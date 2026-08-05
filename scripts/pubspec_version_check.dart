import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';

/// Validate a version to match with the version in pubspec.yaml file
void checkPubspecVersion({
  required String expectedVersion,
  required String pubspecFilePath,
}) {
  if (expectedVersion.isEmpty) {
    debugPrint('The version is empty.');
    exit(1);
  }

  if (pubspecFilePath.isEmpty) {
    debugPrint('The pubspec file path is empty.');
    exit(1);
  }
  final pubspecFile = File(pubspecFilePath);
  if (!pubspecFile.existsSync()) {
    debugPrint('The pubspec file does not exist: ${pubspecFile.absolute.path}');
    exit(1);
  }
  final pubspecYaml = loadYaml(pubspecFile.readAsStringSync());
  final pubspecVersion = pubspecYaml['version'];
  if (expectedVersion != pubspecVersion) {
    debugPrint(
      'The version ($expectedVersion) does not match the version in pubspec.yaml ($pubspecVersion).\n'
      'The pubspec.yaml file is located at: ${pubspecFile.absolute.path}',
    );
    exit(1);
  }
  debugPrint(
    'The version ($expectedVersion) match the version in pubspec.yaml',
  );
}
