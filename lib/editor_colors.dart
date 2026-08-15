import 'package:flutter/material.dart';

/// Shared palette for overlay text and frame stroke colors.
class EditorSwatch {
  const EditorSwatch(this.label, this.color);

  final String label;
  final Color color;
}

const editorSwatches = [
  EditorSwatch('Hvit', Color(0xFFFFFFFF)),
  EditorSwatch('Krem', Color(0xFFF3F4EC)),
  EditorSwatch('Beige', Color(0xFFE8E0D4)),
  EditorSwatch('Butter', Color(0xFFF5E6A3)),
  EditorSwatch('Peach', Color(0xFFF5D0C5)),
  EditorSwatch('Lychee', Color(0xFFFFB7C5)),
  EditorSwatch('Rosa', Color(0xFFFFC1CC)),
  EditorSwatch('Pink', Color(0xFFE8A0BF)),
  EditorSwatch('Dusty rose', Color(0xFFD4A5A5)),
  EditorSwatch('Cherry', Color(0xFFE85A7A)),
  EditorSwatch('Apricot', Color(0xFFFFC48A)),
  EditorSwatch('Sunset', Color(0xFFFF8E6E)),
  EditorSwatch('Gull', Color(0xFFE8B86D)),
  EditorSwatch('Clay', Color(0xFFC4A484)),
  EditorSwatch('Terracotta', Color(0xFFB85C38)),
  EditorSwatch('Coral', Color(0xFFD97B4A)),
  EditorSwatch('Pistachio', Color(0xFFC5D5A3)),
  EditorSwatch('Matcha', Color(0xFF7E8F72)),
  EditorSwatch('Lime', Color(0xFFA8C686)),
  EditorSwatch('Cloud', Color(0xFFD6E4F0)),
  EditorSwatch('Baby blue', Color(0xFF7EB6D9)),
  EditorSwatch('Sky', Color(0xFF8FA4B0)),
  EditorSwatch('Denim', Color(0xFF6B8CAE)),
  EditorSwatch('Lilac mist', Color(0xFFD4C4E8)),
  EditorSwatch('Lavendel', Color(0xFF9B8EC4)),
  EditorSwatch('Orchid', Color(0xFFB07AC7)),
  EditorSwatch('Burgunder', Color(0xFF6B3A3A)),
  EditorSwatch('Espresso', Color(0xFF3D2C29)),
  EditorSwatch('Navy', Color(0xFF2C3A4A)),
  EditorSwatch('Svart', Color(0xFF111111)),
];

List<Color> get editorSwatchColors => [
      for (final swatch in editorSwatches) swatch.color,
    ];

List<String> get editorSwatchLabels => [
      for (final swatch in editorSwatches) swatch.label,
    ];
