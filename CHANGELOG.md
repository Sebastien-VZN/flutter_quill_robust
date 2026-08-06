# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> [!NOTE]
> The [previous `CHANGELOG.md`](https://github.com/singerdmx/flutter-quill/blob/master/doc/OLD_CHANGELOG.md) has been archived.

## [Unreleased]

### Added

- **QuillControllerRichPaste.pasteHtml()** (`lib/src/controller/clipboard/quill_controller_rich_paste.dart`) — new rich-paste path that reads the `"HTML Format"` clipboard format via `ClipboardService.getHtmlText()` and converts it with `HtmlToDelta`. Wired into `clipboardPaste()` right after `pasteMarkdown()`, restoring the behaviour documented by `QuillClipboardConfig.enableExternalRichPaste`: external content pasted from Word, browsers and other apps keeps its styling (bold, italic, links, colors, sizes, headers, lists, alignment) instead of falling back to plain text.
- **Embed-to-URL sanitiser** in `pasteHtml()` — media embed operations produced by `HtmlToDelta` (`image`, `video`) are replaced with their source URL as plain text, since this fork removed media embed support. Embeds with no portable URL (tables) are dropped.
- **`pasteMarkdown()` resilience** — catches `UnimplementedError` so iOS / macOS / Web (where `getClipboardMarkdown` is declared supported but never overridden in `quill_native_bridge`) fall through to the HTML / plain-text paste paths instead of aborting the whole paste.
- **QuillDebugLogs** (`lib/src/common/utils/quill_debug_logs.dart`) — global debug-log manager with `quillDebugPrint()` wrapper. All `debugPrint` calls in the lib now route through this wrapper and stay silent unless enabled.
- **QuillEditorConfig.enableDebugLogs** — config flag (default `false`) that toggles `QuillDebugLogs.enabled` at editor init. Pass `enableDebugLogs: true` to surface `DataCaster` type-mismatch logs and other internal debug output.

### Fixed

- **ClipboardServiceProvider not a singleton** — `_instance` was an instance field, so every `ClipboardServiceProvider()` created a fresh provider bound to `DefaultClipboardService`. The service override hook (`instance` setter) had no effect on rich paste, which builds its own provider. The backing field is now `static`, making an override visible to every consumer.
- **ClipboardServiceProvider broken setter** — `set instance(...) => _instance;` returned the current value instead of assigning; now assigns `_instance = service`.

## [11.6.0] - 2026-08-06

### Added

- **QuillToolbarEmojiButton** (`lib/src/toolbar/buttons/emoji/emoji_button.dart`) — new desktop-only toolbar button that opens an emoji picker dropdown anchored below the button using Material 3 `MenuAnchor`. Pattern matches the existing font-family / font-size / header-style / line-height dropdowns. Insertion at the cursor position via `QuillController.replaceText`. Stays open after each emoji selection so the user can insert multiple emojis in a row; closes by toggling the same button or tapping outside.
- **QuillToolbarEmojiDialog** (`lib/src/toolbar/buttons/emoji/emoji_dialog.dart`) — theme-aware wrapper around `emoji_picker_flutter` `EmojiPicker` (8 categories + search bar). Colors sourced from `Theme.of(context)` (no project-specific palette). `Config.height` left null so the picker adapts to the parent `SizedBox`.
- **QuillToolbarEmojiButtonOptions** (`lib/src/toolbar/config/buttons/emoji_options.dart`) — new options class with `menuWidth` (default 320), `menuHeight` (default 400), `dialogTheme`, and `customOnPressedCallback`.
- **QuillSimpleToolbarConfig.showEmojiButton** — new config flag (default `true`). The button is rendered only when `showEmojiButton && isDesktop` (see `lib/src/common/utils/platform.dart`); on mobile the native keyboard emoji palette remains the input path.
- **Localization key `emoji`** — added to `lib/src/l10n/quill_en.arb`; `flutter gen-l10n` regenerated all 48 locale files. `scripts/translations_check.dart` `_expectedTranslationKeysLength` bumped from 117 to 118.
- **Dependency** — added `emoji_picker_flutter: ^4.5.3` (Flutter >=3.41.8 compatible) to `pubspec.yaml`.

### Changed

- **QuillSimpleToolbar** (`lib/src/toolbar/simple_toolbar.dart`) — `QuillToolbarEmojiButton` inserted in the search/clipboard group, right after `QuillToolbarSearchButton`, gated by `config.showEmojiButton && isDesktop`.
- **QuillSimpleToolbarButtonOptions** — new `emoji` field of type `QuillToolbarEmojiButtonOptions`.

## [11.5.4] - 2026-08-06

### Repository

- **Commit messages rewritten** — 14 non-conventional commit messages on `master` (between `v11.5.3+2` and HEAD) reworded to follow [Conventional Commits](https://www.conventionalcommits.org/). Commit content is byte-identical (`git diff backup/master-before-reword..HEAD` empty); tag `v11.5.3+2` and its GitHub release untouched. Backup branch `backup/master-before-reword` kept locally as a safety net.

### Added

- **DataCaster** (`lib/src/document/data_caster.dart`) — centralized type-casting utility with `debugPrint` logging on type mismatches. Provides `toInt()`, `toStr()`, `toBool()`, `toDouble()` static methods with optional `context` parameter for traceability.
- **FormatValueType** enum — runtime type marker (`boolean`, `string`, `nullableString`, `integer`, `nullableInteger`, `number`, `nullableNumber`) that compensates for Dart's lack of union types.
- **Typed accessors** on `FormatAttribute` — `intValue`, `stringValue`, `boolValue`, `numberValue` delegate to `DataCaster` with full context logging.
- **Typed accessors** on `Embeddable` — `intVal`, `stringVal`, `boolValue`, `numberValue` delegate to `DataCaster`.
- **ClipboardService** rebuilt — interface cleaned of media methods, `DefaultClipboardService` recreated using only bridge-supported operations (`getClipboardHtml`, `getClipboardText`, `getClipboardMarkdown` + copy variants).
- **ClipboardServiceProvider** recreated as singleton for the cleaned `ClipboardService`.

### Changed

- **Attribute → FormatAttribute** — Replaced 22+ `Attribute<T>` subclasses with a single `FormatAttribute` class using `FormatValueType` enum and named constructor (`key`, `scope`, `value`, `valueType`).
- **AttributeScope → FormatScope** — Renamed enum. `ignore` scope renamed to `metadata`.
- **BlockEmbed** — Removed `imageType` and `videoType` statics. Kept `formulaType` and `customType` as static factories.
- **EditableTextLine constructor** — Migrated from 14 positional arguments to named parameters.
- **text_line.dart** — All `.value` (Object?) direct accesses migrated to `.stringValue` via typed accessors. `CustomBlockEmbed.fromJsonString` calls now null-guarded with `.stringVal`.
- **color_button.dart / color_dialog.dart** — `.value` migrated to `.stringValue` for `stringToColor()` / `hexToColor()` calls.
- **raw_editor_state.dart** — `_linkActionPicker` converted from synchronous `LinkMenuAction?` to `Future<LinkMenuAction>` with `LinkMenuAction.none` fallback, matching the `LinkActionPicker` typedef.
- **raw_editor_state.dart** — Added missing `offset` parameter to `QuillRawEditorMultiChildRenderObject` in the non-scrollable code path.
- **proxy.dart** — `RenderBaselineProxy` construction fixed from 3 positional args to 2 + setter for `padding`.
- **debugCheckHasMediaQuery** — Replaced `assert()` with defensive guard (`if (!debugCheckHasMediaQuery(context))` + `debugPrint` + `SizedBox.shrink()`). No asserts in production code paths.
- **Linter** — `very_good_analysis` strict mode (`strict-casts`, `strict-inference`, `strict-raw-types`) enabled. Zero analyzer errors.

### Removed

- **Media embed blocks** — Image, video, gif, and camera embed blocks removed from the editor and extensions. Only `formula` and `custom` embed types remain.
- **ClipboardService media methods** — `getImageFile()`, `getGifFile()`, `copyImage()`, `getHtmlFile()`, `getMarkdownFile()` removed from the interface. Replaced with bridge-supported text/HTML/Markdown methods.
- **DefaultClipboardService media methods** — All image/gif/file clipboard operations removed. Only text-based clipboard operations remain.
- **HTML/Markdown converters** — Delta-to-HTML and Markdown-to-Delta converters removed from the fork. Ported to the `quill_native_bridge` package.
- **`getFontSize()`** — Removed from `text_line.dart`. Replaced with `getFontSizeAsDouble()` from `font.dart`.
- **`linkPrefixes`** — Already-`@Deprecated` and `@internal` constant removed from the public API surface. Use `LinkValidator.linkPrefixes` instead.

### Fixed

- **Embeddable.numberValue** — Was checking `data is bool` instead of `data is num`, causing all numeric embeds to return `null`. Fixed via `DataCaster.toDouble`.
- **debugCheckHasMediaQuery inverted logic** — `if (debugCheckHasMediaQuery(context))` returned `SizedBox.shrink()` on every build (function always returns `true`). Fixed to use `if (!debugCheckHasMediaQuery(context))` defensive guard.
- **text_line.dart nullable access** — `horizontalSpacing.left` / `verticalSpacing.top` accessed unconditionally on nullable types. Fixed with `?.` + `?? 0.0` fallbacks.

### Tests

- 121 tests passing, 0 failures.
- Fixed 4 tests: `controller_test.dart` (`null` → `isEmpty`), `attributes_test.dart` (added `metadataKeys` removal), `document_search_test.dart` (`.data` → `.data.toString()`), `line_test.dart` (`FormatAttribute.ol` object → `"ordered"` string in Delta JSON).

## [11.5.1] - 2026-05-20

### Added

- Added localization support for `mn` (Mongolian, Mongolia)

### Changed

- Updated minimum supported SDK version to Flutter 3.44/Dart 3.12.
- Implemented the new [TextInputClient.onFocusReceived](https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/services/text_input.dart#L1395-L1401) method required by Flutter SDK 3.44+ (`returns false`).

## [11.5.0] - 2025-10-18

### Fixed

- Fixed `View.of(context)` calls throwing when used with the `screenshot` package [#2662](https://github.com/singerdmx/flutter-quill/pull/2662).

### Added

- Add missing Brazilian Portuguese translations

## [11.4.2] - 2025-07-22

### Fixed

- **App crash on desktop platforms** when using Flutter `3.32.0-0.5.pre` and newer.
  Fixed by passing the required `viewId` for experimental multi-window support [#2579](https://github.com/singerdmx/flutter-quill/pull/2579).

## [11.4.1] - 2025-05-15

### Added

- `copyWith` methods to `HorizontalSpacing`, `VerticalSpacing`, `DefaultTextBlockStyle`, and `DefaultListBlockStyle` for immutable updates of properties [#2550](https://github.com/singerdmx/flutter-quill/pull/2550).
- Finnish (fi) language translation [#2564](https://github.com/singerdmx/flutter-quill/pull/2564).

## [11.4.0] - 2025-04-23

### Added

- Accept `mailto`, `tel`, `sms`, and other link prefixes by default in the insert link toolbar button [#2525](https://github.com/singerdmx/flutter-quill/pull/2525).
- `validateLink` in `QuillToolbarLinkStyleButtonOptions` to allow overriding the link validation [#2525](https://github.com/singerdmx/flutter-quill/pull/2525).

### Fixed

- Improve doc comment of `customLinkPrefixes` in `QuillEditor` [#2525](https://github.com/singerdmx/flutter-quill/pull/2525).

### Changed

- Deprecate `linkRegExp` in favor of the new callback `validateLink` [#2525](https://github.com/singerdmx/flutter-quill/pull/2525).

## [11.3.0] - 2025-04-23

### Fixed

- Can't select text when `readOnly` is true [#2529](https://github.com/singerdmx/flutter-quill/pull/2529).

### Added

- Display magnifier using `RawMagnifier` widget when dragging on iOS/Android [#2529](https://github.com/singerdmx/flutter-quill/pull/2529).

## [11.2.0] - 2025-03-26

### Added

- Cache for `toPlainText` in `Document` class to avoid unnecessary text computing [#2482](https://github.com/singerdmx/flutter-quill/pull/2482).

## [11.1.2] - 2025-03-24

### Fixed

- **[iOS]** `QuillEditor` doesn't respect the system keyboard brightness by default [#2522](https://github.com/singerdmx/flutter-quill/pull/2522).
- Add a default empty list for `characterShortcutEvents` and `spaceShortcutEvents` in `QuillRawEditorConfig` [#2522](https://github.com/singerdmx/flutter-quill/pull/2522).
- Deprecate `QuillEditorState.configurations` in favor of `QuillEditorState.config` [#2522](https://github.com/singerdmx/flutter-quill/pull/2522).

## [11.1.1] - 2025-03-19

### Fixed

 - Explicitly schedule frame on secondary click to ensure context menu is shown on Windows [#2507](https://github.com/singerdmx/flutter-quill/pull/2507).

## [11.1.0] - 2025-03-11

### Fixed

- Remove unnecessary content change listeners in read-only mode to avoid triggering infinite loops of **FocusNode** callbacks [#2488](https://github.com/singerdmx/flutter-quill/pull/2488).
- Remove unicode from `QuillText` element that causes weird caret behavior on empty lines [#2453](https://github.com/singerdmx/flutter-quill/pull/2453).
- Focus and open context menu on right click if unfocused [#2477](https://github.com/singerdmx/flutter-quill/pull/2477).
- Update QuillController `length` extension method deprecation message [#2483](https://github.com/singerdmx/flutter-quill/pull/2483).

### Added

- `Rule` is now part of the public API, so that `Document.setCustomRules` can be used.
- `decoration` property in `DefaultTextBlockStyle` for the `header` attribute to customize headers with borders, background colors, and other styles using `BoxDecoration` [#2429](https://github.com/singerdmx/flutter-quill/pull/2429).

## [11.0.0] - 2025-02-16

> [!IMPORTANT]
> See the [migration guide from 10.0.0 to 11.0.0](https://github.com/singerdmx/flutter-quill/blob/master/doc/migration/10_to_11.md) for the full breaking changes and migration.

### Fixed

- **[iOS]** Localize the Cupertino link menu actions.
- Export `QuillToolbarSelectLineHeightStyleDropdownButtonOptions`, fixing [#2333](https://github.com/singerdmx/flutter-quill/issues/2333).
- Clipboard images pasting as plain text on **Android** [#2384](https://github.com/singerdmx/flutter-quill/pull/2384).
- Avoid using [`url_launcher_string.dart`](https://pub.dev/documentation/url_launcher/latest/url_launcher_string/url_launcher_string-library.html) which is [**strongly discouraged**](https://pub.dev/packages/url_launcher#urls-not-handled-by-uri) [#2403](https://github.com/singerdmx/flutter-quill/pull/2403).
- The color picker dialog's hex field does not use the correct value of the selected text in the editor [#2415](https://github.com/singerdmx/flutter-quill/pull/2415).

### Added

- `QuillClipboardConfig` class with customizable clipboard paste handling callbacks, partial fix to [#2350](https://github.com/singerdmx/flutter-quill/issues/2350).
- The option to enable/disable rich text paste (from other apps) in `QuillClipboardConfig`.
- `onKeyPressed` in `QuillEditorConfig` to customize key press handling in the editor [#2368](https://github.com/singerdmx/flutter-quill/pull/2368).
- Croatian (hr) language translation [#2431](https://github.com/singerdmx/flutter-quill/pull/2431).
- `enableClipboardPaste` flag in `QuillToolbarClipboardButton` [#2427](https://github.com/singerdmx/flutter-quill/pull/2427).

### Changed

- Migrate [quill_native_bridge](https://pub.dev/packages/quill_native_bridge) to `11.0.0` [#2403](https://github.com/singerdmx/flutter-quill/pull/2403).
- Avoid using deprecated APIs in Flutter 3.27.0 [#2416](https://github.com/singerdmx/flutter-quill/pull/2416).
- **BREAKING**: Update configuration class names to use the suffix `Config` instead of `Configurations`.
- **BREAKING**: Refactor **embed block interface** for both the `EmbedBuilder.build()` and `EmbedButtonBuilder`.
- **BREAKING**: Clipboard action buttons in `QuillSimpleToolbar` are now disabled by default.
- **BREAKING**: Replace `QuillClipboardConfig.onDeltaPaste` with `QuillClipboardConfig.onRichTextPaste`.

### Removed

- **BREAKING**: The quill shared configuration class.
- The dependency [equatable](https://pub.dev/packages/equatable).
- The experimental support for spell checking. See [#2246](https://github.com/singerdmx/flutter-quill/issues/2246).
- **BREAKING**: The magnifier feature due to buggy behavior [#2413](https://github.com/singerdmx/flutter-quill/pull/2413).

## [10.8.5] - 2024-10-24

### Fixed

- Allow all correct URLs to be formatted [#2328](https://github.com/singerdmx/flutter-quill/pull/2328).
- **[macOS]** Implement actions for `ExpandSelectionToDocumentBoundaryIntent` and `ExpandSelectionToLineBreakIntent` to use keyboard shortcuts [#2279](https://github.com/singerdmx/flutter-quill/pull/2279).

## [9.4.0] - 2024-06-13

### Added

- Korean translations [#1911](https://github.com/singerdmx/flutter-quill/pull/1911).

### Changed

- Rework search bar/dialog for **Material 3** UI with on-the-fly search [#1904](https://github.com/singerdmx/flutter-quill/pull/1904).
- Support for subscript and superscript across all languages.
- Improve pasting of Markdown and HTML file content from the system clipboard [#1915](https://github.com/singerdmx/flutter-quill/pull/1915).

### Removed

- Apple-specific font dependency for subscript and superscript functionality from the example.
- **BREAKING**: The [`super_clipboard`](https://pub.dev/packages/super_clipboard) plugin. To restore legacy behavior, use [`flutter_quill_extensions`](https://pub.dev/packages/flutter_quill_extensions) package and `FlutterQuillExtensions.useSuperClipboardPlugin()`.

[unreleased]: https://github.com/Sebastien-VZN/flutter_quill_robust/compare/master
[11.5.1]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.5.1
[11.5.0]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.5.0
[11.4.2]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.4.2
[11.4.1]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.4.1
[11.4.0]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.4.0
[11.3.0]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.3.0
[11.2.0]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.2.0
[11.1.2]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.1.2
[11.1.1]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.1.1
[11.1.0]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.1.0
[11.0.0]: https://github.com/singerdmx/flutter-quill/compare/v10.0.0...v11.0.0
[10.8.5]: https://github.com/singerdmx/flutter-quill/compare/v9.4.0...v10.8.5
[9.4.0]: https://github.com/singerdmx/flutter-quill/releases/tag/v9.4.0