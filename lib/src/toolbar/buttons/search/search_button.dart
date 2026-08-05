import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_quill/src/l10n/extensions/localizations_ext.dart';
import 'package:flutter_quill/src/toolbar/base_button/stateless_base_button.dart';
import 'package:flutter_quill/src/toolbar/simple_toolbar.dart';

class QuillToolbarSearchButton extends QuillToolbarBaseButtonStateless<QuillToolbarSearchButtonOptions, QuillToolbarSearchButtonExtraOptions> {
  const QuillToolbarSearchButton({
    required super.controller,
    super.key,
    this._options,
  });

  final QuillToolbarSearchButtonOptions? _options;

  @override
  QuillToolbarSearchButtonOptions? get options => _options;

  void _sharedOnPressed(BuildContext context) {
    final customCallback = options?.customOnPressedCallback;
    if (customCallback != null) {
      customCallback(controller);
      return;
    }
    unawaited(
      showDialog<String>(
        context: context,
        builder: (_) => QuillToolbarSearchDialog(
          controller: controller,
          dialogTheme: options?.dialogTheme,
          searchBarAlignment: options?.searchBarAlignment,
        ),
      ),
    );
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
      onPressed: () => _sharedOnPressed(context),
      afterPressed: afterButtonPressed(context),
      iconTheme: iconTheme(context),
    );
  }

  @override
  Widget? buildCustomChildBuilder(BuildContext context) {
    return childBuilder?.call(
      options!,
      QuillToolbarSearchButtonExtraOptions(
        controller: controller,
        context: context,
        onPressed: () {
          _sharedOnPressed(context);
          afterButtonPressed.call(context);
        },
      ),
    );
  }

  @override
  IconData Function(BuildContext context) get getDefaultIconData =>
      (context) => Icons.search;

  @override
  String Function(BuildContext context) get getDefaultTooltip =>
      (context) => context.loc.search;
}
