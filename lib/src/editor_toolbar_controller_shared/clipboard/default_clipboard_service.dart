import "package:flutter_quill/src/common/utils/quill_native_provider.dart";
import "package:flutter_quill/src/editor_toolbar_controller_shared/clipboard/clipboard_service.dart";

/// Implementation de [ClipboardService] basee sur le bridge natif.
///
/// Ne supporte que les operations texte/HTML/Markdown.
/// Les methodes media (image, gif, camera) ne sont plus supportees par le bridge.

class DefaultClipboardService extends ClipboardService {
  @override
  Future<String?> getHtmlText() async {
    if (!(await QuillNativeProvider.instance.isSupported(
      QuillNativeBridgeFeature.getClipboardHtml,
    ))) {
      return null;
    }
    return QuillNativeProvider.instance.getClipboardHtml();
  }

  @override
  Future<void> copyHtmlToClipboard(String html) async {
    if (!(await QuillNativeProvider.instance.isSupported(
      QuillNativeBridgeFeature.copyHtmlToClipboard,
    ))) {
      return;
    }
    await QuillNativeProvider.instance.copyHtmlToClipboard(html);
  }

  @override
  Future<String?> getClipboardText() async {
    if (!(await QuillNativeProvider.instance.isSupported(
      QuillNativeBridgeFeature.getClipboardText,
    ))) {
      return null;
    }
    return QuillNativeProvider.instance.getClipboardText();
  }

  @override
  Future<void> copyTextToClipboard(String text) async {
    if (!(await QuillNativeProvider.instance.isSupported(
      QuillNativeBridgeFeature.copyTextToClipboard,
    ))) {
      return;
    }
    await QuillNativeProvider.instance.copyTextToClipboard(text);
  }

  @override
  Future<String?> getMarkdownText() async {
    if (!(await QuillNativeProvider.instance.isSupported(
      QuillNativeBridgeFeature.getClipboardMarkdown,
    ))) {
      return null;
    }
    return QuillNativeProvider.instance.getClipboardMarkdown();
  }

  @override
  Future<void> copyMarkdownToClipboard(String markdown) async {
    if (!(await QuillNativeProvider.instance.isSupported(
      QuillNativeBridgeFeature.copyMarkdownToClipboard,
    ))) {
      return;
    }
    await QuillNativeProvider.instance.copyMarkdownToClipboard(markdown);
  }
}
