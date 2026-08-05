import 'package:flutter/foundation.dart' show immutable;

import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/editor_toolbar_controller_shared/quill_config.dart';

class QuillToolbarToggleCheckListButtonExtraOptions extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarToggleCheckListButtonExtraOptions({
    required super.controller,
    required super.context,
    required super.onPressed,
    this.isToggled = false,
  });
  final bool isToggled;
}

@immutable
class QuillToolbarToggleCheckListButtonOptions
    extends QuillToolbarBaseButtonOptions<QuillToolbarToggleCheckListButtonOptions, QuillToolbarToggleCheckListButtonExtraOptions> {
  const QuillToolbarToggleCheckListButtonOptions({
    super.iconSize,
    super.iconButtonFactor,
    this.attribute = FormatAttribute.unchecked,
    this.shouldRequestKeyboard = false,
    super.iconTheme,
    super.tooltip,
    super.iconData,
    super.afterButtonPressed,
    super.childBuilder,
  });

  final FormatAttribute attribute;

  final bool shouldRequestKeyboard;
}
