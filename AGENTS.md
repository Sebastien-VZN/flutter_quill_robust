# AGENTS.md — flutter_quill_robust

Repo-specific survival guide for OpenCode sessions. If a fact is obvious from filenames or generic Flutter conventions, it is not here.

## What this repo is

A production-hardened fork of `flutter_quill`. It keeps **text-only rich editing** and removes all media embeds (image, video, gif, camera). The only embed blocks left are `formula` and `custom`. Public API lives in `lib/flutter_quill.dart`; extensions are in `flutter_quill_extensions/`.

## Monorepo layout

| Directory | What it owns |
|---|---|
| `lib/` | Main `flutter_quill` package. Public barrel: `lib/flutter_quill.dart`. |
| `flutter_quill_extensions/` | Extension package for custom embed builders only. No media. Depends on `flutter_quill` via path (`../`). |
| `example/` | Demo app used for CI platform builds. Build with `--dart-define=CI=true`. |
| `scripts/` | Root-only Dart scripts. Run as `dart ./scripts/<name>.dart`, **not** from inside `scripts/`. |

## Daily commands

| Goal | Command |
|---|---|
| Get dependencies for all packages | `flutter pub get` (root), `flutter pub get -C flutter_quill_extensions`, `flutter pub get -C example` |
| Regenerate localizations | `flutter gen-l10n` |
| Run tests | `flutter test` (root only; 121 tests) |
| Run a focused test group | `flutter test test/<path>.dart` |
| Analyze | `flutter analyze --no-fatal-infos .` |
| Format check (CI style) | `dart ./scripts/format_check.dart` |
| Format fix | `dart format -l 150 .` |
| Pre-push validation | `dart ./scripts/before_push.dart` |
| Translation key-count guard | `dart ./scripts/translations_check.dart` |
| Regenerate translations + fix + format | `dart ./scripts/regenerate_translations.dart` |
| Build example web (mirrors CI) | `flutter build web --release --dart-define=CI=true` in `example/` |

### Required order for local verification

1. `flutter gen-l10n`
2. `dart ./scripts/format_check.dart`
3. `flutter analyze --no-fatal-infos .`
4. `flutter test`

`scripts/before_push.dart` runs a superset of this plus a web build, dry-run publish, and translation check.

## Linter and style (source of truth: `analysis_options.yaml`)

- `very_good_analysis` strict mode: `strict-casts`, `strict-inference`, `strict-raw-types`.
- Line length is **150**, not 80.
- Double quotes are preferred (`prefer_single_quotes: false`).
- **Package imports only** (`always_use_package_imports: true`) — no relative imports across `lib/`.
- No `print()`; use `debugPrint`.
- Constructors must come first in class bodies.
- Every `Future` must be `await`ed or wrapped with `unawaited()`.
- Async functions return `Future<void>`, not `void`.
- Do not weaken lint rules to silence warnings. Fix the code instead.

## Type-safety rules specific to this fork

- `FormatAttribute` replaced the upstream 22 `Attribute<T>` subclasses. Use typed accessors: `intValue`, `stringValue`, `boolValue`, `numberValue`.
- `Embeddable` data uses typed accessors: `intVal`, `stringVal`, `boolValue`, `numberValue`.
- All `Object?` → typed conversions go through `DataCaster` (`lib/src/document/data_caster.dart`), with a `context:` string.
- Avoid `as` casts on attribute values or embed data.

## No-asserts, no-media conventions

- **No `assert()` in production code paths.** Use defensive guards plus `debugPrint`, then early-return a safe widget/value.
- **Do not add image, video, gif, or camera embed support.** Only `formula` and `custom` embed blocks are allowed.
- Clipboard code uses only text/HTML/Markdown via `quill_native_bridge`.

## Generated code

- `lib/src/l10n/generated/` is produced by `flutter gen-l10n` and **is tracked in git**. Without committing it, consumers that depend on this package via a git URL cannot resolve `FlutterQuillLocalizations` (Dart does not run `flutter gen-l10n` on fetched git deps), so every git consumer would see `Undefined name 'FlutterQuillLocalizations'`.
- The folder is excluded from `flutter analyze` (see `analysis_options.yaml`) and from `dart format` (see `scripts/_lib/format_files.dart`, shared by `scripts/format_check.dart` and `scripts/before_push.dart`) because `flutter gen-l10n` output formatting differs slightly between the Windows and Linux Flutter toolchains.
- Do not hand-edit committed files under `lib/src/l10n/generated/`. Regenerate via `flutter gen-l10n` (or `dart ./scripts/regenerate_translations.dart`), then commit the result.
- `scripts/regenerate_translations.dart` deletes the folder, regenerates, applies `dart fix`, then formats.
- `scripts/translations_check.dart` asserts the template ARB has exactly **117** keys. If you add or remove keys, update `_expectedTranslationKeysLength` in that script.

## Fork-specific dependency

`quill_native_bridge` is consumed from a git fork, not pub.dev:

```yaml
quill_native_bridge:
  git:
    url: https://github.com/Sebastien-VZN/quill_native_bridge_robust.git
    path: quill_native_bridge
```

Both packages use `publish_to: none` and are not published to pub.dev. Releases are GitHub releases built by CI.

## CI / release facts

- Workflow: `.github/workflows/build_check.yml`.
- CI pins Flutter **3.44.8** stable.
- Quality gate (format + analyze + tests) must pass before platform builds run.
- Platform builds happen on `ubuntu-latest`, `macos-latest`, and `windows-latest`, all with `--dart-define=CI=true`.
- Pushing to `master` auto-creates a GitHub release if the `pubspec.yaml` version has not been tagged yet.
- Do **not** bump `pubspec.yaml` versions yourself; maintainers/CI handle it. Add changelog entries under `## [Unreleased]` in `CHANGELOG.md`.

## Where to look next

- `CONTRIBUTING.md` — full style and review guidelines.
- `CHANGELOG.md` — recent refactoring context (Unreleased section is a good architecture summary).
- `README.md` — install, basic usage, and related forks.
- `flutter_quill_extensions/README.md` — extension package usage.
