import 'package:flutter/material.dart';

class AppTheme {
  static const cream = Color(0xFFF3F4EC);
  static const mist = Color(0xFFE6E9DF);
  static const matcha = Color(0xFF7E8F72);
  static const ink = Color(0xFF2C3028);
  static const muted = Color(0xFF6F7668);
  static const leaf = Color(0xFFC5CBBC);
  static const line = Color(0xFFD2D6C8);

  static ThemeData data() {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: matcha,
        onPrimary: cream,
        secondary: matcha,
        onSecondary: cream,
        surface: cream,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: mist,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: matcha,
          foregroundColor: cream,
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: muted),
      ),
      useMaterial3: true,
    );
  }
}
