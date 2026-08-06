import 'package:flutter_quill/flutter_quill.dart';

class QuillToolbarEmojiButtonExtraOptions extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarEmojiButtonExtraOptions({
    required super.controller,
    required super.context,
    required super.onPressed,
  });
}

class QuillToolbarEmojiButtonOptions extends QuillToolbarBaseButtonOptions<QuillToolbarEmojiButtonOptions, QuillToolbarEmojiButtonExtraOptions> {
  const QuillToolbarEmojiButtonOptions({
    super.iconData,
    super.childBuilder,
    super.tooltip,
    super.afterButtonPressed,
    super.iconTheme,
    super.iconSize,
    super.iconButtonFactor,
    this.dialogTheme,
    this.customOnPressedCallback,
    this.menuWidth = 320,
    this.menuHeight = 400,
  });

  final QuillDialogTheme? dialogTheme;

  /// By default we will show the emoji picker dropdown ui.
  /// Pass a value to this callback to change the behavior.
  final QuillToolbarEmojiButtonOnPressedCallback? customOnPressedCallback;

  /// Width of the emoji picker dropdown menu.
  final double menuWidth;

  /// Height of the emoji picker dropdown menu.
  final double menuHeight;
}

typedef QuillToolbarEmojiButtonOnPressedCallback = void Function(QuillController controller);
