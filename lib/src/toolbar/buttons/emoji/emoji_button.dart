import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/document/document.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/stateless_base_button.dart';
import 'package:flutter_quill/src/toolbar/buttons/emoji/emoji_dialog.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';
import 'package:flutter_quill/src/toolbar/theme/quill_icon_theme.dart';

/// Toolbar button that opens an emoji picker dropdown anchored below the
/// button using Material 3 [MenuAnchor].
///
/// On mobile platforms the emoji button is not rendered by the toolbar
/// (see [QuillSimpleToolbar] gating with `isDesktop`); mobile users get
/// emojis from the native keyboard. This button is desktop-only.
class QuillToolbarEmojiButton extends QuillToolbarBaseButtonStateless<QuillToolbarEmojiButtonOptions, QuillToolbarEmojiButtonExtraOptions> {
  const QuillToolbarEmojiButton({
    required super.controller,
    super.key,
    this._options,
    super.baseOptions,
  });

  final QuillToolbarEmojiButtonOptions? _options;

  @override
  QuillToolbarEmojiButtonOptions? get options => _options;

  @override
  IconData Function(BuildContext context) get getDefaultIconData =>
      (context) => Icons.emoji_emotions_outlined;

  @override
  String Function(BuildContext context) get getDefaultTooltip =>
      (context) => context.loc.emoji;

  @override
  Widget buildButton(BuildContext context) {
    return _EmojiButtonBody(
      controller: controller,
      options: options,
      iconData: iconData(context),
      iconSize: iconSize(context) * iconButtonFactor(context),
      tooltip: tooltip(context),
      iconTheme: iconTheme(context),
      afterPressed: afterButtonPressed(context),
    );
  }

  @override
  Widget? buildCustomChildBuilder(BuildContext context) {
    return childBuilder?.call(
      options!,
      QuillToolbarEmojiButtonExtraOptions(
        controller: controller,
        context: context,
        onPressed: () {
          afterButtonPressed.call(context);
        },
      ),
    );
  }
}

class _EmojiButtonBody extends StatefulWidget {
  const _EmojiButtonBody({
    required this.controller,
    required this.options,
    required this.iconData,
    required this.iconSize,
    required this.tooltip,
    required this.iconTheme,
    required this.afterPressed,
  });

  final QuillController controller;
  final QuillToolbarEmojiButtonOptions? options;
  final IconData iconData;
  final double iconSize;
  final String tooltip;
  final QuillIconTheme? iconTheme;
  final VoidCallback? afterPressed;

  @override
  State<_EmojiButtonBody> createState() => _EmojiButtonBodyState();
}

class _EmojiButtonBodyState extends State<_EmojiButtonBody> {
  final MenuController _menuController = MenuController();

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  void _toggle() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
    widget.afterPressed?.call();
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final controller = widget.controller;
    final offset = controller.selection.baseOffset;
    final text = emoji.emoji;
    final newOffset = offset + text.length;
    controller
      ..replaceText(offset, 0, text, TextSelection.collapsed(offset: newOffset))
      ..updateSelection(
        TextSelection.collapsed(offset: newOffset),
        ChangeSource.local,
      );
  }

  @override
  Widget build(BuildContext context) {
    final menuWidth = widget.options?.menuWidth ?? 320;
    final menuHeight = widget.options?.menuHeight ?? 400;
    return MenuAnchor(
      controller: _menuController,
      style: MenuStyle(
        maximumSize: WidgetStatePropertyAll(Size(menuWidth, menuHeight)),
        backgroundColor: WidgetStatePropertyAll(Theme.of(context).canvasColor),
        elevation: const WidgetStatePropertyAll(4),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        SizedBox(
          width: menuWidth,
          height: menuHeight,
          child: QuillToolbarEmojiDialog(onEmojiSelected: _onEmojiSelected),
        ),
      ],
      child: QuillToolbarIconButton(
        tooltip: widget.tooltip,
        icon: Icon(widget.iconData, size: widget.iconSize),
        isSelected: false,
        onPressed: _toggle,
        afterPressed: widget.afterPressed,
        iconTheme: widget.iconTheme,
      ),
    );
  }
}
