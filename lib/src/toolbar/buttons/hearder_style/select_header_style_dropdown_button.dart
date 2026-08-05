import 'package:flutter/material.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/buttons/quill_icon_button.dart';
import 'package:flutter_quill/src/toolbar/config/buttons/select_header_style_dropdown_button_options.dart';

typedef QuillToolbarSelectHeaderStyleDropdownBaseButton =
    QuillToolbarBaseButton<QuillToolbarSelectHeaderStyleDropdownButtonOptions, QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions>;

typedef QuillToolbarSelectHeaderStyleDropdownBaseButtonsState<W extends QuillToolbarSelectHeaderStyleDropdownButton> =
    QuillToolbarCommonButtonState<W, QuillToolbarSelectHeaderStyleDropdownButtonOptions, QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions>;

class QuillToolbarSelectHeaderStyleDropdownButton extends QuillToolbarSelectHeaderStyleDropdownBaseButton {
  const QuillToolbarSelectHeaderStyleDropdownButton({
    required super.controller,
    super.options = const QuillToolbarSelectHeaderStyleDropdownButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  });

  @override
  QuillToolbarSelectHeaderStyleDropdownBaseButtonsState createState() => _QuillToolbarSelectHeaderStyleDropdownButtonState();
}

class _QuillToolbarSelectHeaderStyleDropdownButtonState extends QuillToolbarSelectHeaderStyleDropdownBaseButtonsState {
  @override
  String get defaultTooltip => context.loc.headerStyle;

  @override
  IconData get defaultIconData => Icons.question_mark_outlined;

  FormatAttribute _selectedItem = FormatAttribute.header;

  final _menuController = MenuController();
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeEditingValue);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }

  @override
  void didUpdateWidget(
    covariant QuillToolbarSelectHeaderStyleDropdownButton oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    widget.controller
      ..removeListener(_didChangeEditingValue)
      ..addListener(_didChangeEditingValue);
  }

  void _didChangeEditingValue() {
    final newSelectedItem = _getHeaderValue();
    if (newSelectedItem == _selectedItem) {
      return;
    }
    setState(() {
      _selectedItem = newSelectedItem;
    });
  }

  FormatAttribute _getHeaderValue() {
    final attr = widget.controller.toolbarButtonToggler[FormatAttribute.header.key];
    if (attr != null) {
      // checkbox tapping causes controller.selection to go to offset 0
      widget.controller.toolbarButtonToggler.remove(FormatAttribute.header.key);
      return attr;
    }
    return widget.controller.getSelectionStyle().attributes[FormatAttribute.header.key] ?? FormatAttribute.header;
  }

  String _label(FormatAttribute value) {
    final label = switch (value) {
      FormatAttribute.h1 => context.loc.heading1,
      FormatAttribute.h2 => context.loc.heading2,
      FormatAttribute.h3 => context.loc.heading3,
      FormatAttribute.h4 => context.loc.heading4,
      FormatAttribute.h5 => context.loc.heading5,
      FormatAttribute.h6 => context.loc.heading6,
      FormatAttribute.header => widget.options.defaultDisplayText ?? context.loc.normal,
      _ => throw ArgumentError(),
    };
    return label;
  }

  List<FormatAttribute> get headerAttributes {
    return widget.options.attributes ??
        [
          FormatAttribute.h1,
          FormatAttribute.h2,
          FormatAttribute.h3,
          FormatAttribute.header,
        ];
  }

  void _onPressed(FormatAttribute e) {
    setState(() => _selectedItem = e);
    widget.controller.formatSelection(_selectedItem);
  }

  @override
  Widget build(BuildContext context) {
    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        widget.options,
        QuillToolbarSelectHeaderStyleDropdownButtonExtraOptions(
          currentValue: _selectedItem,
          context: context,
          controller: widget.controller,
          onPressed: () {
            throw UnimplementedError('Not implemented yet.');
          },
        ),
      );
    }

    return MenuAnchor(
      controller: _menuController,
      menuChildren: headerAttributes
          .map(
            (e) => MenuItemButton(
              onPressed: () {
                _onPressed(e);
              },
              child: Text(_label(e)),
            ),
          )
          .toList(),
      child: Builder(
        builder: (context) {
          final isMaterial3 = Theme.of(context).useMaterial3;
          final child = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _label(_selectedItem),
                style: widget.options.textStyle ?? TextStyle(fontSize: iconSize / 1.15),
              ),
              Icon(Icons.arrow_drop_down, size: iconSize * iconButtonFactor),
            ],
          );
          if (!isMaterial3) {
            return RawMaterialButton(
              onPressed: _onDropdownButtonPressed,
              child: child,
            );
          }
          return QuillToolbarIconButton(
            onPressed: _onDropdownButtonPressed,
            icon: child,
            isSelected: false,
            iconTheme: iconTheme,
            tooltip: tooltip,
          );
        },
      ),
    );
  }

  void _onDropdownButtonPressed() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
    afterButtonPressed?.call();
  }
}
