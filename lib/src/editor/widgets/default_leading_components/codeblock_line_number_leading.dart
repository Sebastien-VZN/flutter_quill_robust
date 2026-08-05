import 'package:flutter/material.dart';
import 'package:flutter_quill/src/editor/raw_editor/builders/leading_block_builder.dart';
import 'package:flutter_quill/src/editor/style_widgets/style_widgets.dart';

Widget codeBlockLineNumberLeading(LeadingConfig config) => QuillNumberPoint(
  index: config.getIndexNumberByIndent!,
  indentLevelCounts: config.indentLevelCounts,
  count: config.count,
  style: config.style!,
  attrs: config.attrs,
  width: config.width!,
  padding: config.padding!,
);
