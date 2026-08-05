import 'package:flutter_quill/src/controller/quill_controller.dart';
import 'package:flutter_quill/src/editor_toolbar_controller_shared/quill_config.dart';
import 'package:flutter_quill/src/toolbar/embed/embed_button_builder.dart';
import 'package:flutter_quill/src/toolbar/theme/quill_dialog_theme.dart';
import 'package:flutter_quill/src/toolbar/theme/quill_icon_theme.dart';
import 'package:meta/meta.dart';

/// Encapsulates the context required for embedding a button in a toolbar.
///
/// This class holds essential parameters for configuring embedded toolbar button,
/// and it is used within the [EmbedButtonBuilder] interface.
///
/// See also:
///
/// * [EmbedButtonBuilder]
class EmbedButtonContext {
  @internal
  EmbedButtonContext({
    required this.controller,
    required this.toolbarIconSize,
    required this.iconTheme,
    required this.dialogTheme,
    required this.baseButtonOptions,
  });

  /// The [QuillController] managing the editor's state.
  final QuillController controller;
  final double toolbarIconSize;
  final QuillIconTheme? iconTheme;
  final QuillDialogTheme? dialogTheme;

  @internal
  final QuillToolbarBaseButtonOptions<dynamic, dynamic>? baseButtonOptions;
}
