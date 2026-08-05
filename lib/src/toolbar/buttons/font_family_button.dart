import 'package:flutter/material.dart';

import 'package:flutter_quill/src/common/utils/widgets.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';

class QuillToolbarFontFamilyButton extends QuillToolbarBaseButton<QuillToolbarFontFamilyButtonOptions, QuillToolbarFontFamilyButtonExtraOptions> {
  QuillToolbarFontFamilyButton({
    required super.controller,
    super.options = const QuillToolbarFontFamilyButtonOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  }) {
    // Guards défensifs — remplacent les assert() pour éviter les crash en
    // production. Les options sont déjà construites et finales, on loggue
    // simplement les violations d'invariants.
    if (options.items != null && options.items!.isEmpty) {
      debugPrint(
        'QuillToolbarFontFamilyButton — items is empty, will use defaults',
      );
    }
    if (options.initialValue != null && options.initialValue!.isEmpty) {
      debugPrint(
        'QuillToolbarFontFamilyButton — initialValue is empty, ignoring',
      );
    }
  }

  @override
  QuillToolbarFontFamilyButtonState createState() => QuillToolbarFontFamilyButtonState();
}

class QuillToolbarFontFamilyButtonState
    extends
        QuillToolbarBaseButtonState<
          QuillToolbarFontFamilyButton,
          QuillToolbarFontFamilyButtonOptions,
          QuillToolbarFontFamilyButtonExtraOptions,
          String
        > {
  @override
  String get currentStateValue {
    final attribute = controller.getSelectionStyle().attributes[options.attribute.key];
    return attribute == null ? _defaultDisplayText : (_getKeyName(attribute.stringValue.toString()) ?? _defaultDisplayText);
  }

  String get _defaultDisplayText {
    return options.initialValue ?? widget.options.defaultDisplayText ?? context.loc.font;
  }

  Map<String, String> get _items {
    final fontFamilies =
        options.items ??
        {
          'Sans Serif': 'sans-serif',
          'Serif': 'serif',
          'Monospace': 'monospace',
          'Ibarra Real Nova': 'ibarra-real-nova',
          'SquarePeg': 'square-peg',
          'Nunito': 'nunito',
          'Pacifico': 'pacifico',
          'Roboto Mono': 'roboto-mono',
          context.loc.clear: 'Clear',
        };
    return fontFamilies;
  }

  String? _getKeyName(String value) {
    for (final entry in _items.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  String get defaultTooltip => context.loc.fontFamily;

  @override
  IconData get defaultIconData => Icons.font_download_outlined;

  void _onPressed() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
    afterButtonPressed?.call();
  }

  final _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final childBuilder = this.childBuilder;
    if (childBuilder != null) {
      return childBuilder(
        options,
        QuillToolbarFontFamilyButtonExtraOptions(
          currentValue: currentValue,
          defaultDisplayText: _defaultDisplayText,
          controller: controller,
          context: context,
          onPressed: _onPressed,
        ),
      );
    }
    return UtilityWidgets.maybeWidget(
      enabled: tooltip.isNotEmpty || options.overrideTooltipByFontFamily,
      wrapper: (child) {
        var effectiveTooltip = tooltip;
        if (options.overrideTooltipByFontFamily) {
          effectiveTooltip = effectiveTooltip.isNotEmpty ? '$effectiveTooltip: $currentValue' : '${context.loc.font}: $currentValue';
        }
        return Tooltip(message: effectiveTooltip, child: child);
      },
      child: MenuAnchor(
        controller: _menuController,
        menuChildren: [
          for (final MapEntry<String, String> fontFamily in _items.entries)
            MenuItemButton(
              key: ValueKey(fontFamily.key),
              onPressed: () {
                final newValue = fontFamily.value;
                final keyName = _getKeyName(newValue);
                setState(() {
                  if (keyName != 'Clear') {
                    currentValue = keyName ?? _defaultDisplayText;
                  } else {
                    currentValue = _defaultDisplayText;
                  }
                  if (keyName != null) {
                    controller.formatSelection(
                      FormatAttribute.fromKeyValue(
                        FormatAttribute.font.key,
                        newValue == 'Clear' ? null : newValue,
                      ),
                    );
                    options.onSelected?.call(newValue);
                  }
                });
              },
              child: Text(
                fontFamily.key,
                style: TextStyle(
                  fontFamily: options.renderFontFamilies ? fontFamily.value : null,
                  color: fontFamily.value == 'Clear' ? options.defaultItemColor : null,
                ),
              ),
            ),
        ],
        child: Builder(
          builder: (context) {
            final isMaterial3 = Theme.of(context).useMaterial3;
            if (!isMaterial3) {
              return RawMaterialButton(
                onPressed: _onPressed,
                child: _buildContent(context),
              );
            }
            return QuillToolbarIconButton(
              isSelected: false,
              iconTheme: iconTheme,
              onPressed: _onPressed,
              icon: _buildContent(context),
            );
          },
        ),
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
              currentValue,
              maxLines: 1,
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
