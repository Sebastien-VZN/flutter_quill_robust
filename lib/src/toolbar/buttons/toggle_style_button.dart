import 'package:flutter/material.dart';

import 'package:flutter_quill/src/common/utils/widgets.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/style.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';
import 'package:flutter_quill/src/toolbar/theme/quill_icon_theme.dart';

typedef ToggleStyleButtonBuilder =
    Widget Function(
      BuildContext context,
      FormatAttribute attribute,
      IconData icon,
      bool? isToggled,
      VoidCallback? onPressed,
      VoidCallback? afterPressed, [
      double iconSize,
      QuillIconTheme? iconTheme,
    ]);

class QuillToolbarToggleStyleButton extends QuillToolbarToggleStyleBaseButton {
  const QuillToolbarToggleStyleButton({
    required super.controller,
    required this.attribute,
    super.options = const QuillToolbarToggleStyleButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  });

  final FormatAttribute attribute;

  @override
  QuillToolbarToggleStyleButtonState createState() => QuillToolbarToggleStyleButtonState();
}

class QuillToolbarToggleStyleButtonState extends QuillToolbarToggleStyleBaseButtonState<QuillToolbarToggleStyleButton> {
  Style get _selectionStyle => controller.getSelectionStyle();

  @override
  bool get currentStateValue => _getIsToggled(_selectionStyle.attributes);

  (String, IconData) get _defaultTooltipAndIconData {
    switch (widget.attribute.key) {
      case 'bold':
        return (context.loc.bold, Icons.format_bold);
      case 'script':
        if (widget.attribute.value == "sub") {
          return (context.loc.subscript, Icons.subscript);
        }
        return (context.loc.superscript, Icons.superscript);
      case 'italic':
        return (context.loc.italic, Icons.format_italic);
      case 'small':
        return (context.loc.small, Icons.format_size);
      case 'underline':
        return (context.loc.underline, Icons.format_underline);
      case 'strike':
        return (context.loc.strikeThrough, Icons.format_strikethrough);
      case 'code':
        return (context.loc.inlineCode, Icons.code);
      case 'direction':
        return (context.loc.textDirection, Icons.format_textdirection_r_to_l);
      case 'list':
        if (widget.attribute.value == 'bullet') {
          return (context.loc.bulletList, Icons.format_list_bulleted);
        }
        return (context.loc.numberedList, Icons.format_list_numbered);
      case 'code-block':
        return (context.loc.codeBlock, Icons.code);
      case 'blockquote':
        return (context.loc.quote, Icons.format_quote);
      case 'align':
        return switch (widget.attribute.value) {
          'left' => (context.loc.alignLeft, Icons.format_align_left),
          'right' => (context.loc.alignRight, Icons.format_align_right),
          'center' => (context.loc.alignCenter, Icons.format_align_center),
          'justify' => (context.loc.alignJustify, Icons.format_align_justify),
          Object() => throw ArgumentError(widget.attribute.value),
          null => (context.loc.alignCenter, Icons.format_align_center),
        };
      default:
        throw ArgumentError(
          'Could not find the default tooltip for '
          '${widget.attribute}',
        );
    }
  }

  @override
  String get defaultTooltip => _defaultTooltipAndIconData.$1;

  @override
  IconData get defaultIconData => _defaultTooltipAndIconData.$2;

  void _onPressed() {
    _toggleAttribute();
    afterButtonPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarToggleStyleButtonExtraOptions(
          context: context,
          controller: controller,
          onPressed: _onPressed,
          isToggled: currentValue,
        ),
      );
    }
    return UtilityWidgets.maybeTooltip(
      message: tooltip,
      child: defaultToggleStyleButtonBuilder(
        context,
        widget.attribute,
        iconData,
        currentValue,
        _toggleAttribute,
        afterButtonPressed,
        iconSize,
        iconButtonFactor,
        iconTheme,
      ),
    );
  }

  bool _getIsToggled(Map<String, FormatAttribute> attrs) {
    if (widget.attribute.key == FormatAttribute.list.key ||
        widget.attribute.key == FormatAttribute.header.key ||
        widget.attribute.key == FormatAttribute.script.key ||
        widget.attribute.key == FormatAttribute.align.key) {
      final attribute = attrs[widget.attribute.key];
      if (attribute == null) {
        return false;
      }
      return attribute.value == widget.attribute.value;
    }
    return attrs.containsKey(widget.attribute.key);
  }

  void _toggleAttribute() {
    controller
      ..skipRequestKeyboard = !widget.attribute.isInline
      ..formatSelection(
        currentValue ? FormatAttribute.clone(widget.attribute, null) : widget.attribute,
      );
  }
}

Widget defaultToggleStyleButtonBuilder(
  BuildContext context,
  FormatAttribute attribute,
  IconData icon,
  bool? isToggled,
  VoidCallback? onPressed,
  VoidCallback? afterPressed, [
  double iconSize = kDefaultIconSize,
  double iconButtonFactor = kDefaultIconButtonFactor,
  QuillIconTheme? iconTheme,
]) {
  final isEnabled = onPressed != null;
  return QuillToolbarIconButton(
    icon: Icon(icon, size: iconSize * iconButtonFactor),
    isSelected: isEnabled && isToggled == true,
    onPressed: onPressed,
    afterPressed: afterPressed,
    iconTheme: iconTheme,
  );
}
