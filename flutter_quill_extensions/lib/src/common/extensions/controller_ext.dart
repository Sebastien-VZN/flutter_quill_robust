import 'package:flutter_quill/flutter_quill.dart';

@Deprecated('Invalid extension')
extension QuillControllerExt on QuillController {
  @Deprecated(
    'Invalid extension property and will be removed, use selection.baseOffset instead',
  )
  int get index => selection.baseOffset;
  @Deprecated(
    'Invalid extension property and will be removed, use selection.extentOffset - selection.baseOffset instead',
  )
  int get length => selection.extentOffset - index;
}
