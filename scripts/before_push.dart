import 'dart:io';

import 'package:flutter/foundation.dart';

import '_lib/format_files.dart';

void main() async {
  await runCommand('flutter', ['analyze']);

  await runCommand('flutter', ['test']);

  await runCommand('flutter', ['pub', 'publish', '--dry-run']);

  await runCommand('dart', ['fix', '--apply']);

  // Format the repository, then assert it is fully formatted (mirrors the CI
  // `format_check.dart` check). Skips generated localizations whose formatting
  // differs across the Windows and Linux Flutter toolchains — see
  // `scripts/_lib/format_files.dart` for the shared exclusion list. Files are
  // passed in chunks to stay under the Windows command-line length limit.
  final files = collectFormatableDartFiles();
  if (files.isEmpty) {
    stderr.writeln('No Dart files found to format.');
    exit(1);
  }
  for (final batch in chunkFormatBatches(files)) {
    await runCommand('dart', ['format', '-l', '150', ...batch]);
  }
  for (final batch in chunkFormatBatches(files)) {
    await runCommand('dart', ['format', '-l', '150', '--set-exit-if-changed', ...batch]);
  }

  await runCommand('flutter', [
    'build',
    'web',
    '--release',
    '--dart-define=CI=true',
  ], workingDirectory: 'example');

  debugPrint('');

  await runCommand('dart', ['./scripts/translations_check.dart']);

  debugPrint('');

  debugPrint('Checks completed.');
}

Future<void> runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  debugPrint(
    "Running '$executable ${arguments.join(' ')}' in directory '${workingDirectory ?? 'root'}'...",
  );
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  debugPrint(result.stdout.toString());
  debugPrint(result.stderr.toString());
}
