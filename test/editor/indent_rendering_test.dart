import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/utils/quill_test_app.dart';

/// Regression test for the indent rendering bug.
///
/// Before the fix, `TextBlockUtils.defaultIndentWidthBuilder` read the indent
/// attribute via `numberValue`, which returns `null` for the `nullableInteger`
/// typed `indent` attribute. The extra left spacing was therefore always `0.0`
/// regardless of the indent level, so indented paragraphs and nested list items
/// were not visually indented in the editor — even though the document model
/// held the correct `indent` attribute (controller-level tests passed).
///
/// These tests pump a `QuillEditor` and measure the x-coordinate of the body
/// `RichText` to verify indent shifts the rendered text right proportionally.
void main() {
  QuillController buildController(Delta delta, {TextSelection? selection}) {
    final controller = QuillController.basic()
      ..compose(
        delta: delta,
        textSelection: selection ?? const TextSelection.collapsed(offset: 0),
        source: ChangeSource.local,
      );
    return controller;
  }

  Future<void> pumpEditor(WidgetTester tester, QuillController controller) async {
    await tester.pumpWidget(
      QuillTestApp.withScaffold(
        QuillEditor.basic(
          controller: controller,
          focusNode: FocusNode(),
          scrollController: ScrollController(),
        ),
      ),
    );
    await tester.pump();
  }

  /// Returns the left x-coordinate of the body RichText rendered by the editor.
  double bodyLeft(WidgetTester tester) {
    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsWidgets, reason: 'editor must render at least one RichText');
    return tester.getTopLeft(richTextFinder.first).dx;
  }

  testWidgets('indented paragraph body is shifted right vs plain paragraph', (tester) async {
    // Plain paragraph — baseline left position.
    final plain = buildController(Delta()..insert('plain\n'));
    await pumpEditor(tester, plain);
    final plainLeft = bodyLeft(tester);

    // Indented paragraph (level 1).
    final indented = buildController(
      Delta()
        ..insert('indented')
        ..insert('\n', attributes: {"indent": 1}),
    );
    await pumpEditor(tester, indented);
    final indentedLeft = bodyLeft(tester);

    expect(
      indentedLeft,
      greaterThan(plainLeft),
      reason: 'indent level 1 must shift the body right relative to a plain paragraph',
    );
  });

  testWidgets('higher indent level produces strictly more right shift', (tester) async {
    final l1 = buildController(
      Delta()
        ..insert('level1')
        ..insert('\n', attributes: {"indent": 1}),
    );
    await pumpEditor(tester, l1);
    final l1Left = bodyLeft(tester);

    final l3 = buildController(
      Delta()
        ..insert('level3')
        ..insert('\n', attributes: {"indent": 3}),
    );
    await pumpEditor(tester, l3);
    final l3Left = bodyLeft(tester);

    expect(
      l3Left,
      greaterThan(l1Left),
      reason: 'indent level 3 must indent more than level 1',
    );
  });

  testWidgets('indent level 1 has a non-zero shift', (tester) async {
    final plain = buildController(Delta()..insert('zero\n'));
    await pumpEditor(tester, plain);
    final plainLeft = bodyLeft(tester);

    final indented = buildController(
      Delta()
        ..insert('one')
        ..insert('\n', attributes: {"indent": 1}),
    );
    await pumpEditor(tester, indented);
    final indentedLeft = bodyLeft(tester);

    expect(
      indentedLeft - plainLeft,
      greaterThan(0.0),
      reason: 'indent must produce a positive left shift',
    );
  });
}
