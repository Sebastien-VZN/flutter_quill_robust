# RAPPORT — Cartographie et Plan de Refonte flutter_quill_robust

Date : 04 août 2026 (v4 — toutes les erreurs lib/ résolues, 121 tests verts)
Auteur : Atlas (IA Orchestrateur)
Projet : flutter_quill_robust (fork Sebastien-VZN/flutter_quill_robust)
Version : 11.5.2-robust.1
Linter : very_good_analysis ^10.2.0 (strict-casts, strict-inference, strict-raw-types ACTIFS — source de vérité, NE PAS MODIFIER)

---

## 1. ÉTAT DES LIEUX

### 1.1 Git

- Branche : master
- Working tree : modifications non-commitées (data_caster.dart + embeddable.dart + format_attribute.dart + corrections lib/ + corrections test/)
- Derniers commits :
  - 926e8376 — rebuild (nettoyage editor.dart, raw_editor_state.dart, text_line.dart, suppression default_clipboard_service.dart)
  - 896820ab — format files (75 fichiers, Phase B/C en cours — DataCaster, accesseurs typés, migration .value)
  - 7d4af711 — fix leading
  - 929580ae — fix controler and docuement
  - 074f19fd — update fix

### 1.2 Analyse Linter (flutter analyze lib/ test/)

| Sévérité | v2 (avant) | v3 (intermédiaire) | v4 (actuel) | Variation totale |
|---|---|---|---|---|
| ERROR | 148 | 46 | 0 | -148 (-100%) |
| WARNING | 59 | 41 | ~41 | -18 (-31%) |
| INFO | 275 | 188 | ~191 | -84 (-31%) |
| TOTAL | 482 | 275 | 232 | -250 (-52%) |

**0 ERREURS.** Le code compile. Les 232 issues restantes sont des warnings (strict_raw_type, parameter_assignments) et des infos (prefer_asserts_with_message, etc.) — non bloquants.

### 1.3 Tests (flutter test test/)

| Métrique | v3 | v4 |
|---|---|---|
| Tests passants | 114 | 121 |
| Tests échouant | 4 | 0 |
| Total | 118 | 121 |

**121 tests, 0 échec.**

---

## 2. CORRECTIONS RÉALISÉES (v3 → v4)

### 2.1 ClipboardServiceProvider (7 erreurs → 0)

**Fichiers modifiés :** clipboard_service.dart, default_clipboard_service.dart (recréé), clipboard_service_provider.dart (recréé), quill_controller_rich_paste.dart, internal.dart

L'interface `ClipboardService` a été nettoyée des méthodes média supprimées du bridge :
- Supprimé : `getImageFile()`, `getGifFile()`, `copyImage()`, `getHtmlFile()`, `getMarkdownFile()`
- Ajouté : `getHtmlText()`, `copyHtmlToClipboard()`, `getClipboardText()`, `copyTextToClipboard()`, `getMarkdownText()`, `copyMarkdownToClipboard()`

`DefaultClipboardService` recréé avec uniquement les méthodes supportées par le bridge natif (getClipboardHtml, getClipboardText, getClipboardMarkdown + leurs variants copy). `ClipboardServiceProvider` recréé comme singleton. `quill_controller_rich_paste.dart` migré de `getMarkdownFile()` → `getMarkdownText()`.

### 2.2 getFontSize (1 erreur → 0)

**Fichier :** text_line.dart

`getFontSize(size.value)` → `getFontSizeAsDouble(size.stringValue, defaultStyles: defaultStyles)`. Import `font.dart` ajouté dans text_line.dart. Pattern aligné sur text_block.dart:252 qui utilisait déjà `getFontSizeAsDouble`.

### 2.3 raw_editor_state.dart offset (1 erreur → 0)

**Fichier :** raw_editor_state.dart:425

`QuillRawEditorMultiChildRenderObject` manquait le paramètre `offset` dans le bloc non-scrollable. Ajouté `offset: _scrollController.hasClients ? _scrollController.position : null` (même pattern que le bloc scrollable ligne 396).

### 2.4 proxy.dart (1 erreur → 0)

**Fichier :** proxy.dart:14

`RenderBaselineProxy(null, textStyle!, padding)` (3 args positionnels) → `RenderBaselineProxy(null, textStyle!)..padding = padding ?? EdgeInsets.zero` (2 args + setter).

### 2.5 text_line.dart .value → .stringValue (11 erreurs → 0)

**Fichier :** text_line.dart — lignes 144, 200, 538, 569, 589, 599, 649, 676, 678

Toutes les lectures `.value` (Object?) remplacées par `.stringValue` via les accesseurs typés de FormatAttribute. `CustomBlockEmbed.fromJsonString` guardé avec null-check + `.stringVal` au lieu de passer `embed.value.data` (Object) directement.

### 2.6 color_button/dialog (4 erreurs → 0)

**Fichiers :** color_button.dart:131,136, color_dialog.dart:42,43

`.value` (Object?) → `.stringValue` sur `attributes['color']` et `attributes['background']` passés à `stringToColor()` / `hexToColor()`.

### 2.7 text_line.dart nullable (4 erreurs → 0)

**Fichier :** text_line.dart:786-789

`horizontalSpacing.left` → `horizontalSpacing?.left ?? 0.0` (les 4 propriétés left/right/top/bottom). Les champs `horizontalSpacing` et `verticalSpacing` sont devenus nullables (`HorizontalSpacing?` / `VerticalSpacing?`).

### 2.8 LinkActionPicker (3 erreurs → 0)

**Fichier :** raw_editor_state.dart:1123-1127

`_linkActionPicker` converti de `LinkMenuAction? Function(Node)` synchrone → `Future<LinkMenuAction> Function(Node)` async avec fallback `LinkMenuAction.none` quand l'attribut link est absent ou null. Compatible avec le typedef `LinkActionPicker = Future<LinkMenuAction> Function(Node)`.

### 2.9 text_block.dart constructeur (14 erreurs → 0)

**Fichier :** text_block.dart:183-213

Constructeur `EditableTextLine` migré de 14 args positionnels → named params (`line:`, `leading:`, `body:`, `horizontalSpacing:`, `verticalSpacing:`, `textDirection:`, `textSelection:`, `color:`, `enableInteractiveSelection:`, `hasFocus:`, `devicePixelRatio:`, `cursorCont:`, `inlineCodeStyle:`, `decoration:`).

### 2.10 debugCheckHasMediaQuery (2 sites → 0)

**Fichiers :** raw_editor_state.dart:326, text_line.dart:137

`assert(debugCheckHasMediaQuery(context))` remplacé par guard défensif `if (!debugCheckHasMediaQuery(context))` + `debugPrint` + `return SizedBox.shrink()`. Conformément à la directive de Seb : pas d'assert en prod, utiliser debugPrint pour tracer les problèmes en debug.

---

## 3. CORRECTIONS TESTS (4 tests → 0)

### 3.1 document_search_test.dart

`node.value.data` (Object) → `.toString()` (3 sites). Compilation restaurée.

### 3.2 controller_test.dart

`expect(controller.getSelectionStyle().values, null)` → `expect(controller.getSelectionStyle().values, isEmpty)` (2 sites). `getSelectionStyle()` retourne un `Style` vide (dont `.values` est `[]`), pas `null`.

### 3.3 attributes_test.dart

Test "collections of keys" : ajout du retrait des `metadataKeys` (`width`, `height`, `style`, `token`) après le retrait des `inlineKeys` et `blockKeys`. Le test attendait un set vide mais ne retirait pas les clés metadata.

### 3.4 line_test.dart

Test "Block" : `'list': FormatAttribute.ol` (objet FormatAttribute) → `'list': 'ordered'` (String). Le delta JSON attend des valeurs primitives, pas des objets Dart. 3 sites corrigés.

---

## 4. ANALYSE DES MODÈLES DATA — ÉTAT ACTUEL

### 4.1 FormatAttribute — Stabilisé

```dart
class FormatAttribute {
  const FormatAttribute({required this.key, required this.scope, required this.value, required this.valueType});
  final String key;
  final FormatScope scope;
  final Object? value;
  final FormatValueType valueType;

  // Accesseurs typés via DataCaster
  int? get intValue => ... DataCaster.toInt(value, context: "FormatAttribute.intValue[$key]");
  String? get stringValue => ... DataCaster.toStr(value, context: "FormatAttribute.stringValue[$key]");
  bool? get boolValue => ... DataCaster.toBool(value, context: "FormatAttribute.boolValue[$key]");
  double? get numberValue => ... DataCaster.toDouble(value, context: "FormatAttribute.numberValue[$key]");
}
```

Architecture saine. DataCaster centralise les casts avec logging. Tous les sites d'appel dans lib/ utilisent maintenant les accesseurs typés.

### 4.2 Embeddable — Stabilisé

```dart
class Embeddable {
  final String type;
  final Object data;

  int? get intVal => DataCaster.toInt(data, context: "Embeddable.intVal[$type]");
  String? get stringVal => DataCaster.toStr(data, context: "Embeddable.stringVal[$type]");
  bool? get boolValue => DataCaster.toBool(data, context: "Embeddable.boolValue[$type]");
  double? get numberValue => DataCaster.toDouble(data, context: "Embeddable.numberValue[$type]");
}
```

Bug `numberValue` (qui vérifiait `data is bool` au lieu de `data is num`) CORRIGÉ via DataCaster.toDouble.

### 4.3 BlockEmbed — OK

Statics restaurés. `imageType`/`videoType` supprimés (médias retirés du fork). `formulaType` et `customType` conservés. Factorys `formula()` et `custom()` sont `static`.

### 4.4 ClipboardService — Nettoyé

Interface nettoyée des méthodes média. `DefaultClipboardService` recréé avec uniquement les méthodes supportées par le bridge natif (HTML, texte, Markdown). `ClipboardServiceProvider` recréé comme singleton.

### 4.5 OffsetValue<T> — Non résolu (24 warnings)

Le polymorphisme `OffsetValue<Style>` / `OffsetValue<Embeddable>` dans les mêmes listes reste. 24 warnings `strict_raw_type`.

### 4.6 MapEquality — À vérifier

L'usage dans `style.dart` et `line.dart` reste à vérifier.

---

## 5. PLAN DE TRAVAIL RESTANT

### Principe directeur
Le linter reste tel quel (strict-casts ACTIF). Les warnings et infos restants sont non-bloquants.

### PHASE D — COHÉRENCE LONG TERME (warnings + préventif)

#### Étape D1 — OffsetValue<dynamic> (24 warnings)

Typer les `List<OffsetValue>` en `List<OffsetValue<Object?>>` ou créer une union typée `sealed class StyledNode`.

#### Étape D2 — parameter_assignments (11 warnings)

Utiliser des variables locales au lieu de réassigner les paramètres.

#### Étape D3 — MapEquality (à vérifier)

Remplacer `MapEquality` dans `style.dart` et `line.dart` par comparaison manuelle.

#### Étape D4 — Renommer FormatAttribute.value en rawValue

Décourager l'accès direct. À faire SEULEMENT après que tous les `.value` sont migrés vers les accesseurs. Tous les sites lib/ sont migrés — reste à vérifier les tests et extensions.

#### Étape D5 — Pattern matching Dart 3 pour Operation.data

Remplacer `op.data as String` par `if (op.data case String s)`.

#### Étape D6 — Leaf._value typage

Ajouter `textValue` et `embedValue` getters sur Leaf.

#### Étape D7 — Retirer @experimental des membres stables

Dans QuillClipboardConfig et QuillControllerConfig, retirer `@experimental` des callbacks clipboard texte (onClipboardPaste, onRichTextPaste, onPlainTextPaste, enableExternalRichPaste).

---

## 6. RECOMMANDATIONS STRATÉGIQUES

### 6.1 Ordre d'exécution optimal

| Phase | Issues | Complexité | Priorité |
|---|---|---|---|
| D1. OffsetValue typing | 24 warnings | Élevée | PROGRESSIF |
| D2. parameter_assignments | 11 warnings | Mécanique | PROGRESSIF |
| D3. MapEquality | à vérifier | Réflexion | PROGRESSIF |
| D4. rawValue rename | Préventif | Élevée | PROGRESSIF |
| D5. Pattern matching | Préventif | Moyenne | PROGRESSIF |
| D6. Leaf._value typage | Préventif | Moyenne | PROGRESSIF |
| D7. @experimental | Préventif | Trivial | PROGRESSIF |

### 6.2 Tests

```bash
cd /mnt/webdev/client_project/flutter_quill_robust
export PATH="$PATH:/home/seb/flutter/bin"
flutter analyze --no-fatal-infos --no-fatal-warnings lib/ test/
dart format -l 150 --set-exit-if-changed .
flutter test test/
```

### 6.3 Ce qui est CORRECT et ne doit PAS être touché

- **FormatAttribute avec valueType + DataCaster** : Architecture saine. NE PAS revenir aux sous-classes.
- **DataCaster** : Centralisation des casts avec logging. NE PAS supprimer.
- **BlockEmbed statics** : Sémantique upstream correcte.
- **ClipboardService nettoyé** : Méthodes média supprimées, bridge natif respecté.
- **`! as` pattern** : Correct avec strict-casts.
- **FormatScope.metadata** (ex-ignore) : Bon renommage.
- **debugCheckHasMediaQuery en guard défensif** : Pas d'assert en prod, debugPrint pour tracer.
- **Le linter strict** : Source de vérité. NE PAS MODIFIER.

---

## 7. SKILLS

Les skills suivants documentent les points cruciaux du fork :

| Skill | Description | Statut |
|---|---|---|
| `quill_data_models` | FormatAttribute, OffsetValue, Style, MapEquality, DataCaster | À jour (DataCaster documenté) |
| `quill_block_embed` | BlockEmbed static vs instance, Embeddable, CustomBlockEmbed | À jour (accesseurs DataCaster documentés) |
| `quill_clipboard_config` | QuillClipboardConfig, ClipboardService, DefaultClipboardService | À mettre à jour (interface nettoyée, méthodes média supprimées) |
| `quill_operation_data` | Operation.data dynamic, casts `as` vs pattern matching Dart 3 | À jour |
| `quill_architecture` | Structure globale du fork, conventions, linter | À jour |

---

## 8. CONCLUSION

La refonte des erreurs est TERMINÉE :
- **0 erreurs** lib/ test/ (v4) — down from 148 (v2)
- **121 tests verts** — 0 échec
- **DataCaster** créé et intégré dans FormatAttribute + Embeddable
- **ClipboardService** nettoyé et reconstruit selon le bridge natif
- **debugCheckHasMediaQuery** converti en guard défensif avec debugPrint (pas d'assert en prod)
- **Tous les `.value` directs** dans lib/ migrés vers les accesseurs typés `.stringValue` / `.intValue` / `.numberValue`

Reste en Phase D (cohérence long terme) : 24 warnings strict_raw_type (OffsetValue), 11 warnings parameter_assignments, MapEquality à vérifier, et améliorations préventives (rawValue rename, pattern matching Dart 3, Leaf typage). Aucun de ces points n'est bloquant — le code compile et les tests passent.

---

## FEUILLE DE ROUTE — Cleanup Linter (août 2026)

### ÉTAT GLOBAL
- 134 tests verts (121 originaux + 13 guards leaf)
- 0 erreur, 0 warning sur les fichiers traités
- Skill : `quill_assert_to_debugprint` (pattern + liste fichiers complétés)

### CATÉGORIE 1 — prefer_asserts_with_message (110 asserts) ✅ TERMINÉ
24 fichiers traités, 110 asserts remplacés par `debugPrint + guard`.
Pattern : `if (!condition) { debugPrint(...); return safeValue; }`
AUCUN assert restant dans lib/. AUCUN `assert(cond, 'msg')` — tout remplacé par guards.
Fichier de test : `test/document/leaf_guards_test.dart` (13 tests).
Skill : `quill_assert_to_debugprint` dans `~/.hermes/skills/dev/`.

### CATÉGORIE 2 — strict_raw_type (~16) ⬜ À FAIRE
Warnings sur types génériques manquants (Map, List, Future sans paramètre de type).
Fichiers concernés : editor_keyboard_shortcut_actions.dart (1), raw_editor_state.dart (1), + ~14 autres.

### CATÉGORIE 3 — parameter_assignments (~4) ⬜ À FAIRE
Réassignation de paramètres dans le corps des méthodes.
Solution : variable locale `safeX` comme dans insert.dart (`safeIndex`, `safeData`).
Fichiers concernés : line.dart (déjà partiellement traité), raw_editor_state.dart (1 sur `newStyle`), + 2 autres.

### CATÉGORIE 4 — experimental_member_use (~4) ⬜ À FAIRE
Utilisation d'APIs expérimentales Flutter.

### CATÉGORIE 5-6 — inference_failure (~4) ⬜ À FAIRE
Types non inférés sur constructeurs et retours de fonctions.
Fichier concerné : raw_editor_state.dart (Future.delayed sans type).

### CATÉGORIE 7 — unused_local_variable (~1) ⬜ À FAIRE

### CATÉGORIE 8 — inference_failure_on_collection_literal (~4) ⬜ À FAIRE

### CATÉGORIE 9 — include_file_not_found (~1) ⬜ À FAIRE

### CATÉGORIE 10 — assorted infos (~63) ⬜ À FAIRE
prefer_const_constructors, discarded_futures, use_named_constants, avoid_setters_without_getters, etc.
Non bloquants mais à nettoyer pour la publication pub.dev.

### PRIORITÉ
1. Cat 2-3 (warnings) — bloquants pour `dart format --set-exit-if-changed` en CI
2. Cat 4-9 (warnings mineurs)
3. Cat 10 (infos) — cosmétique, non bloquant