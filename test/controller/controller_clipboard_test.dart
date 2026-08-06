import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/src/controller/clipboard/quill_controller_paste.dart';
import 'package:flutter_quill/src/controller/clipboard/quill_controller_rich_paste.dart';
import 'package:test/test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('copy', () {
    const testDocumentContents = 'data';
    late QuillController controller;

    setUp(() {
      controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert(testDocumentContents),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        );
    });

    test(
      'should prioritize delta from onDeltaPaste callback over parsed delta when pasting Delta',
      () async {
        var returnComposedDelta = true;

        controller = QuillController.basic(
          config: QuillControllerConfig(
            clipboardConfig: QuillClipboardConfig(
              onRichTextPaste: (delta, isExternal) async {
                if (returnComposedDelta) {
                  return delta.compose(Delta()..insert('composed delta\n'));
                }
                return null;
              },
            ),
          ),
        );

        final initialDelta = Delta()..insert('plain text\n', attributes: {'bold': true});

        expect(
          await controller.getDeltaToPaste(initialDelta),
          initialDelta.compose(Delta()..insert('composed delta\n')),
        );

        returnComposedDelta = false;

        final secondDelta = Delta()..insert('plain text\n', attributes: {'bold': true});

        expect(await controller.getDeltaToPaste(secondDelta), secondDelta);
      },
    );

    test('clipboardSelection empty', () async {
      expect(
        await controller.clipboardSelection(true),
        false,
        reason: 'No effect when no selection',
      );
      expect(await controller.clipboardSelection(false), false);
    });

    test('clipboardSelection', () async {
      controller
        ..replaceText(0, 4, 'bold plain italic', null)
        ..formatText(0, 4, FormatAttribute.bold)
        ..formatText(11, 17, FormatAttribute.italic)
        ..updateSelection(
          const TextSelection(baseOffset: 2, extentOffset: 14),
          ChangeSource.local,
        );
      //
      expect(await controller.clipboardSelection(true), true);
      expect(
        controller.document.length,
        18,
        reason: 'Copy does not change the document',
      );
      expect(await controller.clipboardSelection(false), true);
      expect(controller.document.length, 6, reason: 'Cut changes the document');
      //
      controller
        ..readOnly = true
        ..updateSelection(
          const TextSelection(baseOffset: 2, extentOffset: 4),
          ChangeSource.local,
        );
      expect(controller.selection.isCollapsed, false);
      expect(await controller.clipboardSelection(true), true);
      expect(controller.document.length, 6);
      expect(await controller.clipboardSelection(false), false);
      expect(
        controller.document.length,
        6,
        reason: 'Cut not permitted on readOnly document',
      );
    });
  });

  bool pasteUsingPlainOrDelta(
    QuillController controller,
    String? clipboardText,
  ) => controller.pastePlainTextOrDelta(
    clipboardText,
    pasteDelta: controller.pasteDelta,
    pastePlainText: controller.pastePlainText,
  );

  group('paste', () {
    test('Plain', () async {
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('[]'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection.collapsed(offset: 1),
          ChangeSource.local,
        );
      //
      expect(controller.document.toPlainText(), '[]\n');
      expect(pasteUsingPlainOrDelta(controller, 'insert'), true);
      expect(controller.document.toPlainText(), '[insert]\n');
    });

    test('Plain lines', () async {
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('[]'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection.collapsed(offset: 1),
          ChangeSource.local,
        );
      //
      expect(controller.document.toPlainText(), '[]\n');
      expect(pasteUsingPlainOrDelta(controller, '1\n2\n3\n'), true);
      expect(controller.document.toPlainText(), '[1\n2\n3\n]\n');
    });

    test('Paste from external', () async {
      final source = QuillController.basic()
        ..compose(
          delta: Delta()..insert('Plain text'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection(baseOffset: 4, extentOffset: 8),
          ChangeSource.local,
        );

      await source.clipboardSelection(true);
      expect(source.pastePlainText, 'n te');
      //
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('[]'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection.collapsed(offset: 1),
          ChangeSource.local,
        );
      //
      expect(
        pasteUsingPlainOrDelta(controller, 'insert'),
        true,
        reason: 'External paste',
      );
      expect(controller.document.toPlainText(), '[insert]\n');
    });

    test('Delta simple', () async {
      final source = QuillController.basic()
        ..compose(
          delta: Delta()..insert('Plain text'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..formatText(6, 8, FormatAttribute.bold)
        ..updateSelection(
          const TextSelection(baseOffset: 4, extentOffset: 8),
          ChangeSource.local,
        );
      await source.clipboardSelection(true);
      expect(source.pastePlainText, 'n te');
      expect(
        source.pasteDelta,
        Delta()
          ..insert('n ')
          ..insert('te', attributes: {'bold': true}),
      );
      //
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('[]'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection.collapsed(offset: 1),
          ChangeSource.local,
        );
      //
      expect(
        pasteUsingPlainOrDelta(controller, 'n te'),
        true,
        reason: 'Internal paste',
      );
      expect(controller.document.toPlainText(), '[n te]\n');
      expect(
        controller.document.toDelta(),
        Delta()
          ..insert('[n ')
          ..insert('te', attributes: {'bold': true})
          ..insert(']\n'),
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 5));
    });

    test('Delta multi line', () async {
      const blockAttribute = FormatAttribute.ol;
      const plainSelection = 'BC\nDEF\nGHI\nJK';
      final source = QuillController.basic()
        ..compose(
          delta: Delta()..insert('ABC\nDEF\nGHI\nJKL'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..formatText(1, 1, FormatAttribute.underline) // ABC with B underlined
        ..formatText(4, 0, blockAttribute) // 1. DEF with E in italic
        ..formatText(5, 1, FormatAttribute.italic)
        ..formatText(8, 0, blockAttribute) // 2. GHI with H as inline code
        ..formatText(9, 1, FormatAttribute.inlineCode)
        ..formatText(
          13,
          1,
          FormatAttribute.strikeThrough,
        ) // JKL with K strikethrough
        ..updateSelection(
          const TextSelection(baseOffset: 1, extentOffset: 14),
          ChangeSource.local,
        );
      //
      await source.clipboardSelection(true);
      expect(source.pastePlainText, plainSelection);
      expect(
        source.pasteDelta,
        Delta()
          ..insert('B', attributes: {'underline': true})
          ..insert('C\nD')
          ..insert('E', attributes: {'italic': true})
          ..insert('F')
          ..insert('\n', attributes: {'list': 'ordered'})
          ..insert('G')
          ..insert('H', attributes: {'code': true})
          ..insert('I')
          ..insert('\n', attributes: {'list': 'ordered'})
          ..insert('J')
          ..insert('K', attributes: {'strike': true}),
      );
      //
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('[]'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection.collapsed(offset: 1),
          ChangeSource.local,
        );
      //
      expect(
        pasteUsingPlainOrDelta(controller, plainSelection),
        true,
        reason: 'Internal paste',
      );
      expect(controller.document.toPlainText(), '[$plainSelection]\n');
      expect(
        controller.document.toDelta(),
        Delta()
          ..insert('[')
          ..insert('B', attributes: {'underline': true})
          ..insert('C\nD')
          ..insert('E', attributes: {'italic': true})
          ..insert('F')
          ..insert('\n', attributes: {'list': 'ordered'})
          ..insert('G')
          ..insert('H', attributes: {'code': true})
          ..insert('I')
          ..insert('\n', attributes: {'list': 'ordered'})
          ..insert('J')
          ..insert('K', attributes: {'strike': true})
          ..insert(']\n'),
      );
      expect(controller.selection, const TextSelection.collapsed(offset: 14));
    });
  });

  group('clipboard with embeds', () {
    test('clipboardSelection captures embed in pastePlainText and pasteDelta', () async {
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('before'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..replaceText(6, 0, BlockEmbed.formula('x^2 + y^2'), null)
        ..updateSelection(
          const TextSelection(baseOffset: 0, extentOffset: 8),
          ChangeSource.local,
        );

      // The plain text representation of the selection contains the embed
      // object replacement character for the formula embed.
      await controller.clipboardSelection(true);
      expect(controller.pastePlainText, contains(Embed.kObjectReplacementCharacter));
      expect(controller.pasteDelta.isNotEmpty, true);
      // The delta should contain at least one insert whose data is a Map
      // (the embed payload), not a plain String.
      final hasEmbedOp = controller.pasteDelta.toList().where((op) => op.data is Map).isNotEmpty;
      expect(hasEmbedOp, true, reason: 'pasteDelta should contain an embed operation');
    });

    test('clipboardSelection does not leave clipboard empty before caches are filled', () async {
      // Regression: previously the clipboard was cleared first and only
      // repopulated at the very end, after computing the slow caches. A
      // concurrent paste would then see an empty clipboard. Now the plain
      // text is written to the clipboard before the caches are computed.
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('hello'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection(baseOffset: 0, extentOffset: 5),
          ChangeSource.local,
        );

      await controller.clipboardSelection(true);
      // The cache should be populated synchronously with the clipboard write,
      // so a concurrent paste would see consistent content.
      expect(controller.pastePlainText, 'hello');
      expect(controller.pasteDelta.isNotEmpty, true);
    });

    test('internal paste via pastePlainTextOrDelta preserves embeds', () async {
      final source = QuillController.basic()
        ..compose(
          delta: Delta()..insert('a'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..replaceText(1, 0, BlockEmbed.formula('x^2'), null)
        ..replaceText(2, 0, 'b', null)
        ..updateSelection(
          const TextSelection(baseOffset: 0, extentOffset: 3),
          ChangeSource.local,
        );

      await source.clipboardSelection(true);
      // pastePlainText should be "a\uFFFCb" (embed replaced by FFFC).
      expect(source.pastePlainText, 'a${Embed.kObjectReplacementCharacter}b');

      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('[]'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        )
        ..updateSelection(
          const TextSelection.collapsed(offset: 1),
          ChangeSource.local,
        );

      expect(
        pasteUsingPlainOrDelta(controller, source.pastePlainText),
        true,
        reason: 'Internal paste with embed should be handled',
      );
      // The resulting document should contain the embed (a formula node),
      // not a literal FFFC character in the text.
      final plain = controller.document.toPlainText();
      expect(plain, contains(Embed.kObjectReplacementCharacter));
      expect(plain, '[a${Embed.kObjectReplacementCharacter}b]\n');
    });
  });
}
