import 'package:flutter/material.dart';

class AppTheme {
  /// Warm off-white canvas background.
  static const cream = Color(0xFFFAF9F6);

  /// Raised surfaces, chips, bottom bar fill.
  static const mist = Color(0xFFEFEFE9);

  /// Dark forest green — primary actions, logo, active nav.
  static const matcha = Color(0xFF1E302A);

  static const ink = Color(0xFF1E302A);
  static const muted = Color(0xFF8A9088);
  static const leaf = Color(0xFFE5E3DC);
  static const line = Color(0xFFE5E3DC);

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
        backgroundColor: cream,
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
      dividerColor: line,
      useMaterial3: true,
    );
  }
}
