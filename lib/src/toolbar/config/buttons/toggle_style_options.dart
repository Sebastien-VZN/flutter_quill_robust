import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_quill/src/toolbar/config/base_button_options.dart';
import 'package:meta/meta.dart';

class QuillToolbarToggleStyleButtonExtraOptions extends QuillToolbarBaseButtonExtraOptions implements QuillToolbarBaseButtonExtraOptionsIsToggled {
  const QuillToolbarToggleStyleButtonExtraOptions({
    required super.controller,
    required super.context,
    required super.onPressed,
    required this.isToggled,
  });

  @override
  final bool isToggled;
}

@immutable
class QuillToolbarToggleStyleButtonOptions
    extends QuillToolbarBaseButtonOptions<QuillToolbarToggleStyleButtonOptions, QuillToolbarToggleStyleButtonExtraOptions> {
  const QuillToolbarToggleStyleButtonOptions({
    super.iconData,
    super.iconSize,
    super.iconButtonFactor,
    super.tooltip,
    super.afterButtonPressed,
    super.iconTheme,
    super.childBuilder,
  });
}
