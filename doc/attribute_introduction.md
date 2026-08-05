# What is a `FormatAttribute`

A `FormatAttribute` is a property or characteristic that can be applied to text or a section of text within the editor to change its appearance or behavior. Attributes allow the user to style the text in various ways.

# How do attributes work?

A format attribute is applied to selected segments of text in the editor. Each attribute has a unique key and a value that determines how it should be applied to the text. For example, to apply bold to a text, an attribute with the key `"bold"` is used. When a text is selected and an attribute is applied, the editor updates the visual representation of the text in real time.

# Scope of a `FormatAttribute`

Format attributes have a scope that limits where they start and end. The scope is called `FormatScope`. It has these options:

```dart
enum FormatScope {
  inline,   // only the selected text will apply the attribute (e.g. bold, italic, strike)
  block,    // the entire paragraph will apply the attribute (e.g. header, align, code-block)
  embeds,   // the attribute is treated as a distinct part of a paragraph, acting as a block
  metadata, // the attribute can be applied but is metadata for embeds, not rendered directly
}
```

> **Note:** The `metadata` scope was previously called `ignore` in upstream flutter_quill. It covers embed-related metadata keys such as `width`, `height`, `style`, and `token`. These are not rendered directly by the editor but are carried alongside embed blocks.

# How `FormatAttribute` is defined

This fork replaces the 22+ `Attribute<T>` subclasses from upstream flutter_quill with a single `FormatAttribute` class. There is **no generic type parameter**. Instead, a `FormatValueType` enum provides an explicit runtime type marker that tells consumers how to safely cast the value.

```dart
@immutable
class FormatAttribute {
  const FormatAttribute({
    required this.key,
    required this.scope,
    required this.value,
    required this.valueType,
  });

  /// Unique key matching the Quill Delta JSON key.
  final String key;
  final FormatScope scope;

  /// The attribute value. Use typed accessors (intValue, stringValue, etc.)
  /// instead of accessing this directly whenever possible.
  final Object? value;

  /// Runtime type marker — tells consumers how to safely cast [value].
  final FormatValueType valueType;
}
```

The key of any `FormatAttribute` must be **unique** to avoid conflicts with the built-in instances.

# `FormatValueType`

Because `FormatAttribute` does not use a generic type parameter, the `FormatValueType` enum provides an explicit runtime type marker. This compensates for Dart's lack of union types and lets call sites perform safe, typed casts without relying on `dynamic`.

```dart
enum FormatValueType {
  boolean,        // value is a bool
  string,          // value is a non-null String
  nullableString,  // value is a String?
  integer,         // value is an int
  nullableInteger, // value is an int?
  number,          // value is a double
  nullableNumber,  // value is a double? (int is promoted to double)
}
```

# Typed accessors and `DataCaster`

Instead of reading `value` directly (which is `Object?`), consumers should use the typed accessors. These delegate to `DataCaster`, a centralized casting utility (`lib/src/document/data_caster.dart`) that returns `null` on type mismatch and emits a `debugPrint` warning so malformed data can be traced in production.

```dart
int?    get intValue;     // delegates to DataCaster.toInt
String? get stringValue;  // delegates to DataCaster.toStr
bool?   get boolValue;    // delegates to DataCaster.toBool
double? get numberValue;  // delegates to DataCaster.toDouble (promotes int → double)
```

Each accessor first checks that `valueType` is compatible. If it is not, the accessor returns `null` without calling `DataCaster`. If `valueType` is compatible but the runtime value does not match the expected type, `DataCaster` logs a warning via `debugPrint` and returns `null`.

## `DataCaster` overview

```dart
class DataCaster {
  static int?    toInt(Object? value, {String? context});
  static String? toStr(Object? value, {String? context});
  static bool?   toBool(Object? value, {String? context});
  static double? toDouble(Object? value, {String? context}); // promotes int → double
}
```

All methods return `null` if `value` is `null` or if the type does not match. When the value is non-null but the type is wrong, a `debugPrint` is emitted with the optional context string, making it easy to trace malformed data in production without throwing exceptions.

# Built-in `FormatAttribute` instances

Instead of subclasses, all built-in formats are declared as `static const` instances on `FormatAttribute` itself. Formats with variable values (header levels, alignments, list types) use convenience constants or factory methods.

## Inline formats — boolean toggles (value is `true`)

```dart
static const FormatAttribute bold          = FormatAttribute(key: "bold",       scope: FormatScope.inline, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute italic        = FormatAttribute(key: "italic",     scope: FormatScope.inline, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute small         = FormatAttribute(key: "small",      scope: FormatScope.inline, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute underline     = FormatAttribute(key: "underline",  scope: FormatScope.inline, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute strikeThrough = FormatAttribute(key: "strike",     scope: FormatScope.inline, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute inlineCode    = FormatAttribute(key: "code",       scope: FormatScope.inline, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute placeholder   = FormatAttribute(key: "placeholder",scope: FormatScope.inline, value: true, valueType: FormatValueType.boolean);
```

## Inline formats — nullable string values

```dart
static const FormatAttribute font       = FormatAttribute(key: "font",       scope: FormatScope.inline, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute size       = FormatAttribute(key: "size",       scope: FormatScope.inline, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute link       = FormatAttribute(key: "link",       scope: FormatScope.inline, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute color      = FormatAttribute(key: "color",      scope: FormatScope.inline, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute background = FormatAttribute(key: "background", scope: FormatScope.inline, value: null, valueType: FormatValueType.nullableString);
```

## Inline — script (sub/super)

```dart
static const FormatAttribute subscript   = FormatAttribute(key: "script", scope: FormatScope.inline, value: "sub",   valueType: FormatValueType.nullableString);
static const FormatAttribute superscript = FormatAttribute(key: "script", scope: FormatScope.inline, value: "super", valueType: FormatValueType.nullableString);
static const FormatAttribute script      = FormatAttribute(key: "script", scope: FormatScope.inline, value: null,    valueType: FormatValueType.nullableString);
```

## Block formats

```dart
static const FormatAttribute header    = FormatAttribute(key: "header",     scope: FormatScope.block, value: null, valueType: FormatValueType.nullableInteger);
static const FormatAttribute indent    = FormatAttribute(key: "indent",     scope: FormatScope.block, value: null, valueType: FormatValueType.nullableInteger);
static const FormatAttribute align     = FormatAttribute(key: "align",      scope: FormatScope.block, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute list      = FormatAttribute(key: "list",       scope: FormatScope.block, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute direction = FormatAttribute(key: "direction",  scope: FormatScope.block, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute codeBlock  = FormatAttribute(key: "code-block", scope: FormatScope.block, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute blockQuote = FormatAttribute(key: "blockquote", scope: FormatScope.block, value: true, valueType: FormatValueType.boolean);
static const FormatAttribute lineHeight = FormatAttribute(key: "line-height",scope: FormatScope.block, value: null, valueType: FormatValueType.nullableNumber);
```

## Metadata formats (embed metadata — not rendered directly)

```dart
static const FormatAttribute width  = FormatAttribute(key: "width",  scope: FormatScope.metadata, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute height = FormatAttribute(key: "height", scope: FormatScope.metadata, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute style  = FormatAttribute(key: "style",  scope: FormatScope.metadata, value: null, valueType: FormatValueType.nullableString);
static const FormatAttribute token  = FormatAttribute(key: "token",  scope: FormatScope.metadata, value: "",   valueType: FormatValueType.string);
```

# Convenience constants

## Header levels

```dart
static const FormatAttribute h1 = FormatAttribute(key: "header", scope: FormatScope.block, value: 1, valueType: FormatValueType.nullableInteger);
static const FormatAttribute h2 = FormatAttribute(key: "header", scope: FormatScope.block, value: 2, valueType: FormatValueType.nullableInteger);
static const FormatAttribute h3 = FormatAttribute(key: "header", scope: FormatScope.block, value: 3, valueType: FormatValueType.nullableInteger);
static const FormatAttribute h4 = FormatAttribute(key: "header", scope: FormatScope.block, value: 4, valueType: FormatValueType.nullableInteger);
static const FormatAttribute h5 = FormatAttribute(key: "header", scope: FormatScope.block, value: 5, valueType: FormatValueType.nullableInteger);
static const FormatAttribute h6 = FormatAttribute(key: "header", scope: FormatScope.block, value: 6, valueType: FormatValueType.nullableInteger);
```

## Alignment values

```dart
static const FormatAttribute leftAlignment    = FormatAttribute(key: "align", scope: FormatScope.block, value: "left",    valueType: FormatValueType.nullableString);
static const FormatAttribute centerAlignment  = FormatAttribute(key: "align", scope: FormatScope.block, value: "center",  valueType: FormatValueType.nullableString);
static const FormatAttribute rightAlignment   = FormatAttribute(key: "align", scope: FormatScope.block, value: "right",   valueType: FormatValueType.nullableString);
static const FormatAttribute justifyAlignment = FormatAttribute(key: "align", scope: FormatScope.block, value: "justify", valueType: FormatValueType.nullableString);
```

## List values

```dart
static const FormatAttribute ul        = FormatAttribute(key: "list", scope: FormatScope.block, value: "bullet",  valueType: FormatValueType.nullableString);
static const FormatAttribute ol        = FormatAttribute(key: "list", scope: FormatScope.block, value: "ordered", valueType: FormatValueType.nullableString);
static const FormatAttribute checked   = FormatAttribute(key: "list", scope: FormatScope.block, value: "checked",  valueType: FormatValueType.nullableString);
static const FormatAttribute unchecked = FormatAttribute(key: "list", scope: FormatScope.block, value: "unchecked",valueType: FormatValueType.nullableString);
```

## Direction

```dart
static const FormatAttribute rtl = FormatAttribute(key: "direction", scope: FormatScope.block, value: "rtl", valueType: FormatValueType.nullableString);
```

## Indent levels

```dart
static const FormatAttribute indentL1 = FormatAttribute(key: "indent", scope: FormatScope.block, value: 1, valueType: FormatValueType.nullableInteger);
static const FormatAttribute indentL2 = FormatAttribute(key: "indent", scope: FormatScope.block, value: 2, valueType: FormatValueType.nullableInteger);
static const FormatAttribute indentL3 = FormatAttribute(key: "indent", scope: FormatScope.block, value: 3, valueType: FormatValueType.nullableInteger);
```

## Line height presets

```dart
static const FormatAttribute lineHeightNormal        = FormatAttribute(key: "line-height", scope: FormatScope.block, value: 1.0,  valueType: FormatValueType.nullableNumber);
static const FormatAttribute lineHeightTight         = FormatAttribute(key: "line-height", scope: FormatScope.block, value: 1.15, valueType: FormatValueType.nullableNumber);
static const FormatAttribute lineHeightOneAndHalf    = FormatAttribute(key: "line-height", scope: FormatScope.block, value: 1.5,  valueType: FormatValueType.nullableNumber);
static const FormatAttribute lineHeightDouble        = FormatAttribute(key: "line-height", scope: FormatScope.block, value: 2.0,  valueType: FormatValueType.nullableNumber);
```

# Factory and utility methods

## `fromKeyValue` — deserialize from Delta JSON

```dart
static FormatAttribute? fromKeyValue(String key, Object? value);
```

Looks up `key` in the registry of known format attributes. If found, returns a new `FormatAttribute` with the registry's `scope` and `valueType` and the provided `value`. Returns `null` for unknown keys.

## `clone` — copy with a new value

```dart
static FormatAttribute clone(FormatAttribute origin, Object? value);
```

Creates a new `FormatAttribute` with the same `key`, `scope`, and `valueType` as `origin` but with a different `value`. Used when applying a format with a specific value (e.g. setting header level to 2).

## `cloneNull` — copy with a null value

```dart
FormatAttribute cloneNull();
```

Returns a copy of this attribute with `value` set to `null`. Used to remove a format from a style.

## `getIndentLevel` — dynamic indent level

```dart
static FormatAttribute? getIndentLevel(int? level);
```

Returns the pre-defined `indentL1` / `indentL2` / `indentL3` constant for levels 1–3, or constructs a new `FormatAttribute` for higher levels. Returns `null` if `level` is `null`.

## `inferValueType` — infer type from runtime value

```dart
static FormatValueType inferValueType(Object? value);
```

Infers a `FormatValueType` from a runtime value. Used by `Style.fromJson` for unknown keys that have no registry entry.

# Example: creating a custom format attribute

To create a custom inline highlight attribute, declare a `static const` instance:

```dart
import 'package:flutter_quill/flutter_quill.dart';

const String highlightKey = 'highlight';

const FormatAttribute highlight = FormatAttribute(
  key: highlightKey,
  scope: FormatScope.inline,
  value: null,
  valueType: FormatValueType.nullableString,
);
```

Then use `customStyleBuilder` in `QuillEditorConfig` to render it:

```dart
QuillEditor.basic(
  controller: controller,
  config: QuillEditorConfig(
    customStyleBuilder: (FormatAttribute attribute) {
      if (attribute.key == highlightKey) {
        return TextStyle(color: Colors.black, backgroundColor: Colors.yellow);
      }
      // default paragraph style
      return TextStyle();
    },
  ),
);
```

If you want to see an example of an embed implementation you can see
it [here](https://github.com/singerdmx/flutter-quill/blob/master/doc/custom_embed_blocks.md)