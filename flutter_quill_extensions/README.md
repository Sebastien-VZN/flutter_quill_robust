# Flutter Quill Extensions

An extension package for [flutter_quill_robust](../README.md) that provides **custom embed builders** for the editor.

> This fork has removed all media embed blocks (image, video, gif, camera). Only custom embed blocks remain.

## Install

```yaml
dependencies:
  flutter_quill_extensions:
    git:
      url: https://github.com/Sebastien-VZN/flutter_quill_robust.git
      ref: master
      path: flutter_quill_extensions
```

## Usage

```dart
QuillSimpleToolbar(
  config: QuillSimpleToolbarConfig(
    embedButtons: FlutterQuillEmbeds.toolbarButtons(),
  ),
),

QuillEditor.basic(
  config: QuillEditorConfig(
    embedBuilders: FlutterQuillEmbeds.editorBuilders(),
  ),
)
```

## Custom embed blocks

Provide your own `EmbedBuilder` and `EmbedButton` implementations for any non-media widget you want to render inside the editor. For implementation guidance, see the upstream [custom embed blocks documentation](https://github.com/singerdmx/flutter-quill/blob/master/doc/custom_embed_blocks.md).

## Platform setup

No image or video permissions are required by this fork. `quill_native_bridge` is used for clipboard operations only (text, HTML, Markdown).
