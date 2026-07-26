import 'package:flutter/material.dart';

import 'hex_color.dart';

class AppColors {
  // Primary Color
  static const Color mainColor = Color(0xFFFB923C);
  // Color(0xFFF97316), // Orange-500
  // Color(0xFFFB923C), // Orange-400
  // Color(0xFFEA580C), // Orange-600
  // Light Theme Colors
  static Color lightBackground = HexColor('#FAFAFA');
  static const Color lightPrimaryText = Colors.black;
  static const Color lightSecondaryText = Color(0xFF565656);
  static Color lightSurface = Colors.white; // سطحيات (مثل البطاقات)

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1E1F21);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.grey;
  static const Color darkSurface = Color(0xFF2A2B2D); // سطحيات داكنة

  // Common Colors
  static const Color errorColor = Color(0xFFE94F4F); // تنبيه أو خطأ
  static const Color grayLight = Color(0xFFF1F1F1);
  static const Color grayMedium = Color(0xFF808080);
  static const Color grayDark = Color(0xFF565656);
  static Color colodBlue = HexColor('#F3F9FB');
  static Color searchColor = HexColor('#F1F1F1');
  static Color aleart = HexColor('#E94F4F');
  static Color warning = Colors.yellow;
}
