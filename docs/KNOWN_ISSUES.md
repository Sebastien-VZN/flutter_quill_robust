# KNOWN ISSUES — flutter_quill_robust

Liste des problèmes identifiés et corrigés dans le fork. Chaque bug est verrouillé par des tests automatisés dans `test/`.

---

## 1. FormatException: Apply delta rules failed (RuleType.format)

**Symptôme :** Exception levée quand on applique un attribut inline (bold, italic, size, color, etc.) avec une sélection vide (`len == 0`).

**Endroit :** `lib/src/rules/rule.dart` — `_rules.apply()` throw quand aucune règle ne matche.

**Root cause :** Dans `lib/src/controller/quill_controller.dart`, `formatText(index, len, attribute)` :
- Si `len == 0` et attribut ≠ `link`, on ajoute l'attribut à `toggledStyle` (correct).
- **MAIS** on appelle quand même `document.format(index, 0, attribute)`.
- Les règles de format (`ResolveInlineFormatRule`, `ResolveLineFormatRule`, etc.) ne gèrent pas le cas `len == 0` pour les attributs inline.
- Donc aucune règle ne retourne de delta → throw.

**Fix :** Retourner un delta vide au lieu de throw quand aucune règle ne matche. C'est un no-op cohérent avec le comportement attendu (attribut mis en cache pour la prochaine insertion).

**Test :** `test/controller/format_exception_regression_test.dart`

---

## 2. Listes (bullet, number, checkbox) invisibles sans taille fixée

**Symptôme :** Les éléments de leading des listes (bullet point, numéro, checkbox) n'apparaissent pas si la taille du texte n'est pas explicitement fixée. Si la taille est fixée, le leading peut déborder ou mal s'aligner.

**Endroit :** `lib/src/editor/widgets/text/text_block.dart` — `_buildLeading()`

**Root cause :**
1. Ligne ex-249 : `if (opSize == null) return null;` — on ne construisait le leading **que si** l'attribut `size` était présent sur la ligne. Sans taille fixée → leading invisible.
2. La largeur du leading utilisait `fontSize` du **paragraph par défaut**, pas la taille réelle fixée sur la ligne → décalage indentation/leading quand taille fixée.
3. Les attributs de bloc ne sont pas toujours dans `line.style.attributes` (vide pour une Line inline) — ils sont dans les ops du delta. `_buildLeading` lisait uniquement `nodeAttrs` → `attribute == null` → return null.

**Note importante sur la structure des listes :** Dans Quill, l'attribut de bloc est **canonique** quand il est porté par l'op newline (`insert '\n' avec {list: ...}`), ce qui produit un node `Block` dans l'arbre. Mettre l'attribut sur l'op texte produit une `Line` inline (non canonique) qui ne passe PAS par `EditableTextBlock` et n'a donc jamais de leading. Le toolbar (`formatSelection`) produit toujours la forme canonique.

**Fix appliqué (`_buildLeading`) :**
1. Ne plus exiger `opSize` : `sizeStyle = opSize == null ? fontSize : résolu`.
2. Utiliser `sizeStyle` (taille réelle) pour `width`, `padding`, `lineSize` au lieu du `fontSize` par défaut.
3. Fusionner les attributs depuis le node style ET via `Style.fromJson(attributeOp).attributes` pour détecter l'attribut de bloc où qu'il soit.

**Test :** `test/editor/list_leading_rendering_test.dart` (6 tests — forme canonique vérifiée par diagnostic préalable)

---

## 3. Insert URL bloqué à la saisie

**Symptôme :** Après avoir inséré un lien via le dialog, taper du texte l'insère au **mauvais endroit** (début au lieu de la fin du lien), donnant l'impression que le formulaire / l'éditeur est "bloqué à la saisie".

**Endroit :** `lib/src/editor/widgets/link.dart` — `QuillTextLink.submit()`

**Root cause :** `submit` appelait `replaceText(index, length, text, null)` avec une sélection `null`. Le caret restait à sa position d'origine (offset 0 ou ancienne sélection) au lieu de se placer à la fin du texte inséré. La frappe suivante se diffiait contre une valeur IME obsolète et atterrissait au mauvais offset — reproduit en test : taper 'X' après submit produisait `'XExample\n'` au lieu de `'ExampleX\n'`.

Subtilité : `replaceText` applique un `getPositionDelta` quand `len > 0` (remplacement de sélection), ce qui décale le caret fourni. Le fix épingler la sélection finale après toute l'opération.

**Fix appliqué :**
1. Passer une sélection explicite à `replaceText` : `TextSelection.collapsed(offset: index + text.length)`.
2. Après `formatText`, ré-épingler la sélection si `getPositionDelta` l'a décalée (cas du remplacement d'une sélection existante).

**Test :** `test/toolbar/link_dialog_submit_regression_test.dart` (3 tests — caret + attribut link + éditabilité immédiate)

---

## 4. Focus perdu lors de la saisie (Windows desktop)

**Symptôme :** Après la première frappe, le focus est perdu et la connexion IME se ferme.

**Endroit :** `lib/src/editor/raw_editor/raw_editor_state.dart` — `_handleFocusChanged`

**Fix :** Déjà corrigé dans la session précédente (refactor `_afterFocusChanged` + `didChangeAppLifecycleState` + `[FOCUS-REACQUIRE]`).

**Test :** `test/editor/raw_editor_keyboard_focus_test.dart` + `test/editor/keyboard_ime_pipeline_test.dart`

---

## Historique des tests de surveillance

| Fichier | Couverture |
|---|---|
| `test/editor/keyboard_ime_pipeline_test.dart` | Pipeline IME → document → rendu (12 tests) |
| `test/editor/raw_editor_keyboard_focus_test.dart` | Focus retained après frappe |
| `test/controller/format_exception_regression_test.dart` | FormatException RuleType.format (6 tests) |
| `test/editor/list_leading_rendering_test.dart` | Rendu des leading de listes (6 tests) |
| `test/toolbar/link_dialog_submit_regression_test.dart` | Caret correct après insert URL (3 tests) |

---

## Bugs résolus cette session

- ✅ #1 FormatException — **était déjà interceptée** (try/catch en place), verrouillée par test de non-régression
- ✅ #2 Listes invisibles — **corrigé** dans `text_block.dart::_buildLeading`
- ✅ #3 Insert URL bloqué — **corrigé** dans `link.dart::QuillTextLink.submit`
- ✅ #4 Focus Windows — **corrigé** session précédente

*Dernière mise à jour : session de relecture kimi-k3 — 3 bugs résolus, tests de surveillance ajoutés.*
