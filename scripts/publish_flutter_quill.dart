import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'pubspec_version_check.dart';
import 'update_changelog_version.dart';
import 'update_pubspec_version.dart';

// NOTE: This script is for the maintainers.

const _usage = 'Usage: ./publish_flutter_quill.dart <new-version>';

// The flutter_quill pubspec.yaml
const _targetPubspecYaml = './pubspec.yaml';

// The flutter_quill CHANGELOG
const _targetChangelog = './CHANGELOG.md';

const _exampleDirectory = './example';

const _targetExamplePubspecLock = '$_exampleDirectory/pubspec.lock';

const _confirmPublishOptionName = 'Y';

const _mainGitRemote = 'origin';

const _githubRepoActionsLink = 'https://github.com/singerdmx/flutter-quill/actions';

const _packageName = 'flutter_quill';

const _changelogAndPubspecRestoreMessage =
    'ℹ️  Changes to CHANGELOG.md and pubspec.yaml have not been reverted.\n'
    'To revert them, run:\n'
    'git restore --staged $_targetChangelog $_targetPubspecYaml $_targetExamplePubspecLock\n'
    'git restore $_targetChangelog $_targetPubspecYaml $_targetExamplePubspecLock';

Future<void> main(List<String> args) async {
  debugPrint('➡️ Arguments provided: $args');

  if (args.isEmpty) {
    debugPrint('❌ Missing required arguments. $_usage');
    exit(1);
  }
  if (args.length > 2) {
    debugPrint('❌ Too many arguments. $_usage');
    exit(1);
  }
  final version = args[0];
  if (version.isEmpty) {
    debugPrint('❌ The version is empty. $_usage');
    exit(1);
  }
  if (version.startsWith('v')) {
    debugPrint(
      '❌ Version ($version) should not start with `v`, as the script will add it to the tag.',
    );
    exit(1);
  }
  final confirmPublish = args.elementAtOrNull(1) == '-$_confirmPublishOptionName';
  if (!_isValidVersion(version)) {
    debugPrint('❌ Invalid version format ($version).');
    exit(1);
  }
  if (!_isGitClean()) {
    debugPrint(
      '❌ Git working directory is not clean. Commit all changes and try again.',
    );
    exit(1);
  }

  debugPrint(
    'ℹ️ Checking if the version `$version` is already published on pub.dev...',
  );
  if (await _isPackageVersionPublished(version)) {
    debugPrint(
      '❌ The version `$version` of the `$_packageName` package is already published on pub.dev.',
    );
    debugPrint(
      '📦 Check the package page on pub.dev: https://pub.dev/packages/$_packageName/versions',
    );
    debugPrint('⚠️ Choose a different version and try again.');
    exit(1);
  }
  await updatePubspecVersion(
    newVersion: version,
    pubspecFilePath: _targetPubspecYaml,
  );
  checkPubspecVersion(
    expectedVersion: version,
    pubspecFilePath: _targetPubspecYaml,
  );
  updateChangelogVersion(
    newVersion: version,
    changelogFilePath: _targetChangelog,
  );

  try {
    // To update pubspec.lock of the example
    debugPrint(
      'ℹ️ Running `flutter pub get` in the example directory to update `pubspec.lock`...',
    );
    Process.runSync('flutter', ['pub', 'get', '-C', _exampleDirectory]);

    Process.runSync('git', [
      'add',
      _targetPubspecYaml,
      _targetChangelog,
      _targetExamplePubspecLock,
    ]);

    if (_isGitClean()) {
      debugPrint(
        '❌ No changes detected after updating $_targetChangelog and $_targetPubspecYaml.\n'
        'Review the script for potential issues.',
      );
      exit(1);
    }

    debugPrint('✅ CHANGELOG and pubspec.yaml files have been updated.');
    if (!confirmPublish) {
      debugPrint(
        'ℹ️ To confirm publishing, type `$_confirmPublishOptionName` and press Enter.\n'
        'Tip: Add `-$_confirmPublishOptionName` as an argument to skip this prompt in the future.',
      );
      final confirm = stdin.readLineSync();
      if (confirm != _confirmPublishOptionName) {
        debugPrint(
          '❌ The publishing process has been aborted.\n'
          '$_changelogAndPubspecRestoreMessage',
        );
        exit(1);
      }
    }

    final tagName = 'v$version';

    debugPrint('ℹ️ Committing changes...');
    Process.runSync('git', [
      'commit',
      '-m',
      'chore(release): prepare to publish $version',
    ]);

    debugPrint('ℹ️ Creating git tag `$tagName`...');
    Process.runSync('git', ['tag', tagName]);

    debugPrint('ℹ️ Pushing commit to remote...');
    Process.runSync('git', ['push']);

    debugPrint('ℹ️ Pushing tag to remote...');
    Process.runSync('git', ['push', _mainGitRemote, tagName]);
    debugPrint(
      '✅ The tag $tagName has been pushed. The GitHub workflow will handle the rest.\n'
      'For more details, check: $_githubRepoActionsLink',
    );
  } catch (e) {
    debugPrint('❌ An error occurred during the publishing process: $e\n');
    debugPrint(_changelogAndPubspecRestoreMessage);
  }
}

// Same as https://dart.dev/tools/pub/automated-publishing#configuring-a-github-action-workflow-for-publishing-to-pub-dev
// but without the `v`.
bool _isValidVersion(String version) {
  final regex = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[0-9]+)?)?$');
  return regex.hasMatch(version);
}

bool _isGitClean() {
  final result = Process.runSync('git', ['status', '--porcelain']);
  // If the output is empty, the repository is clean
  return result.stdout.toString().trim().isEmpty;
}

/// Returns `true` if the specified [version] is already published on [pub.dev](https://pub.dev/).
Future<bool> _isPackageVersionPublished(String version) async {
  final url = 'https://pub.dev/api/packages/$_packageName/versions/$version';
  final response = await http.get(Uri.parse(url));
  switch (response.statusCode) {
    case 200:
      return true;
    case 404:
      return false;
    default:
      throw StateError(
        'Unexpected response status code: ${response.statusCode}\nResponse Body: ${response.body}',
      );
  }
}
