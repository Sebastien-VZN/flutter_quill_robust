import 'package:flutter/foundation.dart';
import 'package:flutter_quill/src/toolbar/config/base_button_options.dart';

class QuillToolbarIndentButtonExtraOptions extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarIndentButtonExtraOptions({
    required super.controller,
    required super.context,
    required super.onPressed,
  });
}

@immutable
class QuillToolbarIndentButtonOptions extends QuillToolbarBaseButtonOptions<QuillToolbarIndentButtonOptions, QuillToolbarIndentButtonExtraOptions> {
  const QuillToolbarIndentButtonOptions({
    super.iconData,
    super.afterButtonPressed,
    super.childBuilder,
    super.iconTheme,
    super.tooltip,
    super.iconSize,
    super.iconButtonFactor,
  });
}
