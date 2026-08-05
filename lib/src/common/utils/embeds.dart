import 'dart:math';

import 'package:flutter_quill/src/common/structs/offset_value.dart';
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/document/nodes/leaf.dart';

OffsetStyleValue<Embed> getEmbedNode(QuillController controller, int offset) {
  var offset = controller.selection.start;
  var embedNode = controller.queryNode(offset);
  if (embedNode == null || embedNode is! Embed) {
    offset = max(0, offset - 1);
    embedNode = controller.queryNode(offset);
  }
  if (embedNode != null && embedNode is Embed) {
    return OffsetStyleValue(offset, embedNode);
  }

  return throw ArgumentError('Embed node not found by offset $offset');
}
