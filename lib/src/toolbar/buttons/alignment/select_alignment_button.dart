import 'package:flutter/material.dart';

import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';

enum _AlignmentOptions {
  left(attribute: FormatAttribute.leftAlignment),
  center(attribute: FormatAttribute.centerAlignment),
  right(attribute: FormatAttribute.rightAlignment),
  justifyMinWidth(attribute: FormatAttribute.justifyAlignment);

  const _AlignmentOptions({required this.attribute});

  final FormatAttribute attribute;
}

/// Dropdown button
class QuillToolbarSelectAlignmentButton extends StatelessWidget {
  const QuillToolbarSelectAlignmentButton({
    required this.controller,
    super.key,
  });
  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: _AlignmentOptions.values
          .map(
            (e) => MenuItemButton(
              child: Text(e.name),
              onPressed: () {
                controller.formatSelection(e.attribute);
              },
            ),
          )
          .toList(),
    );
  }
}
