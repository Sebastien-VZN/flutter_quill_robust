import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_quill/src/common/structs/horizontal_spacing.dart';
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:flutter_quill/src/document/nodes/block.dart';
import 'package:flutter_quill/src/document/nodes/node.dart';
import 'package:flutter_quill/src/editor/widgets/default_styles.dart';

typedef LeadingBlockIndentWidth =
    HorizontalSpacing Function(
      Block block,
      BuildContext context,
      int count,
      LeadingBlockNumberPointWidth numberPointWidthDelegate,
    );

typedef LeadingBlockNumberPointWidth = double Function(double fontSize, int count);

typedef TextSpanBuilder =
    InlineSpan Function(
      BuildContext context,
      Node node,
      int nodeOffset,
      String text,
      TextStyle? style,
      GestureRecognizer? recognizer,
    );

TextSpan defaultSpanBuilder(
  BuildContext context,
  Node node,
  int textOffset,
  String text,
  TextStyle? style,
  GestureRecognizer? recognizer,
) => TextSpan(
  text: text,
  style: style,
  recognizer: recognizer,
  mouseCursor: (recognizer != null) ? SystemMouseCursors.click : null,
);

abstract final class TextBlockUtils {
  /// Get the horizontalSpacing using the default
  /// implementation provided by [Flutter Quill]
  static HorizontalSpacing defaultIndentWidthBuilder(
    Block block,
    BuildContext context,
    int count,
    LeadingBlockNumberPointWidth numberPointWidthBuilder,
  ) {
    final defaultStyles = QuillStyles.getStyles(context, false)!;
    final fontSize = defaultStyles.paragraph?.style.fontSize ?? 16;
    final attrs = block.style.attributes;

    final indent = attrs[FormatAttribute.indent.key];
    var extraIndent = 0.0;
    final indentLevel = indent?.intValue;
    if (indentLevel != null) {
      extraIndent = fontSize * indentLevel;
    }

    if (attrs.containsKey(FormatAttribute.blockQuote.key)) {
      return HorizontalSpacing(fontSize + extraIndent, 0);
    }

    var baseIndent = 0.0;

    if (attrs.containsKey(FormatAttribute.list.key)) {
      baseIndent = fontSize * 2;
      if (attrs[FormatAttribute.list.key] == FormatAttribute.ol) {
        baseIndent = numberPointWidthBuilder(fontSize, count);
      } else if (attrs.containsKey(FormatAttribute.codeBlock.key)) {
        baseIndent = numberPointWidthBuilder(fontSize, count);
      }
    }

    return HorizontalSpacing(baseIndent + extraIndent, 0);
  }

  /// Get the width for the number point leading using the default
  /// implementation provided by [Flutter Quill]
  static double defaultNumberPointWidthBuilder(double fontSize, int count) {
    final length = '$count'.length;
    switch (length) {
      case 1:
      case 2:
        return fontSize * 2;
      default:
        // 3 -> 2.5
        // 4 -> 3
        // 5 -> 3.5
        return fontSize * (length - (length - 2) / 2);
    }
  }
}
