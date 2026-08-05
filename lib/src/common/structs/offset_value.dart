import "package:flutter/foundation.dart" show immutable;
import "package:flutter_quill/src/document/nodes/embeddable.dart";
import "package:flutter_quill/src/document/style.dart" show Style;

@immutable
class OffsetStyleValue<T> {
  const OffsetStyleValue(this.offset, this.value, [this.length]);
  final int offset;
  final int? length;
  final T value;
}

/// Sealed union representing either a [Style] entry or an [Embeddable] entry
/// within a document segment. Used by [Line.collectAllIndividualStylesAndEmbed]
/// and [Document.collectAllIndividualStyleAndEmbed] to return a single list
/// without `dynamic` or raw generic types.
///
/// Consumers must use exhaustive `switch` (Dart 3 pattern matching):
///
/// ```dart
/// switch (entry) {
///   StyleEntry(:final style) => applyStyle(style);
///   EmbedEntry(:final embed) => applyEmbed(embed);
/// }
/// ```
sealed class StyledNodeEntry {
  const StyledNodeEntry(this.offset, this.length);
  final int offset;
  final int? length;
}

/// A [Style] segment at a given [offset] with optional [length].
class StyleEntry extends StyledNodeEntry {
  const StyleEntry(super.offset, this.style, [super.length]);
  final Style style;
}

/// An [Embeddable] segment at a given [offset] with optional [length].
class EmbedEntry extends StyledNodeEntry {
  const EmbedEntry(super.offset, this.embed, [super.length]);
  final Embeddable embed;
}
