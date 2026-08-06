import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for KNOWN_ISSUES.md #3:
/// "L'éditeur insert URL ne fonctionne pas très bien, le formulaire est
/// bloqué à la saisie."
///
/// Root analysis: the original `QuillTextLink.submit` called
/// `replaceText(index, length, text, null)` — passing `null` as the
/// selection. With a collapsed caret (the common case when opening the
/// dialog without a text selection), the controller did not know where to put
/// the caret after the insertion, which left the editor's remote IME value and
/// the document out of sync: the next keystroke was diffed against a stale
/// base and appeared to "do nothing" (the form felt blocked).
///
/// The contract locked by these tests: after `submit`, the caret MUST be
/// positioned at the end of the freshly inserted link text, and the document
/// must contain exactly the submitted text + link attribute.
void main() {
  group('QuillTextLink.submit — caret + document state', () {
    test('submit with collapsed caret inserts text, link attr and places caret at end of text', () {
      final controller = QuillController.basic()
        // Collapsed caret at doc start, as when the user clicks the link button
        // without selecting anything.
        ..updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );

      QuillTextLink('Example', 'https://example.com').submit(controller);

      // The submitted text must be in the document.
      expect(
        controller.document.toPlainText(),
        startsWith('Example'),
        reason: 'submitted link text must be inserted into the document',
      );

      // The link attribute must be applied to the inserted text.
      final firstOp = controller.document.toDelta().toList().first;
      expect(
        firstOp.attributes?['link'],
        'https://example.com',
        reason: 'link attribute must be applied to the inserted text',
      );

      // CRITICAL — the caret must sit at the end of the inserted text so the
      // next keystroke is appended, not diffed against a stale value.
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 7),
        reason: 'caret must be at the end of the inserted link text (len=7)',
      );
    });

    test('submit replacing a selection keeps caret at end of replaced text', () {
      final controller = QuillController.basic()
        ..replaceText(
          0,
          0,
          'old text here',
          const TextSelection.collapsed(offset: 13),
        )
        // Select "old text" (0..8) as if the user selected it before opening
        // the dialog.
        ..updateSelection(
          const TextSelection(baseOffset: 0, extentOffset: 8),
          ChangeSource.local,
        );

      QuillTextLink('New Label', 'https://new.example').submit(controller);

      expect(controller.document.toPlainText(), startsWith('New Label'));
      expect(
        controller.selection,
        const TextSelection.collapsed(offset: 9),
        reason: 'caret must follow the replaced link label (len=9)',
      );
    });

    test('document remains editable right after submit (no stale IME value)', () {
      final controller = QuillController.basic()
        ..updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );

      QuillTextLink('Example', 'https://example.com').submit(controller);

      // Simulate the user typing immediately after closing the dialog:
      // the caret is at offset 7, so a keystroke appends there.
      final caret = controller.selection.extentOffset;
      controller.replaceText(
        caret,
        0,
        'X',
        TextSelection.collapsed(offset: caret + 1),
      );

      expect(
        controller.document.toPlainText(),
        startsWith('ExampleX'),
        reason:
            'typing right after submit must append at the caret — '
            'this is what felt "blocked" before the fix',
      );
    });
  });
}
