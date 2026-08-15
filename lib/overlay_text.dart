import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OverlayFont {
  const OverlayFont({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  TextStyle style({Color? color, double? fontSize, double? height}) {
    final base = switch (id) {
      'serif' => GoogleFonts.libreBaskerville(fontWeight: FontWeight.w500),
      'smal' => GoogleFonts.barlowCondensed(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      'plakat' => GoogleFonts.bebasNeue(
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      'hand' => GoogleFonts.caveat(fontWeight: FontWeight.w500),
      _ => GoogleFonts.dmSans(fontWeight: FontWeight.w600),
    };

    return base.copyWith(
      color: color,
      fontSize: fontSize,
      height: height,
    );
  }
}

const overlayTextMinSize = 12.0;
const overlayTextMaxSize = 72.0;

/// Many options for overlay captions — neutrals, pastels, and accents.
const overlayTextColors = [
  Color(0xFFFFFFFF), // Hvit
  Color(0xFFF3F4EC), // Krem
  Color(0xFFE8E0D4), // Beige
  Color(0xFFF5D0C5), // Peach
  Color(0xFFFFC1CC), // Rosa
  Color(0xFFE8A0BF), // Pink
  Color(0xFFD4A5A5), // Dusty rose
  Color(0xFFF4C430), // Gul
  Color(0xFFE8B86D), // Gull
  Color(0xFFC4A484), // Clay
  Color(0xFFB85C38), // Terracotta
  Color(0xFFD97B4A), // Coral
  Color(0xFF7E8F72), // Matcha
  Color(0xFFA8C686), // Soft lime
  Color(0xFF8FA4B0), // Sky
  Color(0xFF7EB6D9), // Baby blue
  Color(0xFF6B8CAE), // Denim
  Color(0xFF9B8EC4), // Lavendel
  Color(0xFFB07AC7), // Orchid
  Color(0xFF6B3A3A), // Burgunder
  Color(0xFF2C3A4A), // Navy
  Color(0xFF111111), // Svart
];

const overlayTextColorLabels = [
  'Hvit',
  'Krem',
  'Beige',
  'Peach',
  'Rosa',
  'Pink',
  'Dusty rose',
  'Gul',
  'Gull',
  'Clay',
  'Terracotta',
  'Coral',
  'Matcha',
  'Lime',
  'Sky',
  'Baby blue',
  'Denim',
  'Lavendel',
  'Orchid',
  'Burgunder',
  'Navy',
  'Svart',
];

const overlayFonts = [
  OverlayFont(id: 'sans', label: 'Sans'),
  OverlayFont(id: 'serif', label: 'Serif'),
  OverlayFont(id: 'smal', label: 'Smal'),
  OverlayFont(id: 'plakat', label: 'Plakat'),
  OverlayFont(id: 'hand', label: 'Hånd'),
];

OverlayFont overlayFontById(String id) {
  return overlayFonts.firstWhere(
    (font) => font.id == id,
    orElse: () => overlayFonts.first,
  );
}

class OverlayText {
  OverlayText({
    required this.value,
    this.color = Colors.white,
    this.fontSize = 24,
    this.fontId = 'sans',
    this.alignment = const Alignment(0, 0.72),
    this.plate = true,
  });

  String value;
  Color color;
  double fontSize;
  String fontId;
  Alignment alignment;
  bool plate;

  OverlayText copyWith({
    String? value,
    Color? color,
    double? fontSize,
    String? fontId,
    Alignment? alignment,
    bool? plate,
  }) {
    return OverlayText(
      value: value ?? this.value,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontId: fontId ?? this.fontId,
      alignment: alignment ?? this.alignment,
      plate: plate ?? this.plate,
    );
  }
}
