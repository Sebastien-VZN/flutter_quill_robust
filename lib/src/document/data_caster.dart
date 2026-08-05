import "package:flutter/foundation.dart" show debugPrint;

/// Utilitaire centralise de cast securise pour les valeurs dynamiques.
///
/// Toutes les methodes retournent `null` si la valeur est `null` ou si le type
/// ne correspond pas. En cas de mismatch (valeur non-null mais type incorrect),
/// un debugPrint est emis avec le contexte fourni, ce qui permet de tracer
/// les donnees mal formatees en production.
///
/// Utilise par FormatAttribute (via FormatValueType) et Embeddable.
class DataCaster {
  /// Cast vers `int?`.
  /// Retourne `null` si [value] est `null` ou n'est pas un `int`.
  /// Log un warning si [value] est non-null mais pas un `int`.
  static int? toInt(Object? value, {String? context}) {
    if (value == null) return null;
    if (value is int) return value;
    debugPrint(
      "DataCaster.toInt — type mismatch${context != null ? " ($context)" : ""} — expected int, got ${value.runtimeType}: $value",
    );
    return null;
  }

  /// Cast vers `String?`.
  /// Retourne `null` si [value] est `null` ou n'est pas un `String`.
  static String? toStr(Object? value, {String? context}) {
    if (value == null) return null;
    if (value is String) return value;
    debugPrint(
      "DataCaster.toStr — type mismatch${context != null ? " ($context)" : ""} — expected String, got ${value.runtimeType}: $value",
    );
    return null;
  }

  /// Cast vers `bool?`.
  /// Retourne `null` si [value] est `null` ou n'est pas un `bool`.
  static bool? toBool(Object? value, {String? context}) {
    if (value == null) return null;
    if (value is bool) return value;
    debugPrint(
      "DataCaster.toBool — type mismatch${context != null ? " ($context)" : ""} — expected bool, got ${value.runtimeType}: $value",
    );
    return null;
  }

  /// Cast vers `double?`.
  /// Retourne `null` si [value] est `null` ou n'est pas un `num`.
  /// Promouvoit un `int` en `double` automatiquement.
  static double? toDouble(Object? value, {String? context}) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    debugPrint(
      "DataCaster.toDouble — type mismatch${context != null ? " ($context)" : ""} — expected num, got ${value.runtimeType}: $value",
    );
    return null;
  }
}
