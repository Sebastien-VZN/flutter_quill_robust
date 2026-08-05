import 'package:flutter/material.dart';

import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/toolbar/buttons/font_family_button.dart';
import 'package:flutter_quill/src/toolbar/config/base_button_options.dart';

@immutable
class QuillToolbarFontFamilyButtonExtraOptions extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarFontFamilyButtonExtraOptions({
    required this.defaultDisplayText,
    required this.currentValue,
    required super.controller,
    required super.context,
    required super.onPressed,
  });
  final String defaultDisplayText;
  final String currentValue;
}

class QuillToolbarFontFamilyButtonOptions
    extends QuillToolbarBaseButtonOptions<QuillToolbarFontFamilyButtonOptions, QuillToolbarFontFamilyButtonExtraOptions> {
  const QuillToolbarFontFamilyButtonOptions({
    this.attribute = FormatAttribute.font,
    this.items,
    super.iconData,
    super.afterButtonPressed,
    super.tooltip,
    super.iconTheme,
    super.childBuilder,
    this.onSelected,
    this.padding,
    this.style,
    this.width,
    this.initialValue,
    this.labelOverflow = TextOverflow.visible,
    this.overrideTooltipByFontFamily = false,
    this.itemHeight,
    this.itemPadding,
    this.defaultItemColor = Colors.red,
    this.renderFontFamilies = true,
    super.iconSize,
    super.iconButtonFactor,
    this.defaultDisplayText,
  });

  /// Defaults to:
  ///
  ///
  /// ```dart
  /// {
  ///  'Sans Serif': 'sans-serif',
  ///  'Serif': 'serif',
  ///  'Monospace': 'monospace',
  ///  'Ibarra Real Nova': 'ibarra-real-nova',
  ///  'SquarePeg': 'square-peg',
  ///  'Nunito': 'nunito',
  ///  'Pacifico': 'pacifico',
  ///  'Roboto Mono': 'roboto-mono',
  ///  context.loc.clear: 'Clear'
  /// }
  /// ```
  ///
  /// See also: [QuillToolbarFontFamilyButtonState._items]
  final Map<String, String>? items;
  final ValueChanged<String>? onSelected;
  final FormatAttribute attribute;

  final EdgeInsetsGeometry? padding;
  final TextStyle? style;
  final double? width;
  final bool renderFontFamilies;
  final String? initialValue;
  final TextOverflow labelOverflow;
  final bool overrideTooltipByFontFamily;
  final double? itemHeight;
  final EdgeInsets? itemPadding;
  final Color? defaultItemColor;
  final String? defaultDisplayText;
}
