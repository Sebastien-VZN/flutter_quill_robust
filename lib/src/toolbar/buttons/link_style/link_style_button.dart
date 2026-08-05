import 'package:flutter/material.dart';
import 'package:flutter_quill/src/editor/widgets/link.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/buttons/link_style/link_dialog.dart';
import 'package:flutter_quill/src/toolbar/buttons/quill_icon_button.dart';
import 'package:flutter_quill/src/toolbar/config/buttons/link_style_options.dart';

typedef QuillToolbarLinkStyleBaseButton = QuillToolbarBaseButton<QuillToolbarLinkStyleButtonOptions, QuillToolbarLinkStyleButtonExtraOptions>;

typedef QuillToolbarLinkStyleBaseButtonState<W extends QuillToolbarLinkStyleBaseButton> =
    QuillToolbarCommonButtonState<W, QuillToolbarLinkStyleButtonOptions, QuillToolbarLinkStyleButtonExtraOptions>;

class QuillToolbarLinkStyleButton extends QuillToolbarLinkStyleBaseButton {
  const QuillToolbarLinkStyleButton({
    required super.controller,
    super.options = const QuillToolbarLinkStyleButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  });

  @override
  QuillToolbarLinkStyleButtonState createState() => QuillToolbarLinkStyleButtonState();
}

class QuillToolbarLinkStyleButtonState extends QuillToolbarLinkStyleBaseButtonState {
  @override
  String get defaultTooltip => context.loc.insertURL;

  void _didChangeSelection() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_didChangeSelection);
  }

  @override
  void didUpdateWidget(covariant QuillToolbarLinkStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_didChangeSelection);
      controller.addListener(_didChangeSelection);
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(_didChangeSelection);
  }

  @override
  IconData get defaultIconData => Icons.link;

  @override
  Widget build(BuildContext context) {
    final isToggled = QuillTextLink.isSelected(controller);

    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarLinkStyleButtonExtraOptions(
          context: context,
          controller: controller,
          onPressed: () async {
            await _openLinkDialog(context);
            afterButtonPressed?.call();
          },
        ),
      );
    }
    return QuillToolbarIconButton(
      tooltip: tooltip,
      icon: Icon(iconData, size: iconSize * iconButtonFactor),
      isSelected: isToggled,
      onPressed: () => _openLinkDialog(context),
      afterPressed: afterButtonPressed,
      iconTheme: iconTheme,
    );
  }

  Future<void> _openLinkDialog(BuildContext context) async {
    final initialTextLink = QuillTextLink.prepare(widget.controller);

    final textLink = await showDialog<QuillTextLink>(
      context: context,
      builder: (_) {
        return LinkDialog(
          validateLink: options.validateLink,
          dialogTheme: options.dialogTheme,
          text: initialTextLink.text,
          link: initialTextLink.link,
          action: options.linkDialogAction,
        );
      },
    );
    if (textLink != null) {
      textLink.submit(widget.controller);
    }
  }
}
