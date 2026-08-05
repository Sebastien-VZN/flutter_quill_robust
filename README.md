# Flutter Quill Robust

A production-hardened fork of [flutter_quill](https://pub.dev/packages/flutter_quill) focused on **text-only rich editing**, **strict typing**, and **zero analyzer errors**.

## What changed from upstream

- **No media embeds** — image, video, gif, and camera blocks have been removed. The editor supports only `formula` and `custom` embeds.
- **Strict typing** — `FormatAttribute` replaces the 22 upstream `Attribute<T>` subclasses, with a `FormatValueType` enum and typed accessors (`intValue`, `stringValue`, `boolValue`, `numberValue`).
- **No asserts in production** — defensive guards with `debugPrint` instead of `assert()`.
- **Centralized casting** — `DataCaster` handles all `Object?` → typed conversions with debug logging on mismatch.
- **Clean clipboard** — `ClipboardService` uses only text, HTML, and Markdown operations through `quill_native_bridge`.
- **Strict linter** — `very_good_analysis` with `strict-casts`, `strict-inference`, and `strict-raw-types` enabled.
- **Delta converters moved** — `HtmlToDelta` and `MarkdownToDelta` live in the `quill_native_bridge` package.

## Install

```yaml
dependencies:
  flutter_quill:
    git:
      url: https://github.com/Sebastien-VZN/flutter_quill_robust.git
      ref: master
```

Override `quill_native_bridge` with the matching fork:

```yaml
dependency_overrides:
  quill_native_bridge:
    git:
      url: https://github.com/Sebastien-VZN/quill_native_bridge_robust.git
      path: quill_native_bridge
```

## Basic usage

```dart
import 'package:flutter_quill/flutter_quill.dart';

final controller = QuillController.basic();

QuillSimpleToolbar(
  controller: controller,
  config: const QuillSimpleToolbarConfig(),
),
Expanded(
  child: QuillEditor.basic(
    controller: controller,
    config: const QuillEditorConfig(),
  ),
)
```

## Input / Output

Documents are stored as [Quill Delta](https://quilljs.com/docs/delta/).

```dart
final json = jsonEncode(controller.document.toDelta().toJson());
controller.document = Document.fromJson(jsonDecode(json));
```

## Testing

```bash
flutter test test/
dart format -l 150 --set-exit-if-changed .
flutter analyze --no-fatal-infos --no-fatal-warnings
```

## Related forks

- [`quill_native_bridge_robust`](https://github.com/Sebastien-VZN/quill_native_bridge_robust) — federated plugin for text/HTML/Markdown clipboard.

---

Original project: [flutter_quill](https://github.com/singerdmx/flutter-quill).  
Maintained by [Sebastien-VZN](https://github.com/Sebastien-VZN).
