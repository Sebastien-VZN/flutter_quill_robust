import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/utils/quill_test_app.dart';

/// Surveillance tests for the IME -> document -> render pipeline hardened in
/// this session.
///
/// These tests lock in the fixed behaviors:
/// 1. A burst of keystrokes is fully applied (no lost characters, caret follows).
/// 2. Typing at the start / middle / end of a line inserts at the caret.
/// 3. IME selection-only and composing-only updates do not corrupt the doc.
/// 4. Backspace deletes at the caret.
/// 5. Node-level guards silently ignore out-of-bounds inserts.
/// 6. The rendered [RichText] always mirrors the document content.
void main() {
  QuillController buildController() => QuillController.basic();

  Future<({QuillController controller, FocusNode focusNode})> pumpEditor(
    WidgetTester tester, {
    QuillController? controller,
    FocusNode? focusNode,
    ScrollController? scrollController,
  }) async {
    final resolvedController = controller ?? buildController();
    final resolvedFocusNode = focusNode ?? FocusNode();
    await tester.pumpWidget(
      QuillTestApp.withScaffold(
        QuillEditor.basic(
          controller: resolvedController,
          focusNode: resolvedFocusNode,
          scrollController: scrollController ?? ScrollController(),
        ),
      ),
    );
    await tester.pump();
    return (controller: resolvedController, focusNode: resolvedFocusNode);
  }

  /// Feeds the editor [TextInput] with a full [TextEditingValue], one pump per
  /// keystroke, character-per-character.
  ///
  /// The [TextInput] client keeps a `_lastKnownRemoteTextEditingValue`. If the
  /// controller selection was changed programmatically *before* tapping, the
  /// remote value lags behind. We therefore first push the current document
  /// state, then pump once so the editor can sync, and only then send the
  /// delta updates one keystroke at a time.
  Future<void> typeViaIme(
    WidgetTester tester,
    QuillController controller,
    String text, {
    int startOffset = 0,
  }) async {
    var current = controller.document.toPlainText();
    var caret = startOffset;

    // Sync the remote IME value with the current document / caret before
    // starting to type, otherwise the diff for the first keystroke is computed
    // against a stale base.
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: current,
        selection: TextSelection.collapsed(offset: caret),
      ),
    );
    await tester.pump();

    for (final char in text.split('')) {
      current = '${current.substring(0, caret)}$char${current.substring(caret)}';
      caret += char.length;
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: current,
          selection: TextSelection.collapsed(offset: caret),
        ),
      );
      await tester.pump();
    }
  }

  group('IME keystroke surveillance', () {
    testWidgets('a burst of 5 keystrokes inserts all characters in order', (tester) async {
      final (:controller, :focusNode) = await pumpEditor(tester);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await typeViaIme(tester, controller, 'abcde');

      expect(
        controller.document.toPlainText(),
        'abcde\n',
        reason: 'all 5 characters must be inserted in order, none lost',
      );
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 5),
        reason: 'caret must follow the typed text',
      );
    });

    testWidgets('insertion at caret in start, middle and end of a line', (tester) async {
      final controller = buildController()
        ..compose(
          delta: Delta()..insert('abc\n'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        );
      await pumpEditor(tester, controller: controller);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();

      Future<void> insertAtCaret(String char, int caret) async {
        controller.updateSelection(
          TextSelection.collapsed(offset: caret),
          ChangeSource.local,
        );
        // Let the editor push the updated value back to the IME so that
        // `_lastKnownRemoteTextEditingValue` is in sync before our next
        // fake IME keystroke.
        await tester.pump();
        final plain = controller.document.toPlainText();
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: '${plain.substring(0, caret)}$char${plain.substring(caret)}',
            selection: TextSelection.collapsed(offset: caret + 1),
          ),
        );
        await tester.pump();
      }

      await insertAtCaret('X', 0);
      expect(controller.document.toPlainText(), 'Xabc\n\n');

      await insertAtCaret('Y', 2);
      expect(controller.document.toPlainText(), 'XaYbc\n\n');

      await insertAtCaret('Z', 5);
      expect(controller.document.toPlainText(), 'XaYbcZ\n\n');
    });

    testWidgets('backspace deletes the character before the caret', (tester) async {
      final controller = buildController()
        ..compose(
          delta: Delta()..insert('abc\n'),
          textSelection: const TextSelection.collapsed(offset: 3),
          source: ChangeSource.local,
        );
      await pumpEditor(tester, controller: controller);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();

      // Simulate backspace: remove the char before caret (offset 3 -> 2).
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ac\n',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      expect(
        controller.document.toPlainText(),
        'ac\n',
        reason: 'backspace must delete the character before the caret',
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
    });

    testWidgets('selection-only IME update does not modify the document', (tester) async {
      final controller = buildController()
        ..compose(
          delta: Delta()..insert('abc\n'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        );
      await pumpEditor(tester, controller: controller);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();

      final before = controller.document.toPlainText();
      // Simulate the platform IME sending a selection-only update (same text,
      // caret moved): the diff between old/new EditingValue is empty so no
      // replaceText should be issued.
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: before,
          selection: const TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      expect(
        controller.document.toPlainText(),
        before,
        reason: 'selection-only update must not alter document text',
      );
    });

    testWidgets('composing-only IME update does not modify the document', (tester) async {
      final controller = buildController()
        ..compose(
          delta: Delta()..insert('abc\n'),
          textSelection: const TextSelection.collapsed(offset: 1),
          source: ChangeSource.local,
        );
      await pumpEditor(tester, controller: controller);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();

      final before = controller.document.toPlainText();
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: before,
          selection: const TextSelection.collapsed(offset: 1),
          composing: const TextRange(start: 1, end: 3),
        ),
      );
      await tester.pump();

      expect(
        controller.document.toPlainText(),
        before,
        reason: 'composing-only update must not alter document text',
      );
    });
  });

  group('Render surveillance (RichText mirroring)', () {
    /// Concatenates the plain text rendered by every [RichText] in the tree.
    String renderedRichText(WidgetTester tester) {
      final buf = StringBuffer();
      for (final element in find.byType(RichText).evaluate()) {
        buf.write((element.widget as RichText).text.toPlainText());
      }
      return buf.toString();
    }

    testWidgets('RichText mirrors document after a typing burst', (tester) async {
      final (:controller, focusNode: _) = await pumpEditor(tester);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();
      await typeViaIme(tester, controller, 'hello');

      final plain = controller.document.toPlainText();
      final rendered = renderedRichText(tester);
      expect(rendered, contains('hello'), reason: 'rendered text must mirror the document');
      expect(plain, 'hello\n');
    });

    testWidgets('RichText mirrors document after backspace', (tester) async {
      final controller = buildController()
        ..compose(
          delta: Delta()..insert('abc\n'),
          textSelection: const TextSelection.collapsed(offset: 3),
          source: ChangeSource.local,
        );
      await pumpEditor(tester, controller: controller);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'ac\n',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();

      expect(renderedRichText(tester), contains('ac'));
      expect(renderedRichText(tester), isNot(contains('ab')));
    });
  });

  group('Node guard surveillance (defensive inserts)', () {
    test('Leaf.insert ignores out-of-bounds index without throwing', () {
      final document = Document()..insert(0, 'ab');
      // Walk root -> Line -> Leaf so we hit the Leaf.insert guard directly.
      final line = document.root.queryChild(0, false).node! as Line;
      final leaf = line.queryChild(0, false).node! as Leaf;

      expect(
        () => leaf.insert(99, 'X', null),
        returnsNormally,
        reason: 'out-of-bounds leaf insert must be silently ignored',
      );
      expect(document.toPlainText(), 'ab\n', reason: 'document must be unchanged');
    });

    test('Line guard ignores out-of-bounds index without throwing', () {
      final document = Document()..insert(0, 'ab');
      final line = document.root.queryChild(0, false).node! as Line;

      expect(
        () => line.insert(99, 'X', null),
        returnsNormally,
        reason: 'out-of-bounds line insert must be silently ignored',
      );
      expect(document.toPlainText(), 'ab\n');
    });

    test('Document.insert ignores a negative index and returns null', () {
      final document = Document();
      expect(document.insert(-1, 'a'), isNull);
      expect(document.toPlainText(), '\n', reason: 'document must stay empty');
    });

    test('Document.delete with invalid index returns null and does not throw', () {
      final document = Document()..insert(0, 'ab');
      expect(document.delete(-1, 1), isNull);
      expect(document.toPlainText(), 'ab\n');
    });
  });

  group('Focus surveillance (widget)', () {
    testWidgets('focus is still retained after typing 3 characters back-to-back', (tester) async {
      final (:controller, :focusNode) = await pumpEditor(tester);

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await typeViaIme(tester, controller, 'xyz');

      expect(
        focusNode.hasFocus,
        isTrue,
        reason: 'focus must survive a multi-keystroke burst',
      );
      await typeViaIme(tester, controller, 'Z', startOffset: 3);
      expect(
        controller.document.toPlainText(),
        contains('Z'),
        reason: 'input connection must still be alive after the burst',
      );
    });
  });
}
