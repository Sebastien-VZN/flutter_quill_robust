import 'package:flutter/foundation.dart' show immutable;

import 'package:flutter_quill/src/document/nodes/leaf.dart';
import 'package:flutter_quill/src/document/nodes/line.dart';

@immutable
class SegmentLeafNode {
  const SegmentLeafNode(this.line, this.leaf);

  final Line? line;
  final Leaf? leaf;
}
