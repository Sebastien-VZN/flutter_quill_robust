import 'package:flutter/material.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/stateless_base_button.dart';
import 'package:flutter_quill/src/toolbar/buttons/quill_icon_button.dart';
import 'package:flutter_quill/src/toolbar/config/buttons/clear_format_options.dart';

class QuillToolbarClearFormatButton
    extends QuillToolbarBaseButtonStateless<QuillToolbarClearFormatButtonOptions, QuillToolbarClearFormatButtonExtraOptions> {
  const QuillToolbarClearFormatButton({
    required super.controller,
    QuillToolbarClearFormatButtonOptions? options,

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  }) : super(options: options);

  void _sharedOnPressed() {
    final attributes = <FormatAttribute>{};
    for (final style in controller.getAllSelectionStyles()) {
      style.attributes.values.forEach(attributes.add);
    }
    for (final attribute in attributes) {
      controller.formatSelection(FormatAttribute.clone(attribute, null));
    }
  }

  @override
  Widget buildButton(BuildContext context) {
    return QuillToolbarIconButton(
      tooltip: tooltip(context),
      icon: Icon(
        iconData(context),
        size: iconSize(context) * iconButtonFactor(context),
      ),
      isSelected: false,
      onPressed: _sharedOnPressed,
      afterPressed: afterButtonPressed(context),
      iconTheme: iconTheme(context),
    );
  }

  @override
  Widget? buildCustomChildBuilder(BuildContext context) {
    return options?.childBuilder?.call(
      options! as QuillToolbarClearFormatButtonOptions,
      QuillToolbarClearFormatButtonExtraOptions(
        controller: controller,
        context: context,
        onPressed: () {
          _sharedOnPressed();
          afterButtonPressed(context)?.call();
        },
      ),
    );
  }

  @override
  IconData Function(BuildContext context) get getDefaultIconData =>
      (context) => Icons.format_clear;

  @override
  String Function(BuildContext context) get getDefaultTooltip =>
      (context) => context.loc.clearFormat;
}
