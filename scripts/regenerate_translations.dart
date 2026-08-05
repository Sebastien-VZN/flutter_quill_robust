import 'dart:io' show Directory, Process;

import 'package:flutter/foundation.dart';

Future<void> main(List<String> args) async {
  final generatedDartLocalizationsFolder = Directory('lib/src/l10n/generated');
  if (generatedDartLocalizationsFolder.existsSync()) {
    debugPrint(
      'Generated directory (${generatedDartLocalizationsFolder.path}) exists, deleting it... 📁',
    );
    await generatedDartLocalizationsFolder.delete(recursive: true);
  }
  debugPrint('Running flutter pub get... 📦');
  await Process.run('flutter', ['pub', 'get']);

  debugPrint('Running flutter gen-l10n... 🌍');
  await Process.run('flutter', ['gen-l10n']);

  debugPrint('Applying Dart fixes to the newly generated files... 🔧');
  await Process.run('dart', ['fix', '--apply', './lib/src/l10n/generated']);

  debugPrint('Formatting the newly generated Dart files... ✨');
  await Process.run('dart', ['format', './lib/src/l10n/generated']);
}
