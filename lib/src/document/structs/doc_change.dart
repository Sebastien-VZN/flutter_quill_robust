import 'package:flutter/foundation.dart' show immutable;

import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/src/document/document.dart';

@immutable
class DocChange {
  const DocChange(this.before, this.change, this.source);

  /// Document state before [change].
  final Delta before;

  /// Change delta applied to the document.
  final Delta change;

  /// The source of this change.
  final ChangeSource source;
}
