import 'package:flutter/material.dart';
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_button_options_resolver.dart';
import 'package:flutter_quill/src/toolbar/buttons/quill_icon_button.dart';
import 'package:flutter_quill/src/toolbar/config/base_button_options.dart';
import 'package:flutter_quill/src/toolbar/config/buttons/custom_button_options.dart';

class QuillToolbarCustomButton extends StatelessWidget {
  const QuillToolbarCustomButton({
    required this.controller,
    this.options = const QuillToolbarCustomButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    this.baseOptions,
    super.key,
  });

  final QuillController controller;
  final QuillToolbarCustomButtonOptions options;
  final QuillToolbarBaseButtonOptions<dynamic, dynamic>? baseOptions;

  void _onPressed(BuildContext context) => options.onPressed?.call();

  QuillToolbarButtonOptionsResolver<QuillToolbarCustomButtonOptions, QuillToolbarCustomButtonExtraOptions> get _optionsResolver =>
      QuillToolbarButtonOptionsResolver<QuillToolbarCustomButtonOptions, QuillToolbarCustomButtonExtraOptions>(
        baseOptions: baseOptions as QuillToolbarBaseButtonOptions<QuillToolbarCustomButtonOptions, QuillToolbarCustomButtonExtraOptions>?,
        specificOptions: options,
      );

  @override
  Widget build(BuildContext context) {
    final childBuilder = _optionsResolver.childBuilder;

    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarCustomButtonExtraOptions(
          context: context,
          controller: controller,
          onPressed: () {
            _onPressed(context);
            _optionsResolver.afterButtonPressed?.call();
          },
        ),
      );
    }

    return QuillToolbarIconButton(
      icon: options.icon ?? const SizedBox.shrink(),
      isSelected: false,
      tooltip: _optionsResolver.tooltip,
      onPressed: () => _onPressed(context),
      afterPressed: _optionsResolver.afterButtonPressed,
      iconTheme: _optionsResolver.iconTheme,
    );
  }
}
