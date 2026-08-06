import 'package:flutter_quill/src/common/utils/quill_debug_logs.dart';
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/document/nodes/leaf.dart';
import 'package:meta/meta.dart';

typedef SpaceShortcutEventHandler = bool Function(QuillText node, QuillController controller);

/// Defines the implementation of shortcut events for space key calls.
@immutable
class SpaceShortcutEvent {
  SpaceShortcutEvent({required this.character, required this.handler}) {
    if (character == '\n' || character.trim().isEmpty) {
      quillDebugPrint(
        'SpaceShortcutEvent — character cannot be empty, a whitespace or a new line.',
      );
    }
  }

  final String character;
  final SpaceShortcutEventHandler handler;

  bool execute(QuillText node, QuillController controller) {
    return handler(node, controller);
  }

  SpaceShortcutEvent copyWith({
    String? character,
    SpaceShortcutEventHandler? handler,
  }) {
    return SpaceShortcutEvent(
      character: character ?? this.character,
      handler: handler ?? this.handler,
    );
  }

  @override
  String toString() => 'SpaceShortcutEvent(character: $character, handler: $handler)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SpaceShortcutEvent && other.character == character && other.handler == handler;
  }

  @override
  int get hashCode => character.hashCode ^ handler.hashCode;
}
