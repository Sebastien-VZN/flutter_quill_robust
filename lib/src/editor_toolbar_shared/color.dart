import 'package:flutter/material.dart';

Color hexToColor(String? hexString) {
  if (hexString == null) {
    return Colors.black;
  }
  final hexRegex = RegExp(r'([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');

  final result = hexString.replaceAll('#', '');
  if (!hexRegex.hasMatch(result)) {
    return Colors.black;
  }

  final buffer = StringBuffer();
  if (result.length == 6 || result.length == 7) buffer.write('ff');
  buffer.write(result);
  return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFF000000);
}

// Without the hash sign (`#`).
String colorToHex(Color color) {
  int floatToInt8(double x) => (x * 255.0).round() & 0xff;

  final alpha = floatToInt8(color.a);
  final red = floatToInt8(color.r);
  final green = floatToInt8(color.g);
  final blue = floatToInt8(color.b);

  return '${alpha.toRadixString(16).padLeft(2, '0')}'
          '${red.toRadixString(16).padLeft(2, '0')}'
          '${green.toRadixString(16).padLeft(2, '0')}'
          '${blue.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
