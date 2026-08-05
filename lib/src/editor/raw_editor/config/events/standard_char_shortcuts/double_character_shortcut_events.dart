import 'package:flutter_quill/src/editor/raw_editor/config/events/character_shortcuts_events.dart';
import 'package:flutter_quill/src/editor/raw_editor/config/events/format/format_double_character_handler.dart';

const _asterisk = '*';
const _underscore = '_';

final CharacterShortcutEvent formatDoubleAsterisksToBold = CharacterShortcutEvent(
  key: 'Format double asterisks to bold',
  character: _asterisk,
  handler: (controller) => handleFormatByWrappingWithDoubleCharacter(
    controller: controller,
    character: _asterisk,
    formatStyle: DoubleCharacterFormatStyle.bold,
  ),
);

final CharacterShortcutEvent formatDoubleUnderscoresToBold = CharacterShortcutEvent(
  key: 'Format double underscores to bold',
  character: _underscore,
  handler: (controller) => handleFormatByWrappingWithDoubleCharacter(
    controller: controller,
    character: _underscore,
    formatStyle: DoubleCharacterFormatStyle.bold,
  ),
);
