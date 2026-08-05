import 'package:flutter/material.dart';
import 'package:flutter_quill/src/common/utils/widgets.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/style.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/buttons/toggle_style_button.dart';
import 'package:flutter_quill/src/toolbar/config/buttons/toggle_check_list_options.dart';

class QuillToolbarToggleCheckListButton
    extends QuillToolbarBaseButton<QuillToolbarToggleCheckListButtonOptions, QuillToolbarToggleCheckListButtonExtraOptions> {
  const QuillToolbarToggleCheckListButton({
    required super.controller,
    super.options = const QuillToolbarToggleCheckListButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  });

  @override
  QuillToolbarToggleCheckListButtonState createState() => QuillToolbarToggleCheckListButtonState();
}

class QuillToolbarToggleCheckListButtonState
    extends
        QuillToolbarBaseButtonState<
          QuillToolbarToggleCheckListButton,
          QuillToolbarToggleCheckListButtonOptions,
          QuillToolbarToggleCheckListButtonExtraOptions,
          bool
        > {
  Style get _selectionStyle => controller.getSelectionStyle();

  @override
  bool get currentStateValue => _getIsToggled(_selectionStyle.attributes);

  bool _getIsToggled(Map<String, FormatAttribute> attrs) {
    var attribute = controller.toolbarButtonToggler[FormatAttribute.list.key];

    if (attribute == null) {
      attribute = attrs[FormatAttribute.list.key];
    } else {
      // checkbox tapping causes controller.selection to go to offset 0
      controller.toolbarButtonToggler.remove(FormatAttribute.list.key);
    }

    if (attribute == null) {
      return false;
    }
    return attribute.value == FormatAttribute.unchecked.value || attribute.value == FormatAttribute.checked.value;
  }

  @override
  String get defaultTooltip => context.loc.checkedList;

  @override
  IconData get defaultIconData => Icons.check_box;

  @override
  Widget build(BuildContext context) {
    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarToggleCheckListButtonExtraOptions(
          context: context,
          controller: controller,
          onPressed: () {
            _toggleAttribute();
            afterButtonPressed?.call();
          },
          isToggled: currentValue,
        ),
      );
    }
    return UtilityWidgets.maybeTooltip(
      message: tooltip,
      child: defaultToggleStyleButtonBuilder(
        context,
        FormatAttribute.unchecked,
        iconData,
        currentValue,
        _toggleAttribute,
        afterButtonPressed,
        iconSize,
        iconButtonFactor,
        iconTheme,
      ),
    );
  }

  void _toggleAttribute() {
    controller
      ..skipRequestKeyboard = !options.shouldRequestKeyboard
      ..formatSelection(
        currentValue ? FormatAttribute.clone(FormatAttribute.unchecked, null) : FormatAttribute.unchecked,
      );
  }
}
