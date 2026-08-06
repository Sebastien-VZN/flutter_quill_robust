import 'package:flutter/material.dart';
import 'package:flutter_quill/src/common/utils/quill_debug_logs.dart';
import 'package:flutter_quill/src/common/utils/widgets.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';

class QuillToolbarFontSizeButton extends QuillToolbarBaseButton<QuillToolbarFontSizeButtonOptions, QuillToolbarFontSizeButtonExtraOptions> {
  QuillToolbarFontSizeButton({
    required super.controller,
    super.options = const QuillToolbarFontSizeButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  }) {
    // Guards défensifs — remplacent les assert() pour éviter les crash en
    // production. Les options sont déjà construites et finales, on loggue
    // simplement les violations d'invariants.
    if (options.items != null && options.items!.isEmpty) {
      quillDebugPrint(
        'QuillToolbarFontSizeButton — items is empty, will use defaults',
      );
    }
    if (options.initialValue != null && options.initialValue!.isEmpty) {
      quillDebugPrint(
        'QuillToolbarFontSizeButton — initialValue is empty, ignoring',
      );
    }
  }

  @override
  QuillToolbarFontSizeButtonState createState() => QuillToolbarFontSizeButtonState();
}

class QuillToolbarFontSizeButtonState
    extends
        QuillToolbarBaseButtonState<QuillToolbarFontSizeButton, QuillToolbarFontSizeButtonOptions, QuillToolbarFontSizeButtonExtraOptions, String> {
  final _menuController = MenuController();

  Map<String, String> get _items {
    final fontSizes =
        options.items ??
        {
          context.loc.small: 'small',
          context.loc.large: 'large',
          context.loc.huge: 'huge',
          context.loc.clear: '0',
        };
    return fontSizes;
  }

  String? getLabel(String? currentValue) {
    return switch (currentValue) {
      'small' => context.loc.small,
      'large' => context.loc.large,
      'huge' => context.loc.huge,
      String() => currentValue,
      null => null,
    };
  }

  String get _defaultDisplayText {
    return options.initialValue ?? widget.options.defaultDisplayText ?? context.loc.fontSize;
  }

  @override
  String get currentStateValue {
    final attribute = controller.getSelectionStyle().attributes[options.attribute.key];
    return attribute == null ? _defaultDisplayText : (_getKeyName(attribute.value) ?? _defaultDisplayText);
  }

  String? _getKeyName(dynamic value) {
    for (final entry in _items.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  String get defaultTooltip => context.loc.fontSize;

  @override
  IconData get defaultIconData => Icons.format_size_outlined;

  void _onDropdownButtonPressed() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
    afterButtonPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarFontSizeButtonExtraOptions(
          controller: controller,
          currentValue: currentValue,
          defaultDisplayText: _defaultDisplayText,
          context: context,
          onPressed: _onDropdownButtonPressed,
        ),
      );
    }
    return MenuAnchor(
      controller: _menuController,
      menuChildren: _items.entries.map((fontSize) {
        return MenuItemButton(
          key: ValueKey(fontSize.key),
          onPressed: () {
            final newValue = fontSize.value;

            final keyName = _getKeyName(newValue);
            setState(() {
              if (keyName != context.loc.clear) {
                currentValue = keyName ?? _defaultDisplayText;
              } else {
                currentValue = _defaultDisplayText;
              }
              if (keyName != null) {
                controller.formatSelection(
                  FormatAttribute.fromKeyValue(
                    FormatAttribute.size.key,
                    newValue == '0' ? null : newValue,
                  ),
                );
                options.onSelected?.call(newValue);
              }
            });
          },
          child: Text(
            fontSize.key,
            style: TextStyle(
              color: fontSize.value == '0' ? options.defaultItemColor : null,
            ),
          ),
        );
      }).toList(),
      child: Builder(
        builder: (context) {
          final isMaterial3 = Theme.of(context).useMaterial3;
          if (!isMaterial3) {
            return RawMaterialButton(
              onPressed: _onDropdownButtonPressed,
              child: _buildContent(context),
            );
          }
          return QuillToolbarIconButton(
            tooltip: tooltip,
            isSelected: false,
            iconTheme: iconTheme,
            onPressed: _onDropdownButtonPressed,
            icon: _buildContent(context),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasFinalWidth = options.width != null;
    return Padding(
      padding: options.padding ?? const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Row(
        mainAxisSize: !hasFinalWidth ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UtilityWidgets.maybeWidget(
            enabled: hasFinalWidth,
            wrapper: (child) => Expanded(child: child),
            child: Text(
              getLabel(currentValue) ?? '',
              overflow: options.labelOverflow,
              style: options.style ?? TextStyle(fontSize: iconSize / 1.15),
            ),
          ),
          Icon(Icons.arrow_drop_down, size: iconSize * iconButtonFactor),
        ],
      ),
    );
  }
}
