import "package:flutter/services.dart" show Clipboard;

/// Abstraction de Flutter [Clipboard] pour le texte riche (HTML, Markdown).
///
/// Les methodes media (image, gif, camera) ont ete supprimees du bridge natif
/// et ne sont plus supportees par ce fork.

abstract class ClipboardService {
  /// Retourne le HTML du presse-papier.
  Future<String?> getHtmlText();

  /// Copie du HTML vers le presse-papier.
  Future<void> copyHtmlToClipboard(String html);

  /// Retourne le texte brut du presse-papier.
  Future<String?> getClipboardText();

  /// Copie du texte brut vers le presse-papier.
  Future<void> copyTextToClipboard(String text);

  /// Retourne le Markdown du presse-papier.
  Future<String?> getMarkdownText();

  /// Copie du Markdown vers le presse-papier.
  Future<void> copyMarkdownToClipboard(String markdown);

  /// Si le presse-papier n'est pas vide ou contient quelque chose a coller.
  Future<bool> get hasClipboardContent async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    return clipboardData != null;
  }
}
