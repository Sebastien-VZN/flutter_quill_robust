import 'package:flutter/widgets.dart';
import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/document/nodes/leaf.dart' as leaf;
import 'package:flutter_quill/src/editor/embed/embed_editor_builder.dart';
import 'package:meta/meta.dart';

/// Encapsulates the context required for embedding content in a rich text editor.
///
/// This class holds essential parameters for configuring embedded content,
/// and it is used within the [EmbedBuilder] interface.
///
/// See also:
///
/// * [leaf.Embed]
/// * [EmbedBuilder]
class EmbedContext {
  @internal
  EmbedContext({
    required this.controller,
    required this.node,
    required this.readOnly,
    required this.inline,
    required this.textStyle,
  });

  /// The [QuillController] managing the editor's state.
  final QuillController controller;

  /// The [leaf.Embed] instance representing the embedded content.
  final leaf.Embed node;

  /// Indicates if the editor is in read-only mode.
  final bool readOnly;

  /// Indicates if the embed should be rendered inline.
  final bool inline;

  /// The [TextStyle] to apply to the embedded content.
  final TextStyle textStyle;
}
