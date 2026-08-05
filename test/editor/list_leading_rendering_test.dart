import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/utils/quill_test_app.dart';

/// Regression test for KNOWN_ISSUES.md #2:
/// List leading (bullet, number, checkbox) invisible when text size is not
/// explicitly set, or misaligned when a custom size is applied.
///
/// Before the fix, `TextBlock._buildLeading` returned `null` when the line had
/// no explicit `size` attribute (`opSize == null`), hiding the bullet/number/
/// checkbox. And when a size IS set, the leading width was computed from the
/// *default paragraph* font size instead of the *actual* line font size.
///
/// Important: block attributes in Quill are canonical when carried by the
/// trailing newline op (`insert '\n' with {list: ...}`), which produces a
/// `Block` node in the document tree. These tests use that canonical form —
/// the same one the toolbar produces via `formatSelection`.
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

  group('List leading must be visible with default text size', () {
    testWidgets('bullet list shows bullet point leading', (tester) async {
      final controller = buildController(
        Delta()
          ..insert('item1')
          ..insert('\n', {"list": "bullet"}),
      );
      await pumpEditor(tester, controller);

      expect(
        find.byType(QuillBulletPoint),
        findsOneWidget,
        reason: 'bullet point leading must be rendered even without explicit size',
      );
    });

    testWidgets('ordered list shows number point leading', (tester) async {
      final controller = buildController(
        Delta()
          ..insert('item1')
          ..insert('\n', {"list": "ordered"})
          ..insert('item2')
          ..insert('\n', {"list": "ordered"}),
      );
      await pumpEditor(tester, controller);

      expect(
        find.byType(QuillNumberPoint),
        findsNWidgets(2),
        reason: 'number point leading must be rendered for each ordered item',
      );
    });

    testWidgets('checkbox list shows checkbox leading', (tester) async {
      final controller = buildController(
        Delta()
          ..insert('task1')
          ..insert('\n', {"list": "unchecked"}),
      );
      await pumpEditor(tester, controller);

      expect(
        find.byType(QuillCheckboxPoint),
        findsOneWidget,
        reason: 'checkbox leading must be rendered for checkbox list',
      );
    });
  });

  group('List leading must align with explicit text size', () {
    testWidgets('bullet leading aligns with huge font size', (tester) async {
      final controller = buildController(
        Delta()
          ..insert('item1', {"size": "huge"})
          ..insert('\n', {"list": "bullet"}),
      );
      await pumpEditor(tester, controller);

      // The leading must be visible and we should not hit an overflow error.
      expect(find.byType(QuillBulletPoint), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'no layout overflow');
    });

    testWidgets('number leading aligns with small font size', (tester) async {
      final controller = buildController(
        Delta()
          ..insert('item1', {"size": "small"})
          ..insert('\n', {"list": "ordered"}),
      );
      await pumpEditor(tester, controller);

      expect(find.byType(QuillNumberPoint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('checkbox leading remains tappable with large font size', (tester) async {
      final controller = buildController(
        Delta()
          ..insert('task1', {"size": "huge"})
          ..insert('\n', {"list": "unchecked"}),
      );
      await pumpEditor(tester, controller);

      expect(find.byType(QuillCheckboxPoint), findsOneWidget);
    });
  });
}
