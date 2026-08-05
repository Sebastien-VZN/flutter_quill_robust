import 'package:flutter/material.dart';
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/toolbar/buttons/toggle_style_button.dart';
import 'package:flutter_quill/src/toolbar/config/simple_toolbar_button_options.dart';

class QuillToolbarSelectAlignmentButtons extends StatelessWidget {
  const QuillToolbarSelectAlignmentButtons({
    required this.controller,
    this.options = const QuillToolbarSelectAlignmentButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    this.baseOptions,
    super.key,
  });

  final QuillToolbarBaseButtonOptions<dynamic, dynamic>? baseOptions;

  // This button doesn't support the base button option

  final QuillController controller;
  final QuillToolbarSelectAlignmentButtonOptions options;

  List<FormatAttribute> get _attrbuites {
    return options.attributes ??
        [
          if (options.showLeftAlignment) FormatAttribute.leftAlignment,
          if (options.showCenterAlignment) FormatAttribute.centerAlignment,
          if (options.showRightAlignment) FormatAttribute.rightAlignment,
          if (options.showJustifyAlignment) FormatAttribute.justifyAlignment,
        ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _attrbuites
          .map(
            (e) => QuillToolbarToggleStyleButton(
              baseOptions: baseOptions,
              controller: controller,
              attribute: e,
              options: QuillToolbarToggleStyleButtonOptions(
                iconData: options.iconData,
                iconSize: options.iconSize,
                iconButtonFactor: options.iconButtonFactor,
                afterButtonPressed: options.afterButtonPressed,
                iconTheme: options.iconTheme,
                tooltip: options.tooltip,
              ),
            ),
          )
          .toList(),
    );
  }
}
