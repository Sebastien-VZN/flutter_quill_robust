import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';

double? getFontSizeAsDouble(
  dynamic sizeValue, {
  required DefaultStyles defaultStyles,
}) {
  if (sizeValue is String && ['small', 'normal', 'large', 'huge'].contains(sizeValue)) {
    return switch (sizeValue) {
      'small' => defaultStyles.sizeSmall?.fontSize,
      'normal' => null,
      'large' => defaultStyles.sizeLarge?.fontSize,
      'huge' => defaultStyles.sizeHuge?.fontSize,
      String() => throw ArgumentError(),
    };
  }

  if (sizeValue is double) {
    return sizeValue;
  }

  if (sizeValue is int) {
    return sizeValue.toDouble();
  }

  final fontSize = double.tryParse(sizeValue.toString());
  if (fontSize == null) {
    debugPrint('Invalid size $sizeValue');
    return null;
  }
  return fontSize;
}
