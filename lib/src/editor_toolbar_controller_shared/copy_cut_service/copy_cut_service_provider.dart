import 'package:flutter_quill/src/editor_toolbar_controller_shared/copy_cut_service/copy_cut_service.dart';

class CopyCutServiceProvider {
  CopyCutService instance = const DefaultCopyCutService();

  void setInstanceToDefault() {
    instance = const DefaultCopyCutService();
  }
}
