import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/document/document.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';

enum BlockFormatStyle { todo, bullet, ordered, header }

bool handleFormatBlockStyleBySpaceEvent({
  required QuillController controller,
  required String character,
  required BlockFormatStyle formatStyle,
}) {
  if (character.trim().isEmpty || character == '\n') {
    debugPrint(
      'handleFormatBlockStyleBySpaceEvent — Expected non-empty, non-newline character. Got: $character',
    );
    return false;
  }
  if (formatStyle == BlockFormatStyle.todo) {
    _updateSelectionForKeyPhrase(
      character,
      FormatAttribute.unchecked,
      controller,
    );
    return true;
  } else if (formatStyle == BlockFormatStyle.bullet) {
    _updateSelectionForKeyPhrase(character, FormatAttribute.ul, controller);
    return true;
  } else if (formatStyle == BlockFormatStyle.ordered) {
    _updateSelectionForKeyPhrase(character, FormatAttribute.ol, controller);
    return true;
  } else if (formatStyle == BlockFormatStyle.header) {
    var headerAttribute = FormatAttribute.header;
    final count = _count(character, '#');
    if (count == 1) {
      headerAttribute = FormatAttribute.h1;
    } else if (count == 2) {
      headerAttribute = FormatAttribute.h2;
    } else if (count == 3) {
      headerAttribute = FormatAttribute.h3;
    }
    _updateSelectionForKeyPhrase(character, headerAttribute, controller);
    return true;
  }

  return false;
}

void _updateSelectionForKeyPhrase(
  String phrase,
  FormatAttribute attribute,
  QuillController controller,
) {
  controller.replaceText(
    controller.selection.baseOffset - phrase.length,
    phrase.length,
    '\n',
    null,
  );
  _moveCursor(-phrase.length, controller);
  controller
    ..formatSelection(attribute)
    // Remove the added newline.
    ..replaceText(controller.selection.baseOffset + 1, 1, '', null);
}

void _moveCursor(int chars, QuillController controller) {
  final selection = controller.selection;
  controller.updateSelection(
    controller.selection.copyWith(
      baseOffset: selection.baseOffset + chars,
      extentOffset: selection.baseOffset + chars,
    ),
    ChangeSource.local,
  );
}

int _count(String char, String matchChar) {
  var count = 0;
  for (var i = 0; i < char.length; i++) {
    if (char[i] == matchChar) {
      count++;
    } else {
      break;
    }
  }
  return count;
}
