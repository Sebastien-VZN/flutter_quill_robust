import 'package:flutter/widgets.dart' show IconData, TextStyle, ValueChanged, VoidCallback;

import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';
import 'package:flutter_quill/src/toolbar/theme/quill_icon_theme.dart';

class QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions({
    required super.controller,
    required super.context,
    required super.onPressed,
    required this.currentValue,
  });
  final FormatAttribute currentValue;
}

class QuillToolbarSelectHeaderStyleDropdownButtonOptions
    extends
        QuillToolbarBaseButtonOptions<QuillToolbarSelectHeaderStyleDropdownButtonOptions, QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions> {
  const QuillToolbarSelectHeaderStyleDropdownButtonOptions({
    super.afterButtonPressed,
    super.childBuilder,
    super.iconTheme,
    super.tooltip,
    super.iconSize,
    super.iconButtonFactor,
    this.textStyle,
    super.iconData,
    this.attributes,
    this.defaultDisplayText,
    this.width,
  });

  final TextStyle? textStyle;

  /// Header attributes, defaults to:
  /// ```dart
  /// [
  ///   FormatAttribute.h1,
  ///   FormatAttribute.h2,
  ///   FormatAttribute.h3,
  ///   FormatAttribute.h4,
  ///   FormatAttribute.h5,
  ///   FormatAttribute.h6,
  ///   FormatAttribute.header,
  /// ]
  /// ```
  final List<FormatAttribute>? attributes;
  final double? width;

  final String? defaultDisplayText;

  QuillToolbarSelectHeaderStyleDropdownButtonOptions copyWith({
    ValueChanged<String>? onSelected,
    List<FormatAttribute>? attributes,
    TextStyle? style,
    double? iconSize,
    double? iconButtonFactor,
    IconData? iconData,
    VoidCallback? afterButtonPressed,
    String? tooltip,
    QuillIconTheme? iconTheme,
    String? defaultDisplayText,
    double? width,
  }) {
    return QuillToolbarSelectHeaderStyleDropdownButtonOptions(
      attributes: attributes ?? this.attributes,
      iconData: iconData ?? this.iconData,
      afterButtonPressed: afterButtonPressed ?? this.afterButtonPressed,
      tooltip: tooltip ?? this.tooltip,
      iconTheme: iconTheme ?? this.iconTheme,
      iconSize: iconSize ?? this.iconSize,
      iconButtonFactor: iconButtonFactor ?? this.iconButtonFactor,
      defaultDisplayText: defaultDisplayText ?? this.defaultDisplayText,
      width: width ?? this.width,
    );
  }
}
