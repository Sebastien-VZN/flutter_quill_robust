import 'package:flutter/material.dart';
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_button_options_resolver.dart';
import 'package:flutter_quill/src/toolbar/config/simple_toolbar_config.dart';
import 'package:flutter_quill/src/toolbar/theme/quill_icon_theme.dart';
import 'package:meta/meta.dart';

/// The [T] is the options for the button, usually should refresnce itself
/// it's used in [childBuilder] so the developer can custmize this when using it
/// The [I] is extra options for the button, usually for it's state
@internal
abstract class QuillToolbarBaseButtonStateless<T, I> extends StatelessWidget {
  const QuillToolbarBaseButtonStateless({
    required this.controller,
    super.key,
    this.options,
    this.baseOptions,
  });

  final QuillToolbarBaseButtonOptions<T, I>? options;

  final QuillToolbarBaseButtonOptions<dynamic, dynamic>? baseOptions;

  QuillToolbarButtonOptionsResolver<T, I> get _optionsResolver => QuillToolbarButtonOptionsResolver<T, I>(
    baseOptions: baseOptions as QuillToolbarBaseButtonOptions<T, I>?,
    specificOptions: options,
  );

  final QuillController controller;

  double iconSize(BuildContext context) {
    return _optionsResolver.iconSize ?? kDefaultIconSize;
  }

  double iconButtonFactor(BuildContext context) {
    return _optionsResolver.iconButtonFactor ?? kDefaultIconButtonFactor;
  }

  VoidCallback? afterButtonPressed(BuildContext context) {
    return _optionsResolver.afterButtonPressed;
  }

  QuillIconTheme? iconTheme(BuildContext context) {
    return _optionsResolver.iconTheme;
  }

  IconData iconData(BuildContext context) {
    return _optionsResolver.iconData ?? getDefaultIconData(context);
  }

  String tooltip(BuildContext context) {
    return _optionsResolver.tooltip ?? getDefaultTooltip(context);
  }

  QuillToolbarButtonOptionsChildBuilder<T, I> get childBuilder => _optionsResolver.childBuilder;

  abstract final IconData Function(BuildContext context) getDefaultIconData;
  abstract final String Function(BuildContext context) getDefaultTooltip;

  Widget buildButton(BuildContext context);
  Widget? buildCustomChildBuilder(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final childBuilder = _optionsResolver.childBuilder;
    if (childBuilder != null) {
      return buildCustomChildBuilder(context) ?? const SizedBox.shrink();
    }
    return buildButton(context);
  }
}
