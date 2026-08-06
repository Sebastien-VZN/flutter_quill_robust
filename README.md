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
- **Centralized debug logs** — all internal `debugPrint` calls go through `quillDebugPrint()` (see `QuillDebugLogs`). Disabled by default; opt in via `QuillEditorConfig(enableDebugLogs: true)` to surface `DataCaster` type-mismatch traces and other internal debug output.
- **Emoji picker (desktop)** — toolbar button that opens a dropdown emoji picker anchored below the button. Material 3 `MenuAnchor` pattern, theme-aware, backed by `emoji_picker_flutter` (1500+ emojis, 8 categories, search bar, skin tones).

## Emoji picker (desktop)

Because typing `¯\_(ツ)_/¯` by hand is so 2015.

The toolbar ships with an optional **emoji button** for desktop platforms. On mobile, the native keyboard emoji palette is the input path, so the button is not rendered there — no redundancy, no clutter.

```dart
QuillSimpleToolbar(
  controller: controller,
  config: const QuillSimpleToolbarConfig(
    showEmojiButton: true, // default; desktop-only via isDesktop gating
  ),
)
```

### How it works

- **Dropdown anchored below the button** via Material 3 `MenuAnchor` — same pattern as the font-family / font-size / header-style / line-height dropdowns. Tap the button to open, tap again to close, or tap outside.
- **Stays open after each emoji selection** — insert a whole string of 🎉🎊🥳 in one go without reopening the picker.
- **Insertion at the cursor position** via `QuillController.replaceText` — the emoji lands exactly where your caret is, not at the end of the document.
- **Theme-aware colors** — no project-specific palette; the picker adapts to your app's `Theme.of(context)` automatically.
- **Sizing tunable** via `QuillToolbarEmojiButtonOptions.menuWidth` (default 320) and `menuHeight` (default 400).

### What's inside

Backed by [`emoji_picker_flutter`](https://pub.dev/packages/emoji_picker_flutter) (^4.5.3, Flutter >=3.41.8):

- **1500+ emojis** across 8 categories (Smileys, Animals, Food, Activities, Travel, Objects, Symbols, Flags)
- **Search bar** to find that one emoji you know exists but can't remember where it is
- **Skin tone support** with long-press selection
- **Recently used** tab (optional, persisted via `SharedPreferences`)

### Disable it

```dart
const QuillSimpleToolbarConfig(showEmojiButton: false)
```

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
