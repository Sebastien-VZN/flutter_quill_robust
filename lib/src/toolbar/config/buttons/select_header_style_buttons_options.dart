import 'package:flutter/widgets.dart' show Axis;

import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';

class QuillToolbarSelectHeaderStyleButtonsExtraOptions extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarSelectHeaderStyleButtonsExtraOptions({
    required super.controller,
    required super.context,
    required super.onPressed,
  });
}

class QuillToolbarSelectHeaderStyleButtonsOptions
    extends QuillToolbarBaseButtonOptions<QuillToolbarSelectHeaderStyleButtonsOptions, QuillToolbarSelectHeaderStyleButtonsExtraOptions> {
  const QuillToolbarSelectHeaderStyleButtonsOptions({
    super.afterButtonPressed,
    super.childBuilder,
    super.iconTheme,
    super.tooltip,
    this.axis,
    this.attributes,
    super.iconSize,
    super.iconButtonFactor,
  });

  /// Default value:
  ///
  /// ```dart
  /// const [
  ///   FormatAttribute.header,
  ///   FormatAttribute.h1,
  ///   FormatAttribute.h2,
  ///   FormatAttribute.h3,
  /// ]
  /// ```
  final List<FormatAttribute>? attributes;

  /// By default we will the toolbar axis from [QuillSimpleToolbarConfig]
  final Axis? axis;
}
