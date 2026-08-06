// This script has one task, which is to prevent the translations from
// being accidentally deleted, as we have more than 40 files for both the
// arb files (source) and the dart files (the generated)
// which make it harder to review the changes, some keys can be deleted
// without update the generated dart files which will cause a bug/build failure
// on the next time running the script after doing some changes to the translations
// which make it harder to revert the changes
// The script must run in the root project folder instead of the scripts folder

import 'dart:convert';
import 'dart:io' show File, exit;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

// This must be updated once add or remove some translation keys
// if you update existing keys, no need to update it
const _expectedTranslationKeysLength = 118;

Future<void> main(List<String> args) async {
  final l10nYamlText = await File('l10n.yaml').readAsString();
  if (l10nYamlText == '') return;

  final l10nYaml = loadYaml(l10nYamlText);
  final templateArbFileName = l10nYaml['template-arb-file'].toString();
  final arbDir = l10nYaml['arb-dir'].toString();
  if (arbDir == '' || templateArbFileName == '') return;

  final templateArbFile = File(path.join(arbDir, templateArbFileName));
  debugPrint('The file path to template arb file: ${templateArbFile.path}');
  final templateArb = jsonDecode(await templateArbFile.readAsString()) as Map<String, Object?>;
  debugPrint(
    'The length of the current translation keys: ${templateArb.keys.length}',
  );
  final newTranslationKeysLength = templateArb.keys.length;

  if (newTranslationKeysLength > _expectedTranslationKeysLength) {
    debugPrint(
      "You have add a new keys, please update the '_expectedTranslationKeysLength' value",
    );
    debugPrint('$newTranslationKeysLength > $_expectedTranslationKeysLength');
    exit(1);
  }
  if (newTranslationKeysLength < _expectedTranslationKeysLength) {
    debugPrint(
      "You have removed some keys, please update the '_expectedTranslationKeysLength' value",
    );
    debugPrint('$newTranslationKeysLength < $_expectedTranslationKeysLength');
    exit(1);
  }
  if (newTranslationKeysLength != _expectedTranslationKeysLength) {
    debugPrint(
      "It's looks like you have modified the keys length without updating the `_expectedTranslationKeysLength` value",
    );
    debugPrint('$newTranslationKeysLength != $_expectedTranslationKeysLength');
    exit(1);
  }
}
