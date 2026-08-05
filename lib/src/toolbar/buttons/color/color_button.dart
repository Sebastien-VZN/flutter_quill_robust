import 'package:flutter/material.dart';
import 'package:flutter_quill/src/common/utils/color.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/style.dart';
import 'package:flutter_quill/src/editor_toolbar_shared/color.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/buttons/color/color_dialog.dart';
import 'package:flutter_quill/src/toolbar/buttons/quill_icon_button.dart';
import 'package:flutter_quill/src/toolbar/config/buttons/color_options.dart';

typedef QuillToolbarColorBaseButton = QuillToolbarBaseButton<QuillToolbarColorButtonOptions, QuillToolbarColorButtonExtraOptions>;

typedef QuillToolbarColorBaseButtonState<W extends QuillToolbarColorButton> =
    QuillToolbarCommonButtonState<W, QuillToolbarColorButtonOptions, QuillToolbarColorButtonExtraOptions>;

/// Controls color styles.
///
/// When pressed, this button displays overlay toolbar with
/// buttons for each color.
class QuillToolbarColorButton extends QuillToolbarColorBaseButton {
  const QuillToolbarColorButton({
    required super.controller,
    required this.isBackground,
    super.options = const QuillToolbarColorButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  });

  /// Is this background color button or font color
  final bool isBackground;

  @override
  QuillToolbarColorButtonState createState() => QuillToolbarColorButtonState();
}

class QuillToolbarColorButtonState extends QuillToolbarColorBaseButtonState {
  late bool _isToggledColor;
  late bool _isToggledBackground;
  late bool _isWhite;
  late bool _isWhiteBackground;

  @override
  String get defaultTooltip => widget.isBackground ? context.loc.backgroundColor : context.loc.fontColor;

  Style get _selectionStyle => widget.controller.getSelectionStyle();

  void _didChangeEditingValue() {
    setState(() {
      _isToggledColor = _getIsToggledColor(
        widget.controller.getSelectionStyle().attributes,
      );
      _isToggledBackground = _getIsToggledBackground(
        widget.controller.getSelectionStyle().attributes,
      );
      _isWhite = _isToggledColor && _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhiteBackground = _isToggledBackground && _selectionStyle.attributes['background']!.value == '#ffffff';
    });
  }

  @override
  void initState() {
    super.initState();
    _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
    _isToggledBackground = _getIsToggledBackground(_selectionStyle.attributes);
    _isWhite = _isToggledColor && _selectionStyle.attributes['color']!.value == '#ffffff';
    _isWhiteBackground = _isToggledBackground && _selectionStyle.attributes['background']!.value == '#ffffff';
    widget.controller.addListener(_didChangeEditingValue);
  }

  bool _getIsToggledColor(Map<String, FormatAttribute> attrs) {
    return attrs.containsKey(FormatAttribute.color.key);
  }

  bool _getIsToggledBackground(Map<String, FormatAttribute> attrs) {
    return attrs.containsKey(FormatAttribute.background.key);
  }

  @override
  void didUpdateWidget(covariant QuillToolbarColorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      widget.controller.addListener(_didChangeEditingValue);
      _isToggledColor = _getIsToggledColor(_selectionStyle.attributes);
      _isToggledBackground = _getIsToggledBackground(
        _selectionStyle.attributes,
      );
      _isWhite = _isToggledColor && _selectionStyle.attributes['color']!.value == '#ffffff';
      _isWhiteBackground = _isToggledBackground && _selectionStyle.attributes['background']!.value == '#ffffff';
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  IconData get defaultIconData => widget.isBackground ? Icons.format_color_fill : Icons.color_lens;

  @override
  Widget build(BuildContext context) {
    final iconColor = _isToggledColor && !widget.isBackground && !_isWhite
        ? stringToColor(value: _selectionStyle.attributes['color']!.stringValue)
        : null;

    final iconColorBackground = _isToggledBackground && widget.isBackground && !_isWhiteBackground
        ? stringToColor(
            value: _selectionStyle.attributes['background']!.stringValue,
          )
        : null;

    final fillColor = _isToggledColor && !widget.isBackground && _isWhite ? stringToColor(value: '#ffffff') : null;
    final fillColorBackground = _isToggledBackground && widget.isBackground && _isWhiteBackground ? stringToColor(value: '#ffffff') : null;

    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarColorButtonExtraOptions(
          controller: controller,
          context: context,
          onPressed: () async {
            await _showColorPicker();
            afterButtonPressed?.call();
          },
          iconColor: iconColor,
          iconColorBackground: iconColorBackground,
          fillColor: fillColor,
          fillColorBackground: fillColorBackground,
        ),
      );
    }

    return QuillToolbarIconButton(
      tooltip: tooltip,
      isSelected: false,
      iconTheme: iconTheme,
      icon: Icon(
        iconData,
        color: widget.isBackground ? iconColorBackground : iconColor,
        size: iconSize * iconButtonFactor,
      ),
      onPressed: _showColorPicker,
      afterPressed: afterButtonPressed,
    );
  }

  void _changeColor(BuildContext context, Color? color) {
    if (color == null) {
      widget.controller.formatSelection(
        widget.isBackground ? FormatAttribute.background : FormatAttribute.color,
      );
      return;
    }
    var hex = colorToHex(color);
    hex = "#$hex";
    widget.controller.formatSelection(
      widget.isBackground
          ? FormatAttribute(
              key: "background",
              scope: FormatScope.inline,
              value: hex,
              valueType: FormatValueType.nullableString,
            )
          : FormatAttribute(
              key: "color",
              scope: FormatScope.inline,
              value: hex,
              valueType: FormatValueType.nullableString,
            ),
    );
  }

  Future<void> _showColorPicker() async {
    final customCallback = options.customOnPressedCallback;
    if (customCallback != null) {
      await customCallback(controller, widget.isBackground);
      return;
    }
    await showDialog<String>(
      context: context,
      builder: (_) => ColorPickerDialog(
        isBackground: widget.isBackground,
        onRequestChangeColor: _changeColor,
        isToggledColor: _isToggledColor,
        selectionStyle: _selectionStyle,
      ),
    );
  }
}
