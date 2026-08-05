import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/src/common/utils/platform.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/editor/raw_editor/keyboard_shortcuts/editor_keyboard_shortcut_actions.dart';
import 'package:meta/meta.dart';

final bool _isDesktopMacOS = isMacOS;

@internal
Map<SingleActivator, Intent> defaultSinlgeActivatorIntents() {
  return {
    const SingleActivator(LogicalKeyboardKey.escape): const HideSelectionToolbarIntent(),
    SingleActivator(
      LogicalKeyboardKey.keyZ,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const UndoTextIntent(
      SelectionChangedCause.keyboard,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyY,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const RedoTextIntent(
      SelectionChangedCause.keyboard,
    ),

    // Selection formatting.
    SingleActivator(
      LogicalKeyboardKey.keyB,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ToggleTextStyleIntent(
      FormatAttribute.bold,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyU,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ToggleTextStyleIntent(
      FormatAttribute.underline,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyI,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ToggleTextStyleIntent(
      FormatAttribute.italic,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyS,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
      shift: true,
    ): const ToggleTextStyleIntent(
      FormatAttribute.strikeThrough,
    ),
    SingleActivator(
      LogicalKeyboardKey.backquote,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ToggleTextStyleIntent(
      FormatAttribute.inlineCode,
    ),
    SingleActivator(
      LogicalKeyboardKey.tilde,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
      shift: true,
    ): const ToggleTextStyleIntent(
      FormatAttribute.codeBlock,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyB,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
      shift: true,
    ): const ToggleTextStyleIntent(
      FormatAttribute.blockQuote,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyK,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyLinkIntent(),

    // Lists
    SingleActivator(
      LogicalKeyboardKey.keyL,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
      shift: true,
    ): const ToggleTextStyleIntent(
      FormatAttribute.ul,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyO,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
      shift: true,
    ): const ToggleTextStyleIntent(
      FormatAttribute.ol,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyC,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
      shift: true,
    ): const QuillEditorApplyCheckListIntent(),

    // Indents
    SingleActivator(
      LogicalKeyboardKey.keyM,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const IndentSelectionIntent(
      true,
    ),
    SingleActivator(
      LogicalKeyboardKey.keyM,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
      shift: true,
    ): const IndentSelectionIntent(
      false,
    ),

    // Headers
    SingleActivator(
      LogicalKeyboardKey.digit1,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyHeaderIntent(
      FormatAttribute.h1,
    ),
    SingleActivator(
      LogicalKeyboardKey.digit2,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyHeaderIntent(
      FormatAttribute.h2,
    ),
    SingleActivator(
      LogicalKeyboardKey.digit3,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyHeaderIntent(
      FormatAttribute.h3,
    ),
    SingleActivator(
      LogicalKeyboardKey.digit4,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyHeaderIntent(
      FormatAttribute.h4,
    ),
    SingleActivator(
      LogicalKeyboardKey.digit5,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyHeaderIntent(
      FormatAttribute.h5,
    ),
    SingleActivator(
      LogicalKeyboardKey.digit6,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyHeaderIntent(
      FormatAttribute.h6,
    ),
    SingleActivator(
      LogicalKeyboardKey.digit0,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const QuillEditorApplyHeaderIntent(
      FormatAttribute.header,
    ),

    SingleActivator(
      LogicalKeyboardKey.keyF,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const OpenSearchIntent(),

    //  Arrow key scrolling
    SingleActivator(
      LogicalKeyboardKey.arrowUp,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ScrollIntent(
      direction: AxisDirection.up,
    ),
    SingleActivator(
      LogicalKeyboardKey.arrowDown,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ScrollIntent(
      direction: AxisDirection.down,
    ),
    SingleActivator(
      LogicalKeyboardKey.pageUp,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ScrollIntent(
      direction: AxisDirection.up,
      type: ScrollIncrementType.page,
    ),
    SingleActivator(
      LogicalKeyboardKey.pageDown,
      control: !_isDesktopMacOS,
      meta: _isDesktopMacOS,
    ): const ScrollIntent(
      direction: AxisDirection.down,
      type: ScrollIncrementType.page,
    ),
  };
}
