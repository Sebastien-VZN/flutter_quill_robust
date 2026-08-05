import "package:flutter_quill/src/editor_toolbar_controller_shared/clipboard/clipboard_service.dart";
import "package:flutter_quill/src/editor_toolbar_controller_shared/clipboard/default_clipboard_service.dart";

final class ClipboardServiceProvider {
  ClipboardService _instance = DefaultClipboardService();

  ClipboardService get instance => _instance;

  set instance(ClipboardService service) => _instance;

  void setInstanceToDefault() {
    _instance = DefaultClipboardService();
  }
}
