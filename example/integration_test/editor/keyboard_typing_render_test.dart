import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Returns the plain text rendered by all [RichText] widgets found in the
  /// widget tree, concatenated. Used to verify that typed text is actually
  /// painted, not just stored in the document model.
  String renderedRichTextText(WidgetTester tester) {
    final richTexts = find.byType(RichText).evaluate();
    final buf = StringBuffer();
    for (final element in richTexts) {
      final richText = element.widget as RichText;
      buf.write(richText.text.toPlainText());
    }
    return buf.toString();
  }

  group('keyboard typing renders', () {
    testWidgets(
      'typed characters appear in the rendered text',
      (tester) async {
        final controller = QuillController.basic();
        final focusNode = FocusNode();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuillEditor.basic(
                controller: controller,
                focusNode: focusNode,
                scrollController: scrollController,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(QuillEditor));
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        const word = 'hello';
        final buffer = StringBuffer();

        for (final char in word.split('')) {
          buffer.write(char);
          final current = buffer.toString();
          final nextText = '$current\n';
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: nextText,
              selection: TextSelection.collapsed(offset: current.length),
            ),
          );
          await tester.pumpAndSettle();
        }

        expect(
          controller.document.toPlainText(),
          contains('hello'),
          reason: 'document must contain typed text',
        );
        expect(
          renderedRichTextText(tester),
          contains('hello'),
          reason: 'typed text must be rendered visibly in the editor',
        );

        focusNode.dispose();
        scrollController.dispose();
        controller.dispose();
      },
    );

    testWidgets(
      'focus is retained after typing a character',
      (tester) async {
        final controller = QuillController.basic();
        final focusNode = FocusNode();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuillEditor.basic(
                controller: controller,
                focusNode: focusNode,
                scrollController: scrollController,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(QuillEditor));
        await tester.pumpAndSettle();

        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'a\n',
            selection: TextSelection.collapsed(offset: 1),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          focusNode.hasFocus,
          isTrue,
          reason: 'focus must be retained after first keystroke',
        );

        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'ab\n',
            selection: TextSelection.collapsed(offset: 2),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          controller.document.toPlainText(),
          'ab\n',
          reason: 'second keystroke must be inserted',
        );
        expect(
          renderedRichTextText(tester),
          contains('ab'),
          reason: 'second keystroke must be rendered',
        );

        focusNode.dispose();
        scrollController.dispose();
        controller.dispose();
      },
    );

    testWidgets(
      'typed text in pre-filled document appends at caret',
      (tester) async {
        final controller = QuillController.basic()
          ..compose(
            delta: Delta()..insert('abc\n'),
            textSelection: const TextSelection.collapsed(offset: 3),
            source: ChangeSource.local,
          );
        final focusNode = FocusNode();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuillEditor.basic(
                controller: controller,
                focusNode: focusNode,
                scrollController: scrollController,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.updateSelection(
          const TextSelection.collapsed(offset: 3),
          ChangeSource.local,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(QuillEditor));
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'abcX\n',
            selection: TextSelection.collapsed(offset: 4),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          controller.document.toPlainText(),
          'abcX\n',
          reason: 'document must contain appended character',
        );
        expect(
          renderedRichTextText(tester),
          contains('abcX'),
          reason: 'appended text must be rendered visibly',
        );

        focusNode.dispose();
        scrollController.dispose();
        controller.dispose();
      },
    );
  });
}
