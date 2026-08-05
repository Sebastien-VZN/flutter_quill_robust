import 'dart:io';

import 'package:path/path.dart' as p;

/// Runs `dart format -l 150 --set-exit-if-changed` on every `.dart` file
/// except generated localizations, whose formatting differs between
/// Windows and Linux Flutter toolchains.
void main() {
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

    files.add(entity.path);
  }

  if (files.isEmpty) {
    stderr.writeln('No Dart files found to format.');
    exit(1);
  }

  final result = Process.runSync('dart', ['format', '-l', '150', '--set-exit-if-changed', ...files], runInShell: true);

  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exit(result.exitCode);
}
