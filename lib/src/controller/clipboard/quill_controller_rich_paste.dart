@internal
library;

// This file should not be exported as the APIs in it are meant for internal usage only
import "package:flutter/widgets.dart" show TextSelection;
import "package:flutter_quill/quill_delta.dart";
import "package:flutter_quill/src/controller/quill_controller.dart";
import "package:flutter_quill/src/editor_toolbar_controller_shared/clipboard/clipboard_service_provider.dart";
import "package:meta/meta.dart";
import "package:quill_native_bridge/quill_native_bridge.dart" show MarkdownToDelta;

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

    final markdownText = await getMarkdown();
    if (markdownText != null) {
      final clipboardDelta = MarkdownToDelta().convert(markdownText);

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
}
