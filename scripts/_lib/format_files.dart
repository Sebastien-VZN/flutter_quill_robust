import 'dart:io';

import 'package:path/path.dart' as p;

/// Collects every `.dart` file under the repository root that should be passed
/// to `dart format`. Generated localizations are intentionally skipped: they
/// are committed (so git consumers resolve `FlutterQuillLocalizations`), but
/// their formatting is produced by `flutter gen-l10n` and differs slightly
/// between the Windows and Linux Flutter toolchains, so re-running
/// `dart format` on them would create spurious cross-platform diffs.
///
/// Paths are returned **relative** to the repository root to keep command-line
/// invocations short enough for Windows' 8 191-char limit. Run from the
/// repository root, e.g. via `dart ./scripts/format_check.dart`.
List<String> collectFormatableDartFiles() {
  final root = Directory.current;
  final excludedDirs = <String>{
    p.join(root.path, 'lib', 'src', 'l10n', 'generated'),
    p.join(root.path, 'build'),
    p.join(root.path, '.dart_tool'),
    p.join(root.path, 'example', 'build'),
    p.join(root.path, 'example', '.dart_tool'),
    p.join(root.path, 'flutter_quill_extensions', 'build'),
    p.join(root.path, 'flutter_quill_extensions', '.dart_tool'),
  };

  final files = <String>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final dir = p.dirname(entity.path);
    if (excludedDirs.any(dir.startsWith)) continue;

    files.add(p.relative(entity.path, from: root.path));
  }
  return files;
}

/// Splits [files] into batches small enough that
/// `dart format$extraFlags <batch...>` stays under the OS command-line limit.
/// Windows caps a single command line at ~8 191 chars; chunking keeps each
/// invocation safe and lets `dart format` work cross-platform.
Iterable<List<String>> chunkFormatBatches(List<String> files, {int maxBatchChars = 4000}) sync* {
  var batch = <String>[];
  var batchLen = 0;
  for (final file in files) {
    // +1 for the separator space between args.
    final entryLen = file.length + 1;
    if (batch.isNotEmpty && batchLen + entryLen > maxBatchChars) {
      yield batch;
      batch = <String>[];
      batchLen = 0;
    }
    batch.add(file);
    batchLen += entryLen;
  }
  if (batch.isNotEmpty) yield batch;
}
