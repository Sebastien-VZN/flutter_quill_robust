import 'package:flutter/foundation.dart';

/// Gestionnaire global des logs de debug de flutter_quill.
///
/// Désactivé par défaut. Activé via [QuillEditorConfig.enableDebugLogs].
/// Tous les [debugPrint] de la lib doivent passer par [quillDebugPrint]
/// pour respecter ce flag.
class QuillDebugLogs {
  QuillDebugLogs._();

  /// Flag global activé/désactivé à l'init du [QuillEditor] via sa config.
  static bool enabled = false;
}

/// Wrapper de [debugPrint] respectant [QuillDebugLogs.enabled].
///
/// Remplace tout `debugPrint(...)` dans la lib par `quillDebugPrint(...)`.
/// Ne produit aucun log tant que [QuillDebugLogs.enabled] est `false` (défaut).
void quillDebugPrint(String? message) {
  if (QuillDebugLogs.enabled) {
    debugPrint(message);
  }
}
