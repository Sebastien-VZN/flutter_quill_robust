import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_quill/src/document/format_attribute.dart';
import 'package:quiver/core.dart';

/* Collection of style attributes */
@immutable
class Style {
  const Style() : _attributes = const <String, FormatAttribute>{};

  factory Style.fromJson(Map<String, dynamic>? attributes) {
    if (attributes == null) {
      return const Style();
    }

    final result = attributes.map((key, dynamic value) {
      final attr = FormatAttribute.fromKeyValue(key, value);
      return MapEntry<String, FormatAttribute>(
        key,
        attr ??
            FormatAttribute(
              key: key,
              scope: FormatScope.metadata,
              value: value,
              valueType: FormatAttribute.inferValueType(value),
            ),
      );
    });
    return Style.attr(result);
  }

  const Style.attr(this._attributes);

  final Map<String, FormatAttribute> _attributes;

  Map<String, dynamic>? toJson() => _attributes.isEmpty
      ? null
      : _attributes.map<String, dynamic>(
          (_, attribute) => MapEntry<String, dynamic>(attribute.key, attribute.value),
        );

  Iterable<String> get keys => _attributes.keys;

  Iterable<FormatAttribute> get values => _attributes.values.sorted(
    (a, b) => FormatAttribute.getRegistryOrder(a) - FormatAttribute.getRegistryOrder(b),
  );

  Map<String, FormatAttribute> get attributes => _attributes;

  bool get isEmpty => _attributes.isEmpty;

  bool get isNotEmpty => _attributes.isNotEmpty;

  bool get isInline => isNotEmpty && values.every((item) => item.isInline);

  bool get isBlock => isNotEmpty && values.every((item) => item.scope == FormatScope.block);

  bool get isIgnored => isNotEmpty && values.every((item) => item.scope == FormatScope.metadata);

  FormatAttribute get single => _attributes.values.single;

  bool containsKey(String key) => _attributes.containsKey(key);

  FormatAttribute? getBlockExceptHeader() {
    for (final val in values) {
      if (val.isBlockExceptHeader && val.value != null) {
        return val;
      }
    }
    for (final val in values) {
      if (val.isBlockExceptHeader) {
        return val;
      }
    }
    return null;
  }

  Map<String, FormatAttribute> getBlocksExceptHeader() {
    final m = <String, FormatAttribute>{};
    attributes.forEach((key, value) {
      if (FormatAttribute.blockKeysExceptHeader.contains(key)) {
        m[key] = value;
      }
    });
    return m;
  }

  Style merge(FormatAttribute attribute) {
    final merged = Map<String, FormatAttribute>.from(_attributes);
    if (attribute.value == null) {
      merged.remove(attribute.key);
    } else {
      merged[attribute.key] = attribute;
    }
    return Style.attr(merged);
  }

  Style mergeAll(Style other) {
    var result = Style.attr(_attributes);
    for (final attribute in other.values) {
      result = result.merge(attribute);
    }
    return result;
  }

  Style removeAll(Set<FormatAttribute> attributes) {
    final merged = Map<String, FormatAttribute>.from(_attributes);
    attributes.map((item) => item.key).forEach(merged.remove);
    return Style.attr(merged);
  }

  Style put(FormatAttribute attribute) {
    final m = Map<String, FormatAttribute>.from(attributes);
    m[attribute.key] = attribute;
    return Style.attr(m);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Style) {
      return false;
    }
    final typedOther = other;
    const eq = MapEquality<String, FormatAttribute>();
    return eq.equals(_attributes, typedOther._attributes);
  }

  @override
  int get hashCode {
    final hashes = _attributes.entries.map(
      (entry) => hash2(entry.key, entry.value),
    );
    return hashObjects(hashes);
  }

  @override
  String toString() => "{${_attributes.values.join(', ')}}";
}
