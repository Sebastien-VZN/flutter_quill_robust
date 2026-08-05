# Contributing

First, we would like to thank you for your time and efforts on this project, we appreciate it.

> [!IMPORTANT]
> The linter (`very_good_analysis` strict mode with `strict-casts`, `strict-inference`, `strict-raw-types`) is the **source of truth**. Never weaken lint rules to silence warnings — fix the code instead. `// ignore:` comments are prohibited without exceptional justification.
>
> No `assert()` calls in production code paths. Use defensive guards with `debugPrint` for debug-time diagnostics instead.

> [!NOTE]
> The package version in `pubspec.yaml` **should not be modified**; this will be handled by a maintainer or CI.
> Add updates to `Unreleased` in `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Development Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (minimum 3.44 / Dart 3.12)
- [IntelliJ IDEA Community Edition](https://www.jetbrains.com/idea/download/)
  or [Android Studio](https://developer.android.com/studio) (with Dart and Flutter plugins) or
  use [VS Code](https://code.visualstudio.com/) (with Dart and flutter extensions)

## Linting and Formatting

This project uses [very_good_analysis](https://pub.dev/packages/very_good_analysis) in strict mode:

- **strict-casts** — no implicit casts from `dynamic` or `Object?`
- **strict-inference** — all types must be explicitly inferred
- **strict-raw-types** — no raw generic types (e.g., `List` must be `List<SomeType>`)

```bash
# Analyze (must pass with zero errors)
flutter analyze --no-fatal-infos --no-fatal-warnings lib/

# Format check
dart format -l 150 --set-exit-if-changed .

# Format fix
dart format -l 150 .
```

### Key Conventions

- **Line length**: 150 characters (not 80)
- **Double quotes** preferred (`prefer_single_quotes: false`)
- **Package imports** required: `package:flutter_quill/...` (no relative paths)
- **No `print()`**: use `debugPrint` instead
- **No `assert()` in production code**: use defensive guards with `debugPrint`
- **Constructors first** in class body (`sort_constructors_first: true`)
- **`unawaited_futures`**: every `Future` must be `await`ed or wrapped with `unawaited()`
- **`avoid_void_async`**: async functions return `Future<void>`, not `void`

### Type Safety with DataCaster

All `Object?` → typed conversions go through `DataCaster` (`lib/src/document/data_caster.dart`):

```dart
// CORRECT — DataCaster with context logging
final fontSize = DataCaster.toDouble(value, context: "FormatAttribute.numberValue[font]");

// WRONG — direct cast
final fontSize = value as double?;
```

Never use `as` casts for `FormatAttribute.value` or `Embeddable.data` — use the typed accessors (`intValue`, `stringValue`, `boolValue`, `numberValue`).

## Testing

```bash
# All tests
flutter test test/

# Specific areas
flutter test test/document/
flutter test test/rules/
flutter test test/controller/
```

All 121 tests must pass. If you add a new feature, write tests for it.

## Code Review Guidelines

1. **Type safety** — no `dynamic`, no unchecked `as` casts, no raw generic types
2. **DataCaster** — all type conversions go through `DataCaster` with context
3. **No media** — this fork does not support image/video/gif embeds. Do not add media-related code
4. **Defensive guards** — use `debugPrint` + early return instead of `assert()` for runtime checks
5. **Consistency** — match existing naming conventions and code style