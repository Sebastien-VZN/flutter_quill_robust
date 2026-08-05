import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/utils/quill_test_app.dart';

/// Regression test for the keyboard focus bug reported in the session logs.
///
/// Scenario: the soft keyboard is already visible (test environment forces
/// `_keyboardVisible = true`), the editor is pre-filled, the user taps the
/// editor to acquire focus, then types a character via the IME. The bug was
/// that the scheduled post-frame `_handleFocusChanged` re-entry (the `yolo`
/// branch) ran after the focus had already been reacquired/retained, reading
/// a stale `_hasFocus = false` and closing the connection — so the next
/// keystroke would be lost.
///
/// We assert that after the first keystroke the editor still has focus and the
/// connection is still open, so a second keystroke is also inserted.
void main() {
  testWidgets(
    'editor retains focus and connection after first keystroke when keyboard already visible',
    (tester) async {
      final controller = QuillController.basic()
        ..compose(
          delta: Delta()..insert('eee\n'),
          textSelection: const TextSelection.collapsed(offset: 0),
          source: ChangeSource.local,
        );
      final focusNode = FocusNode();
      final scrollController = ScrollController();

      await tester.pumpWidget(
        QuillTestApp.withScaffold(
          QuillEditor.basic(
            controller: controller,
            focusNode: focusNode,
            scrollController: scrollController,
          ),
        ),
      );
      await tester.pump();

      // Place the caret just before the trailing newline (offset 3, end of "eee").
      controller.updateSelection(
        const TextSelection.collapsed(offset: 3),
        ChangeSource.local,
      );
      await tester.pump();

      // Acquire focus by tapping the editor.
      await tester.tap(find.byType(QuillEditor));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue, reason: 'editor should have focus after tap');

      // Simulate the IME inserting one character at the caret (offset 3 -> 4).
      final plainBefore = controller.document.toPlainText();
      final newText = '${plainBefore.substring(0, 3)}X${plainBefore.substring(3)}';
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: newText,
          selection: const TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.pumpAndSettle();

      // Focus must be retained after the keystroke.
      expect(
        focusNode.hasFocus,
        isTrue,
        reason: 'focus must be retained after first keystroke',
      );

      // A second keystroke must also be accepted (connection not closed).
      final plainAfterFirst = controller.document.toPlainText();
      final secondText = '${plainAfterFirst.substring(0, 4)}Y${plainAfterFirst.substring(4)}';
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: secondText,
          selection: const TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        controller.document.toPlainText(),
        contains('X'),
        reason: 'first keystroke must be inserted',
      );
      expect(
        controller.document.toPlainText(),
        contains('Y'),
        reason: 'second keystroke must be inserted (connection was not closed)',
      );

      focusNode.dispose();
      scrollController.dispose();
      controller.dispose();
    },
  );
}
