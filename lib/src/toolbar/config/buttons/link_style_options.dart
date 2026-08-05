/// @docImport '../../../rules/insert.dart';
library;

import 'package:flutter_quill/src/common/utils/link_validator.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';
import 'package:flutter_quill/src/toolbar/structs/link_dialog_action.dart';
import 'package:flutter_quill/src/toolbar/theme/quill_dialog_theme.dart';

class QuillToolbarLinkStyleButtonExtraOptions extends QuillToolbarBaseButtonExtraOptions {
  const QuillToolbarLinkStyleButtonExtraOptions({
    required super.controller,
    required super.context,
    required super.onPressed,
  });
}

class QuillToolbarLinkStyleButtonOptions
    extends QuillToolbarBaseButtonOptions<QuillToolbarLinkStyleButtonOptions, QuillToolbarLinkStyleButtonExtraOptions> {
  const QuillToolbarLinkStyleButtonOptions({
    this.dialogTheme,
    this.linkDialogAction,
    this.validateLink,
    super.iconSize,
    super.iconButtonFactor,
    super.iconData,
    super.afterButtonPressed,
    super.tooltip,
    super.iconTheme,
    super.childBuilder,
  });

  final QuillDialogTheme? dialogTheme;
  final LinkDialogAction? linkDialogAction;

  /// {@macro link_validation_callback}
  /// This callback is preferred over [linkRegExp] when both are set.
  final LinkValidationCallback? validateLink;
}
