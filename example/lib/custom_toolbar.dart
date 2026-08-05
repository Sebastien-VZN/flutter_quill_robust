import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CustomToolbar extends StatelessWidget {
  const CustomToolbar({required this.controller, super.key});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        children: [
          QuillToolbarHistoryButton(isUndo: true, controller: controller),
          QuillToolbarHistoryButton(isUndo: false, controller: controller),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: FormatAttribute.bold,
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: FormatAttribute.italic,
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: FormatAttribute.underline,
          ),
          QuillToolbarClearFormatButton(controller: controller),
          const VerticalDivider(),
          QuillToolbarColorButton(controller: controller, isBackground: false),
          QuillToolbarColorButton(controller: controller, isBackground: true),
          const VerticalDivider(),
          QuillToolbarSelectHeaderStyleDropdownButton(controller: controller),
          const VerticalDivider(),
          QuillToolbarSelectLineHeightStyleDropdownButton(
            controller: controller,
          ),
          const VerticalDivider(),
          QuillToolbarToggleCheckListButton(controller: controller),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: FormatAttribute.ol,
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: FormatAttribute.ul,
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: FormatAttribute.inlineCode,
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: FormatAttribute.blockQuote,
          ),
          QuillToolbarIndentButton(controller: controller, isIncrease: true),
          QuillToolbarIndentButton(controller: controller, isIncrease: false),
          const VerticalDivider(),
          QuillToolbarLinkStyleButton(controller: controller),
        ],
      ),
    );
  }
}
