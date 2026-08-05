import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/style.dart';
import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/base_value_button.dart';
import 'package:flutter_quill/src/toolbar/buttons/quill_icon_button.dart';
import 'package:flutter_quill/src/toolbar/config/buttons/select_header_style_buttons_options.dart';

typedef QuillToolbarSelectHeaderStyleBaseButtons =
    QuillToolbarBaseButton<QuillToolbarSelectHeaderStyleButtonsOptions, QuillToolbarSelectHeaderStyleButtonsExtraOptions>;

typedef QuillToolbarSelectHeaderStyleBaseButtonsState<W extends QuillToolbarSelectHeaderStyleBaseButtons> =
    QuillToolbarCommonButtonState<W, QuillToolbarSelectHeaderStyleButtonsOptions, QuillToolbarSelectHeaderStyleButtonsExtraOptions>;

class QuillToolbarSelectHeaderStyleButtons extends QuillToolbarSelectHeaderStyleBaseButtons {
  const QuillToolbarSelectHeaderStyleButtons({
    required super.controller,
    super.options = const QuillToolbarSelectHeaderStyleButtonsOptions(),

    /// Shares common options between all buttons, prefer the [options]
    /// over the [baseOptions].
    super.baseOptions,
    super.key,
  });

  @override
  QuillToolbarSelectHeaderStyleButtonsState createState() => QuillToolbarSelectHeaderStyleButtonsState();
}

class QuillToolbarSelectHeaderStyleButtonsState extends QuillToolbarSelectHeaderStyleBaseButtonsState {
  FormatAttribute? _selectedAttribute;

  @override
  String get defaultTooltip => context.loc.headerStyle;

  @override
  IconData get defaultIconData => Icons.question_mark_outlined;

  Style get _selectionStyle => controller.getSelectionStyle();

  final _valueToText = <FormatAttribute, String>{
    FormatAttribute.header: 'N',
    FormatAttribute.h1: 'H1',
    FormatAttribute.h2: 'H2',
    FormatAttribute.h3: 'H3',
  };

  @override
  void initState() {
    super.initState();
    setState(() {
      _selectedAttribute = _getHeaderValue();
    });
    controller.addListener(_didChangeEditingValue);
  }

  Axis get axis {
    return options.axis ?? Axis.horizontal;
  }

  void _sharedOnPressed(FormatAttribute attribute) {
    final attribute0 = _selectedAttribute == attribute ? FormatAttribute.header : attribute;
    controller.formatSelection(attribute0);
    afterButtonPressed?.call();
  }

  List<FormatAttribute> get _attributes {
    return options.attributes ??
        const [
          FormatAttribute.header,
          FormatAttribute.h1,
          FormatAttribute.h2,
          FormatAttribute.h3,
        ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_attributes.every((element) => _valueToText.keys.contains(element))) {
      debugPrint(
        'QuillToolbarSelectHeaderStyleButtons.build — All attributes must be one of them: header, h1, h2 or h3',
      );
    }

    final style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: iconSize * 0.7,
    );

    final childBuilder = this.childBuilder;

    final children = _attributes.map((attribute) {
      if (childBuilder != null) {
        return childBuilder(
          options,
          QuillToolbarSelectHeaderStyleButtonsExtraOptions(
            controller: controller,
            context: context,
            onPressed: () => _sharedOnPressed(attribute),
          ),
        );
      }

      final isSelected = _selectedAttribute == attribute;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: !kIsWeb ? 1.0 : 5.0),
        child: QuillToolbarIconButton(
          tooltip: tooltip,
          iconTheme: iconTheme,
          isSelected: isSelected,
          onPressed: () => _sharedOnPressed(attribute),
          icon: Text(
            _valueToText[attribute] ?? (throw ArgumentError.notNull('attribute')),
            style: style.copyWith(
              color: isSelected ? iconTheme?.iconButtonSelectedData?.color : iconTheme?.iconButtonUnselectedData?.color,
            ),
          ),
        ),
      );
    }).toList();

    return axis == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: children)
        : Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  void _didChangeEditingValue() {
    setState(() {
      _selectedAttribute = _getHeaderValue();
    });
  }

  FormatAttribute _getHeaderValue() {
    final attr = controller.toolbarButtonToggler[FormatAttribute.header.key];
    if (attr != null) {
      // checkbox tapping causes controller.selection to go to offset 0
      controller.toolbarButtonToggler.remove(FormatAttribute.header.key);
      return attr;
    }
    return _selectionStyle.attributes[FormatAttribute.header.key] ?? FormatAttribute.header;
  }

  @override
  void didUpdateWidget(
    covariant QuillToolbarSelectHeaderStyleButtons oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_didChangeEditingValue);
      controller.addListener(_didChangeEditingValue);
      _selectedAttribute = _getHeaderValue();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_didChangeEditingValue);
    super.dispose();
  }
}
