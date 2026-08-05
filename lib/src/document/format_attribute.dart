import "dart:collection" show LinkedHashMap, LinkedHashSet;

import "package:flutter/foundation.dart" show immutable;
import "package:flutter_quill/flutter_quill.dart" show Style;
import "package:flutter_quill/src/document/data_caster.dart" show DataCaster;
import "package:flutter_quill/src/document/style.dart" show Style;
import "package:quiver/core.dart";

/// Scopes for format attributes, matching Quill Delta specification.
/// See https://quilljs.com/docs/formats/
enum FormatScope {
  inline,
  block,
  embeds,
  metadata, // was "ignore" — metadata for embeds (width, height, style, token)
}

/// Runtime type marker for format attribute values.
///
/// Compensates for Dart's lack of union types: valueType provides an explicit,
/// without relying on `dynamic` or generic type parameters.
enum FormatValueType {
  boolean,
  string,
  nullableString,
  integer,
  nullableInteger,
  number,
  nullableNumber,
}

/// A single format attribute for rich text, identified by [key] and [scope].
///
/// Instead of 22+ subclasses that only freeze constructor parameters,
/// all formats are declared as const/final instances on this class directly.
/// Factory constructors handle formats with variable values (header levels, alignments, etc.).
///
/// [valueType] is a runtime type marker that compensates for the lack of generic type parameter.
/// Use typed accessors ([intValue], [stringValue], [boolValue], [numberValue]) instead of
/// [value] directly to avoid `Object?` casts at call sites.
@immutable
class FormatAttribute {
  const FormatAttribute({
    required this.key,
    required this.scope,
    required this.value,
    required this.valueType,
  });

  factory FormatAttribute.clone(FormatAttribute origin, Object? value) {
    return FormatAttribute(
      key: origin.key,
      scope: origin.scope,
      value: value,
      valueType: origin.valueType,
    );
  }

  /// Unique key matching the Quill Delta JSON key.
  final String key;
  final FormatScope scope;

  /// The attribute value. Use typed accessors ([intValue], [stringValue], etc.)
  /// instead of accessing this directly whenever possible.
  final Object? value;

  /// Runtime type marker — tells consumers how to safely cast [value].
  final FormatValueType valueType;

  // ---------------------------------------------------------------------------
  // Registry — maps Delta keys to their default FormatAttribute instance.
  // Used by [fromKeyValue] for deserialization.
  // ---------------------------------------------------------------------------
  static final Map<String, FormatAttribute> _registry = LinkedHashMap.of({
    FormatAttribute.bold.key: FormatAttribute.bold,
    FormatAttribute.subscript.key: FormatAttribute.subscript,
    FormatAttribute.superscript.key: FormatAttribute.superscript,
    FormatAttribute.italic.key: FormatAttribute.italic,
    FormatAttribute.small.key: FormatAttribute.small,
    FormatAttribute.underline.key: FormatAttribute.underline,
    FormatAttribute.strikeThrough.key: FormatAttribute.strikeThrough,
    FormatAttribute.inlineCode.key: FormatAttribute.inlineCode,
    FormatAttribute.font.key: FormatAttribute.font,
    FormatAttribute.size.key: FormatAttribute.size,
    FormatAttribute.link.key: FormatAttribute.link,
    FormatAttribute.color.key: FormatAttribute.color,
    FormatAttribute.background.key: FormatAttribute.background,
    FormatAttribute.placeholder.key: FormatAttribute.placeholder,
    FormatAttribute.header.key: FormatAttribute.header,
    FormatAttribute.lineHeight.key: FormatAttribute.lineHeight,
    FormatAttribute.align.key: FormatAttribute.align,
    FormatAttribute.direction.key: FormatAttribute.direction,
    FormatAttribute.list.key: FormatAttribute.list,
    FormatAttribute.codeBlock.key: FormatAttribute.codeBlock,
    FormatAttribute.blockQuote.key: FormatAttribute.blockQuote,
    FormatAttribute.indent.key: FormatAttribute.indent,
    FormatAttribute.width.key: FormatAttribute.width,
    FormatAttribute.height.key: FormatAttribute.height,
    FormatAttribute.style.key: FormatAttribute.style,
    FormatAttribute.token.key: FormatAttribute.token,
    FormatAttribute.script.key: FormatAttribute.script,
  });

  // ---------------------------------------------------------------------------
  // Inline formats — bool toggles (value is always true)
  // ---------------------------------------------------------------------------
  static const FormatAttribute bold = FormatAttribute(
    key: "bold",
    scope: FormatScope.inline,
    value: true,
    valueType: FormatValueType.boolean,
  );
  static const FormatAttribute italic = FormatAttribute(
    key: "italic",
    scope: FormatScope.inline,
    value: true,
    valueType: FormatValueType.boolean,
  );
  static const FormatAttribute small = FormatAttribute(
    key: "small",
    scope: FormatScope.inline,
    value: true,
    valueType: FormatValueType.boolean,
  );
  static const FormatAttribute underline = FormatAttribute(
    key: "underline",
    scope: FormatScope.inline,
    value: true,
    valueType: FormatValueType.boolean,
  );
  static const FormatAttribute strikeThrough = FormatAttribute(
    key: "strike",
    scope: FormatScope.inline,
    value: true,
    valueType: FormatValueType.boolean,
  );
  static const FormatAttribute inlineCode = FormatAttribute(
    key: "code",
    scope: FormatScope.inline,
    value: true,
    valueType: FormatValueType.boolean,
  );
  static const FormatAttribute placeholder = FormatAttribute(
    key: "placeholder",
    scope: FormatScope.inline,
    value: true,
    valueType: FormatValueType.boolean,
  );

  // ---------------------------------------------------------------------------
  // Inline formats — nullable string values
  // ---------------------------------------------------------------------------
  static const FormatAttribute font = FormatAttribute(
    key: "font",
    scope: FormatScope.inline,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute size = FormatAttribute(
    key: "size",
    scope: FormatScope.inline,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute link = FormatAttribute(
    key: "link",
    scope: FormatScope.inline,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute color = FormatAttribute(
    key: "color",
    scope: FormatScope.inline,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute background = FormatAttribute(
    key: "background",
    scope: FormatScope.inline,
    value: null,
    valueType: FormatValueType.nullableString,
  );

  // ---------------------------------------------------------------------------
  // Inline — script (sub/super)
  // ---------------------------------------------------------------------------
  static const FormatAttribute subscript = FormatAttribute(
    key: "script",
    scope: FormatScope.inline,
    value: "sub",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute superscript = FormatAttribute(
    key: "script",
    scope: FormatScope.inline,
    value: "super",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute script = FormatAttribute(
    key: "script",
    scope: FormatScope.inline,
    value: null,
    valueType: FormatValueType.nullableString,
  );

  // ---------------------------------------------------------------------------
  // Block formats — nullable integer values
  // ---------------------------------------------------------------------------
  static const FormatAttribute header = FormatAttribute(
    key: "header",
    scope: FormatScope.block,
    value: null,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute indent = FormatAttribute(
    key: "indent",
    scope: FormatScope.block,
    value: null,
    valueType: FormatValueType.nullableInteger,
  );

  // ---------------------------------------------------------------------------
  // Block formats — nullable string values
  // ---------------------------------------------------------------------------
  static const FormatAttribute align = FormatAttribute(
    key: "align",
    scope: FormatScope.block,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute list = FormatAttribute(
    key: "list",
    scope: FormatScope.block,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute direction = FormatAttribute(
    key: "direction",
    scope: FormatScope.block,
    value: null,
    valueType: FormatValueType.nullableString,
  );

  // ---------------------------------------------------------------------------
  // Block formats — bool toggles
  // ---------------------------------------------------------------------------
  static const FormatAttribute codeBlock = FormatAttribute(
    key: "code-block",
    scope: FormatScope.block,
    value: true,
    valueType: FormatValueType.boolean,
  );
  static const FormatAttribute blockQuote = FormatAttribute(
    key: "blockquote",
    scope: FormatScope.block,
    value: true,
    valueType: FormatValueType.boolean,
  );

  // ---------------------------------------------------------------------------
  // Block — line height (custom, nullable double)
  // ---------------------------------------------------------------------------
  static const FormatAttribute lineHeight = FormatAttribute(
    key: "line-height",
    scope: FormatScope.block,
    value: null,
    valueType: FormatValueType.nullableNumber,
  );

  // ---------------------------------------------------------------------------
  // Metadata formats (width, height, style, token) — not rendered directly
  // ---------------------------------------------------------------------------
  static const FormatAttribute width = FormatAttribute(
    key: "width",
    scope: FormatScope.metadata,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute height = FormatAttribute(
    key: "height",
    scope: FormatScope.metadata,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute style = FormatAttribute(
    key: "style",
    scope: FormatScope.metadata,
    value: null,
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute token = FormatAttribute(
    key: "token",
    scope: FormatScope.metadata,
    value: "",
    valueType: FormatValueType.string,
  );

  // ---------------------------------------------------------------------------
  // Convenience constants — header levels
  // ---------------------------------------------------------------------------
  static const FormatAttribute h1 = FormatAttribute(
    key: "header",
    scope: FormatScope.block,
    value: 1,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute h2 = FormatAttribute(
    key: "header",
    scope: FormatScope.block,
    value: 2,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute h3 = FormatAttribute(
    key: "header",
    scope: FormatScope.block,
    value: 3,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute h4 = FormatAttribute(
    key: "header",
    scope: FormatScope.block,
    value: 4,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute h5 = FormatAttribute(
    key: "header",
    scope: FormatScope.block,
    value: 5,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute h6 = FormatAttribute(
    key: "header",
    scope: FormatScope.block,
    value: 6,
    valueType: FormatValueType.nullableInteger,
  );

  // ---------------------------------------------------------------------------
  // Convenience constants — alignment values
  // ---------------------------------------------------------------------------
  static const FormatAttribute leftAlignment = FormatAttribute(
    key: "align",
    scope: FormatScope.block,
    value: "left",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute centerAlignment = FormatAttribute(
    key: "align",
    scope: FormatScope.block,
    value: "center",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute rightAlignment = FormatAttribute(
    key: "align",
    scope: FormatScope.block,
    value: "right",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute justifyAlignment = FormatAttribute(
    key: "align",
    scope: FormatScope.block,
    value: "justify",
    valueType: FormatValueType.nullableString,
  );

  // ---------------------------------------------------------------------------
  // Convenience constants — list values
  // ---------------------------------------------------------------------------
  static const FormatAttribute ul = FormatAttribute(
    key: "list",
    scope: FormatScope.block,
    value: "bullet",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute ol = FormatAttribute(
    key: "list",
    scope: FormatScope.block,
    value: "ordered",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute checked = FormatAttribute(
    key: "list",
    scope: FormatScope.block,
    value: "checked",
    valueType: FormatValueType.nullableString,
  );
  static const FormatAttribute unchecked = FormatAttribute(
    key: "list",
    scope: FormatScope.block,
    value: "unchecked",
    valueType: FormatValueType.nullableString,
  );

  // ---------------------------------------------------------------------------
  // Convenience constants — direction
  // ---------------------------------------------------------------------------
  static const FormatAttribute rtl = FormatAttribute(
    key: "direction",
    scope: FormatScope.block,
    value: "rtl",
    valueType: FormatValueType.nullableString,
  );

  // ---------------------------------------------------------------------------
  // Convenience constants — indent levels
  // ---------------------------------------------------------------------------
  static const FormatAttribute indentL1 = FormatAttribute(
    key: "indent",
    scope: FormatScope.block,
    value: 1,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute indentL2 = FormatAttribute(
    key: "indent",
    scope: FormatScope.block,
    value: 2,
    valueType: FormatValueType.nullableInteger,
  );
  static const FormatAttribute indentL3 = FormatAttribute(
    key: "indent",
    scope: FormatScope.block,
    value: 3,
    valueType: FormatValueType.nullableInteger,
  );

  // ---------------------------------------------------------------------------
  // Convenience constants — line height presets
  // ---------------------------------------------------------------------------
  static const FormatAttribute lineHeightNormal = FormatAttribute(
    key: "line-height",
    scope: FormatScope.block,
    value: 1.0,
    valueType: FormatValueType.nullableNumber,
  );
  static const FormatAttribute lineHeightTight = FormatAttribute(
    key: "line-height",
    scope: FormatScope.block,
    value: 1.15,
    valueType: FormatValueType.nullableNumber,
  );
  static const FormatAttribute lineHeightOneAndHalf = FormatAttribute(
    key: "line-height",
    scope: FormatScope.block,
    value: 1.5,
    valueType: FormatValueType.nullableNumber,
  );
  static const FormatAttribute lineHeightDouble = FormatAttribute(
    key: "line-height",
    scope: FormatScope.block,
    value: 2.0,
    valueType: FormatValueType.nullableNumber,
  );

  // ---------------------------------------------------------------------------
  // Factory — dynamic indent level
  // ---------------------------------------------------------------------------
  static FormatAttribute? getIndentLevel(int? level) {
    if (level == null) return null;
    if (level == 1) return FormatAttribute.indentL1;
    if (level == 2) return FormatAttribute.indentL2;
    if (level == 3) return FormatAttribute.indentL3;
    return FormatAttribute(
      key: "indent",
      scope: FormatScope.block,
      value: level,
      valueType: FormatValueType.nullableInteger,
    );
  }

  // ---------------------------------------------------------------------------
  // Key sets
  // ---------------------------------------------------------------------------
  static final Set<String> registeredAttributeKeys = Set.unmodifiable(
    _registry.keys,
  );

  static final Set<String> inlineKeys = Set.unmodifiable(<String>{
    FormatAttribute.bold.key,
    FormatAttribute.subscript.key,
    FormatAttribute.superscript.key,
    FormatAttribute.italic.key,
    FormatAttribute.small.key,
    FormatAttribute.underline.key,
    FormatAttribute.strikeThrough.key,
    FormatAttribute.link.key,
    FormatAttribute.color.key,
    FormatAttribute.background.key,
    FormatAttribute.placeholder.key,
    FormatAttribute.font.key,
    FormatAttribute.size.key,
    FormatAttribute.inlineCode.key,
  });

  static final Set<String> metadataKeys = Set.unmodifiable(<String>{
    FormatAttribute.width.key,
    FormatAttribute.height.key,
    FormatAttribute.style.key,
    FormatAttribute.token.key,
  });

  static final Set<String> blockKeys = LinkedHashSet.of({
    FormatAttribute.header.key,
    FormatAttribute.align.key,
    FormatAttribute.list.key,
    FormatAttribute.codeBlock.key,
    FormatAttribute.blockQuote.key,
    FormatAttribute.indent.key,
    FormatAttribute.direction.key,
    FormatAttribute.lineHeight.key,
  });

  static final Set<String> blockKeysExceptHeader = LinkedHashSet.of({
    FormatAttribute.list.key,
    FormatAttribute.align.key,
    FormatAttribute.codeBlock.key,
    FormatAttribute.blockQuote.key,
    FormatAttribute.lineHeight.key,
    FormatAttribute.indent.key,
    FormatAttribute.direction.key,
  });

  static final Set<String> exclusiveBlockKeys = LinkedHashSet.of({
    FormatAttribute.header.key,
    FormatAttribute.list.key,
    FormatAttribute.codeBlock.key,
    FormatAttribute.blockQuote.key,
  });

  // ---------------------------------------------------------------------------
  // Instance API
  // ---------------------------------------------------------------------------
  bool get isInline => scope == FormatScope.inline;

  bool get isBlockExceptHeader => blockKeysExceptHeader.contains(key);

  Map<String, Object?> toJson() => <String, Object?>{key: value};

  // ---------------------------------------------------------------------------
  // Typed value accessors — safe casts via valueType, null if type mismatch.
  // Use these instead of .value to avoid Object? casts at call sites.
  // ---------------------------------------------------------------------------

  /// Returns [value] as `int?` if [valueType] matches an integer type, else null.
  /// Log un warning si la valeur est non-null mais pas un `int`.
  int? get intValue {
    switch (valueType) {
      case FormatValueType.integer:
      case FormatValueType.nullableInteger:
        return DataCaster.toInt(
          value,
          context: "FormatAttribute.intValue[$key]",
        );
      default:
        return null;
    }
  }

  /// Returns [value] as `String?` if [valueType] matches a string type, else null.
  /// Log un warning si la valeur est non-null mais pas un `String`.
  String? get stringValue {
    switch (valueType) {
      case FormatValueType.string:
      case FormatValueType.nullableString:
        return DataCaster.toStr(
          value,
          context: "FormatAttribute.stringValue[$key]",
        );
      default:
        return null;
    }
  }

  /// Returns [value] as `bool?` if [valueType] is [FormatValueType.boolean], else null.
  /// Log un warning si la valeur est non-null mais pas un `bool`.
  bool? get boolValue {
    if (valueType == FormatValueType.boolean) {
      return DataCaster.toBool(
        value,
        context: "FormatAttribute.boolValue[$key]",
      );
    }
    return null;
  }

  /// Returns [value] as `double?` if [valueType] matches a number type, else null.
  /// If the underlying value is an `int`, it is promoted to `double`.
  /// Log un warning si la valeur est non-null mais pas un `num`.
  double? get numberValue {
    switch (valueType) {
      case FormatValueType.number:
      case FormatValueType.nullableNumber:
        return DataCaster.toDouble(
          value,
          context: "FormatAttribute.numberValue[$key]",
        );
      default:
        return null;
    }
  }

  /// Creates a copy of this attribute with [value] set to null (used to remove a format).
  FormatAttribute cloneNull() => FormatAttribute(
    key: key,
    scope: scope,
    value: null,
    valueType: valueType,
  );

  /// Infers [FormatValueType] from a runtime value.
  /// Used by [Style.fromJson] for unknown keys that have no registry entry.
  static FormatValueType inferValueType(Object? value) {
    if (value is bool) return FormatValueType.boolean;
    if (value is int) return FormatValueType.nullableInteger;
    if (value is double) return FormatValueType.nullableNumber;
    if (value is String) return FormatValueType.nullableString;
    return FormatValueType.nullableString;
  }

  static FormatAttribute? fromKeyValue(String key, Object? value) {
    final origin = _registry[key];
    if (origin == null) return null;
    return FormatAttribute(
      key: origin.key,
      scope: origin.scope,
      value: value,
      valueType: origin.valueType,
    );
  }

  static int getRegistryOrder(FormatAttribute attribute) {
    var order = 0;
    for (final attr in _registry.values) {
      if (attr.key == attribute.key) break;
      order++;
    }
    return order;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FormatAttribute) return false;
    return key == other.key && scope == other.scope && value == other.value;
  }

  @override
  int get hashCode => hash3(key, scope, value);

  @override
  String toString() => "FormatAttribute{key: $key, scope: $scope, value: $value, valueType: $valueType}";
}
