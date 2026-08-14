import 'package:flutter/material.dart';

class OverlayTextStyle {
  const OverlayTextStyle({
    required this.label,
    required this.fontSize,
  });

  final String label;
  final double fontSize;
}

class OverlayFont {
  const OverlayFont({
    required this.id,
    required this.label,
    this.fontFamily,
    this.fontFamilyFallback,
    this.letterSpacing,
    this.fontWeight = FontWeight.w600,
  });

  final String id;
  final String label;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final double? letterSpacing;
  final FontWeight fontWeight;

  TextStyle style({Color? color, double? fontSize, double? height}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      fontSize: fontSize,
      height: height,
    );
  }
}

const overlayTextSizes = [
  OverlayTextStyle(label: 'Liten', fontSize: 16),
  OverlayTextStyle(label: 'Medium', fontSize: 24),
  OverlayTextStyle(label: 'Stor', fontSize: 34),
];

const overlayTextColors = [
  Colors.white,
  Colors.black,
];

const overlayFonts = [
  OverlayFont(id: 'sans', label: 'Sans'),
  OverlayFont(
    id: 'serif',
    label: 'Serif',
    fontFamily: 'Georgia',
    fontFamilyFallback: ['Times New Roman', 'serif'],
    fontWeight: FontWeight.w500,
  ),
  OverlayFont(
    id: 'smal',
    label: 'Smal',
    fontFamily: 'Avenir Next Condensed',
    fontFamilyFallback: ['Arial Narrow', 'sans-serif-condensed'],
    letterSpacing: 0.6,
  ),
  OverlayFont(
    id: 'plakat',
    label: 'Plakat',
    fontFamily: 'Futura',
    fontFamilyFallback: ['Impact', 'sans-serif-black'],
    letterSpacing: 0.8,
    fontWeight: FontWeight.w700,
  ),
  OverlayFont(
    id: 'hand',
    label: 'Hånd',
    fontFamily: 'Noteworthy',
    fontFamilyFallback: ['Snell Roundhand', 'cursive'],
    fontWeight: FontWeight.w400,
  ),
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
