import 'package:flutter/material.dart';

class ColorHelper {
  ColorHelper._();

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  // Get a readable text color (white or slate-900) based on background luminance
  static Color getContrastColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? const Color(0xFF0F172A)
        : Colors.white;
  }
}
