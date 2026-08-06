@internal
library;

// This file should not be exported as the APIs in it are meant for internal usage only
import "package:flutter/foundation.dart" show debugPrint;
import "package:flutter/widgets.dart" show TextSelection;
import "package:flutter_quill/quill_delta.dart";
import "package:flutter_quill/src/controller/quill_controller.dart";
import "package:flutter_quill/src/editor_toolbar_controller_shared/clipboard/clipboard_service_provider.dart";
import "package:meta/meta.dart";
import "package:quill_native_bridge/quill_native_bridge.dart" show HtmlToDelta, MarkdownToDelta;

extension QuillControllerRichPaste on QuillController {
  // Paste the Markdown into the document from [markdown] if not null, otherwise
  /// will read it from the Clipboard in case the [ClipboardServiceProvider.instance]
  /// support it on the current platform.
  ///
  /// Return `true` if can paste or have pasted using Markdown.
  Future<bool> pasteMarkdown() async {
    final service = ClipboardServiceProvider();
    final clipboardService = service.instance;

    Future<String?> getMarkdown() async {
      final clipboardMarkdown = await clipboardService.getMarkdownText();
      if (clipboardMarkdown != null) {
        return clipboardMarkdown;
      }
      return null;
    }

    String? markdownText;
    try {
      markdownText = await getMarkdown();
      // Catching UnimplementedError is intentional: iOS, macOS and Web declare
      // getClipboardMarkdown as supported but never override it in
      // quill_native_bridge, so we must fall through to HTML / plain-text.
      // ignore: avoid_catching_errors
    } on UnimplementedError catch (e) {
      debugPrint("QuillControllerRichPaste: getMarkdownText unimplemented on this platform, falling back — $e");
      return false;
    }

    if (markdownText != null) {
      final clipboardDelta = MarkdownToDelta().convert(markdownText);

      await _pasteDelta(clipboardDelta);

      return true;
    }
    return false;
  }

  /// Paste the HTML from the system clipboard into the document, converted to
  /// a [Delta] with [HtmlToDelta].
  ///
  /// This is the rich-text paste path used by external applications (Word,
  /// browsers, etc.) which publish the `"HTML Format"` clipboard format.
  ///
  /// Media embeds (`image`, `video`, `table`) produced by the converter are
  /// replaced with their URL as plain text since this fork does not support
  /// media embeds.
  ///
  /// Return `true` if HTML was pasted.
  Future<bool> pasteHtml() async {
    final service = ClipboardServiceProvider();
    final clipboardService = service.instance;

    String? htmlText;
    try {
      htmlText = await clipboardService.getHtmlText();
      // Catching UnimplementedError is intentional: some platforms declare
      // getClipboardHtml as supported without overriding it.
      // ignore: avoid_catching_errors
    } on UnimplementedError catch (e) {
      debugPrint("QuillControllerRichPaste: getHtmlText unimplemented on this platform, falling back — $e");
      return false;
    }

    if (htmlText != null) {
      final clipboardDelta = _replaceEmbedsWithUrls(HtmlToDelta().convert(htmlText));

      await _pasteDelta(clipboardDelta);

      return true;
    }
    return false;
  }

  @visibleForTesting
  Future<Delta> getDeltaToPaste(Delta clipboardDelta) async {
    final onRichTextPaste = config.clipboardConfig?.onRichTextPaste;
    if (onRichTextPaste != null) {
      final delta = await onRichTextPaste(clipboardDelta, true);
      if (delta != null) {
        return delta;
      }
    }
    return clipboardDelta;
  }

  Future<void> _pasteDelta(Delta clipboardDelta) async {
    replaceText(
      selection.start,
      selection.end - selection.start,
      // Ensure to await to pass Delta instead of Future<Delta> since this accept Object
      await getDeltaToPaste(clipboardDelta),
      TextSelection.collapsed(offset: selection.end),
    );
  }

  /// Replaces media embed operations (`image`, `video`, `table`) produced by
  /// [HtmlToDelta] with their URL as plain text: this fork removed media embed
  /// support, so the URL is the only portable content.
  ///
  /// Embed payloads without a portable URL (e.g. tables) are dropped.
  static Delta _replaceEmbedsWithUrls(Delta delta) {
    final result = Delta();
    for (final op in delta.toList()) {
      final data = op.data;
      if (op.isInsert && data is Map) {
        final url = _extractEmbedUrl(data);
        if (url != null && url.isNotEmpty) {
          result.insert(url, attributes: op.attributes);
        }
        // Embeds without a portable URL (tables, empty src) are dropped.
      } else {
        result.push(op);
      }
    }
    return result;
  }

  static String? _extractEmbedUrl(Map<dynamic, dynamic> data) {
    final payload = data["image"] ?? data["video"];
    return payload is String ? payload : null;
  }
}
