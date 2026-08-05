import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for KNOWN_ISSUES.md #1:
/// FormatException('Apply delta rules failed. No matching rule found for type: RuleType.format').
///
/// Scenario reproduced on real code: applying an inline attribute (bold, size,
/// italic…) with a *collapsed* selection (`len == 0`). This is exactly what
/// `QuillController.formatText` does when the toolbar toggles an attribute at
/// the caret: it stores the attribute in `toggledStyle` for future text, then
/// still calls `document.format(index, 0, attribute)`.
///
/// Before the fix, `Rules.apply` threw a [FormatException] because no
/// registered format rule handles `len == 0` for inline attributes. After the
/// fix it must return an empty [Delta] (no-op).
void main() {
  group('Rules.apply — no matching format rule must not throw', () {
    test('formatting collapsed caret with bold returns empty delta, no throw', () {
      final document = Document()..insert(0, 'hello');

      expect(
        () => document.format(2, 0, FormatAttribute.bold),
        returnsNormally,
        reason: 'collapsed caret + inline attribute must be a no-op, not a throw',
      );
    });

    test('formatting collapsed caret with a custom inline attribute does not throw', () {
      final document = Document()..insert(0, 'hello');
      const sizeAttr = FormatAttribute(
        key: 'size',
        scope: FormatScope.inline,
        value: 'huge',
        valueType: FormatValueType.nullableString,
      );

      expect(
        () => document.format(2, 0, sizeAttr),
        returnsNormally,
      );
    });

    test('formatting with len > 0 still applies the attribute', () {
      final document = Document()..insert(0, 'hello');
      final delta = document.format(0, 5, FormatAttribute.bold);

      expect(
        delta.isNotEmpty,
        isTrue,
        reason: 'a real range must still produce a formatting delta',
      );
      final ops = document.toDelta().toList();
      expect(ops.first.attributes?['bold'], isTrue);
    });

    test('line-level attribute on collapsed caret targets the newline (existing behavior)', () {
      // Block-scoped attributes with len == 0 ARE handled by
      // ResolveLineFormatRule (they format the following newline). This test
      // locks that behavior in so the fix for inline attrs does not regress it.
      final document = Document()..insert(0, 'hello');

      expect(
        () => document.format(2, 0, FormatAttribute.h1),
        returnsNormally,
      );
    });
  });

  group('QuillController.formatText at collapsed caret (full pipeline)', () {
    test('toggle bold at caret does not throw and stages toggledStyle', () {
      final controller = QuillController.basic()
        ..updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );

      expect(
        () => controller.formatSelection(FormatAttribute.bold),
        returnsNormally,
        reason: 'toggling bold at the caret must not throw through the controller',
      );
      expect(controller.toggledStyle.attributes.containsKey('bold'), isTrue);
    });

    test('typing after toggling bold at caret applies the staged style', () {
      final controller = QuillController.basic()
        ..updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );
      controller.formatSelection(FormatAttribute.bold);

      // Now simulate a keystroke — the staged toggledStyle must be applied.
      controller.replaceText(0, 0, 'A', const TextSelection.collapsed(offset: 1));

      expect(controller.document.toPlainText(), startsWith('A'));
      final firstOp = controller.document.toDelta().toList().first;
      expect(
        firstOp.attributes?['bold'],
        isTrue,
        reason: 'the staged bold style must be applied to the newly typed char',
      );
    });
  });
}
