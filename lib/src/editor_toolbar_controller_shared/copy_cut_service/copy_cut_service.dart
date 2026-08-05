import 'package:flutter_quill/src/document/nodes/leaf.dart';

/// Service for copy/cut actions on embed nodes.
///
/// Implementations decide how an embed should be serialized when copied or cut.
/// Override [getCopyCutAction] to customize the behavior for specific embed types.
class CopyCutService {
  const CopyCutService();

  /// Returns a function that transforms embed [data] into a string.
  ///
  /// [type] is the embed type (e.g. "image", "custom").
  /// The returned function takes the embed data and returns the string
  /// representation to write into the clipboard buffer.
  String Function(Object? data) getCopyCutAction(String type) {
    return (Object? data) => Embed.kObjectReplacementCharacter;
  }
}

/// Default implementation of [CopyCutService].
///
/// This implementation always returns the default embed character
/// replacement ([Embed.kObjectReplacementCharacter]) to work with the embeds
/// from the internal flutter quill plugins.
class DefaultCopyCutService extends CopyCutService {
  const DefaultCopyCutService();
}
