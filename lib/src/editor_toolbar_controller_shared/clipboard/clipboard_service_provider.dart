import "package:flutter_quill/src/editor_toolbar_controller_shared/clipboard/clipboard_service.dart";
import "package:flutter_quill/src/editor_toolbar_controller_shared/clipboard/default_clipboard_service.dart";

final class ClipboardServiceProvider {
  /// Shared backing store, so that overriding [instance] (e.g. in tests or by
  /// an application providing a custom clipboard backend) is visible to every
  /// consumer, including rich paste which builds its own provider.
  static ClipboardService _instance = DefaultClipboardService();

  // The instance-level getter intentionally wraps the shared static field so
  // the public API keeps working on an instance while sharing the backend.
  // ignore: unnecessary_getters_setters
  ClipboardService get instance => _instance;

  set instance(ClipboardService service) => _instance = service;

  void setInstanceToDefault() {
    _instance = DefaultClipboardService();
  }
}
