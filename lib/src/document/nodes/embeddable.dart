import "dart:convert" show jsonDecode, jsonEncode;

import "package:flutter/foundation.dart" show debugPrint;
import "package:flutter_quill/src/document/data_caster.dart" show DataCaster;

/// An object which can be embedded into a Quill document.
///
/// See also:
///
/// * [BlockEmbed] which represents a block embed.
class Embeddable {
  const Embeddable(this.type, this.data);

  factory Embeddable.fromJson(Map<String, dynamic> json) {
    try {
      final m = Map<String, Object>.from(json);
      return Embeddable(m.keys.first, m.values.first);
    } catch (e) {
      debugPrint("Embeddable map must only have one key : $e");
      return const Embeddable("", Object);
    }
  }

  /// The type of this object.
  final String type;

  /// The data payload of this object.
  final Object data;

  Map<String, Object> toJson() {
    return {type: data};
  }

  /// Retourne `data` caste en `int?` si le type runtime est `int`, sinon `null`.
  /// Log un warning si `data` est non-null mais pas un `int`.
  int? get intVal => DataCaster.toInt(data, context: "Embeddable.intVal[$type]");

  /// Retourne `data` caste en `String?` si le type runtime est `String`, sinon `null`.
  /// Log un warning si `data` est non-null mais pas un `String`.
  String? get stringVal => DataCaster.toStr(data, context: "Embeddable.stringVal[$type]");

  /// Retourne `data` caste en `bool?` si le type runtime est `bool`, sinon `null`.
  /// Log un warning si `data` est non-null mais pas un `bool`.
  bool? get boolValue => DataCaster.toBool(data, context: "Embeddable.boolValue[$type]");

  /// Retourne `data` caste en `double?` si le type runtime est `num` (int ou double), sinon `null`.
  /// Promouvoit un `int` en `double` automatiquement.
  /// Log un warning si `data` est non-null mais pas un `num`.
  double? get numberValue => DataCaster.toDouble(data, context: "Embeddable.numberValue[$type]");
}

/// There are two built-in embed types supported by Quill documents, however
/// the document model itself does not make any assumptions about the types
/// of embedded objects and allows users to define their own types.
class BlockEmbed extends Embeddable {
  const BlockEmbed(super.type, String super.data);
  factory BlockEmbed.formula(String formula) => BlockEmbed(formulaType, formula);
  factory BlockEmbed.custom(CustomBlockEmbed customBlock) => BlockEmbed(customType, customBlock.toJsonString());

  static const String formulaType = "formula";
  static const String customType = "custom";
}

class CustomBlockEmbed extends BlockEmbed {
  const CustomBlockEmbed(super.type, super.data);

  String toJsonString() => jsonEncode(toJson());

  static CustomBlockEmbed? fromJsonString(String data) {
    try {
      final value = jsonDecode(data);
      if (value != null && value is Map<String, dynamic>) {
        final embeddable = Embeddable.fromJson(value);
        return CustomBlockEmbed(embeddable.type, embeddable.data.toString());
      }
    } catch (e) {
      debugPrint("Error in fromJsonString CustomBlockEmbed : $e");
      return null;
    }
    return null;
  }
}
