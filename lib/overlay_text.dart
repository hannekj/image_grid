import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'editor_colors.dart';

class OverlayFont {
  const OverlayFont({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  TextStyle style({Color? color, double? fontSize, double? height, double? letterSpacing}) {
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
      'nunito' => GoogleFonts.nunito(fontWeight: FontWeight.w600),
      'beanie' => GoogleFonts.reenieBeanie(fontWeight: FontWeight.w400),
      'vibes' => GoogleFonts.greatVibes(fontWeight: FontWeight.w400),
      'cormorant' => GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w400),
      'cinzel' => GoogleFonts.cinzel(
          fontWeight: FontWeight.w400,
          letterSpacing: 2.0,
        ),
      'lora' => GoogleFonts.lora(fontWeight: FontWeight.w400),
      // SIL OFL via Google Fonts — free for commercial embedding.
      'klipp' => GoogleFonts.londrinaSketch(fontWeight: FontWeight.w400),
      'roff' => GoogleFonts.rubikDirt(fontWeight: FontWeight.w400),
      'skisse' => GoogleFonts.cabinSketch(fontWeight: FontWeight.w400),
      _ => GoogleFonts.dmSans(fontWeight: FontWeight.w600),
    };

    return base.copyWith(
      color: color,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

const overlayTextMinSize = 12.0;
const overlayTextMaxSize = 72.0;

List<Color> get overlayTextColors => editorSwatchColors;

List<String> get overlayTextColorLabels => editorSwatchLabels;

const overlayFonts = [
  OverlayFont(id: 'sans', label: 'Sans'),
  OverlayFont(id: 'nunito', label: 'Nunito'),
  OverlayFont(id: 'serif', label: 'Serif'),
  OverlayFont(id: 'cormorant', label: 'Cormorant'),
  OverlayFont(id: 'lora', label: 'Lora'),
  OverlayFont(id: 'smal', label: 'Smal'),
  OverlayFont(id: 'plakat', label: 'Plakat'),
  OverlayFont(id: 'cinzel', label: 'Cinzel'),
  OverlayFont(id: 'hand', label: 'Hånd'),
  OverlayFont(id: 'vibes', label: 'Vibes'),
  OverlayFont(id: 'beanie', label: 'Beanie'),
  OverlayFont(id: 'klipp', label: 'Klipp'),
  OverlayFont(id: 'roff', label: 'Røff'),
  OverlayFont(id: 'skisse', label: 'Skisse'),
];

OverlayFont overlayFontById(String id) {
  return overlayFonts.firstWhere(
    (font) => font.id == id,
    orElse: () => overlayFonts.first,
  );
}

enum OverlayPlateTone { none, light, dark }

class OverlayPlateStyle {
  const OverlayPlateStyle({
    required this.tone,
    this.opacity = 0.5,
  });

  final OverlayPlateTone tone;
  final double opacity;

  bool get hasPlate => tone != OverlayPlateTone.none;

  Color get fill {
    if (!hasPlate) return Colors.transparent;
    final base = tone == OverlayPlateTone.dark ? Colors.black : Colors.white;
    return base.withValues(alpha: opacity);
  }

  String get label => switch (tone) {
        OverlayPlateTone.none => 'Ingen plate',
        OverlayPlateTone.light => 'Lys plate',
        OverlayPlateTone.dark => 'Mørk plate',
      };

  bool matches(OverlayPlateStyle other) {
    return tone == other.tone &&
        (tone == OverlayPlateTone.none ||
            (opacity - other.opacity).abs() < 0.01);
  }
}

const overlayPlatePresets = [
  OverlayPlateStyle(tone: OverlayPlateTone.none),
  OverlayPlateStyle(tone: OverlayPlateTone.light, opacity: 0.25),
  OverlayPlateStyle(tone: OverlayPlateTone.light, opacity: 0.50),
  OverlayPlateStyle(tone: OverlayPlateTone.light, opacity: 0.75),
  OverlayPlateStyle(tone: OverlayPlateTone.dark, opacity: 0.25),
  OverlayPlateStyle(tone: OverlayPlateTone.dark, opacity: 0.50),
  OverlayPlateStyle(tone: OverlayPlateTone.dark, opacity: 0.75),
];

enum OverlayKind { text, location }

enum OverlayTextEffect { none, shadow, outline }

Color overlayContrastColor(Color color) {
  return color.computeLuminance() > 0.55 ? const Color(0xFF111111) : Colors.white;
}

Alignment overlayTextDefaultAlignment(int index) {
  const presets = [
    Alignment(0, 0.72),
    Alignment(0, -0.55),
    Alignment(0, 0.12),
    Alignment(-0.55, 0.35),
    Alignment(0.55, 0.35),
  ];
  return presets[index % presets.length];
}

class OverlayText {
  OverlayText({
    required this.value,
    this.kind = OverlayKind.text,
    this.color = Colors.white,
    this.fontSize = 24,
    this.fontId = 'sans',
    this.alignment = const Alignment(0, 0.72),
    this.textAlign = TextAlign.center,
    this.rotation = 0,
    this.letterSpacing = 0,
    this.effect = OverlayTextEffect.none,
    this.plateStyle = const OverlayPlateStyle(
      tone: OverlayPlateTone.dark,
      opacity: 0.55,
    ),
  });

  factory OverlayText.create({
    required String value,
    required int index,
    OverlayKind kind = OverlayKind.text,
    OverlayText? styleFrom,
  }) {
    if (kind == OverlayKind.location) {
      return OverlayText(
        value: value,
        kind: OverlayKind.location,
        color: const Color(0xFF111111),
        fontSize: 15,
        fontId: 'sans',
        alignment: const Alignment(0, -0.78),
        textAlign: TextAlign.center,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(
          tone: OverlayPlateTone.light,
          opacity: 0.92,
        ),
      );
    }

    final base =
        styleFrom != null && styleFrom.kind == OverlayKind.text
            ? styleFrom
            : null;
    return OverlayText(
      value: value,
      kind: OverlayKind.text,
      color: base?.color ?? Colors.white,
      fontSize: base?.fontSize ?? 24,
      fontId: base?.fontId ?? 'sans',
      alignment: overlayTextDefaultAlignment(index),
      textAlign: base?.textAlign ?? TextAlign.center,
      effect: base?.effect ?? OverlayTextEffect.none,
      plateStyle: base?.plateStyle ??
          const OverlayPlateStyle(
            tone: OverlayPlateTone.dark,
            opacity: 0.55,
          ),
    );
  }

  String value;
  OverlayKind kind;
  Color color;
  double fontSize;
  String fontId;
  Alignment alignment;
  TextAlign textAlign;
  double rotation;
  double letterSpacing;
  OverlayTextEffect effect;
  OverlayPlateStyle plateStyle;

  bool get isLocation => kind == OverlayKind.location;

  TextStyle textStyle() {
    final base = overlayFontById(fontId).style(
      color: color,
      fontSize: fontSize,
      height: 1.25,
      letterSpacing: letterSpacing == 0 ? null : letterSpacing,
    );
    return switch (effect) {
      OverlayTextEffect.none => base,
      OverlayTextEffect.shadow => base.copyWith(
          shadows: const [
            Shadow(
              color: Color(0x99000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
            Shadow(
              color: Color(0x66000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      OverlayTextEffect.outline => base,
    };
  }

  TextStyle outlineStrokeStyle() {
    final strokeWidth = (fontSize * 0.09).clamp(1.5, 5.0);
    return overlayFontById(fontId).style(
      fontSize: fontSize,
      height: 1.25,
      letterSpacing: letterSpacing == 0 ? null : letterSpacing,
    ).copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = overlayContrastColor(color),
    );
  }

  OverlayText copyWith({
    String? value,
    OverlayKind? kind,
    Color? color,
    double? fontSize,
    String? fontId,
    Alignment? alignment,
    TextAlign? textAlign,
    double? rotation,
    double? letterSpacing,
    OverlayTextEffect? effect,
    OverlayPlateStyle? plateStyle,
  }) {
    return OverlayText(
      value: value ?? this.value,
      kind: kind ?? this.kind,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontId: fontId ?? this.fontId,
      alignment: alignment ?? this.alignment,
      textAlign: textAlign ?? this.textAlign,
      rotation: rotation ?? this.rotation,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      effect: effect ?? this.effect,
      plateStyle: plateStyle ?? this.plateStyle,
    );
  }

  /// Rotation in degrees for UI display.
  double get rotationDegrees => rotation * 180 / math.pi;

  OverlayText withRotationDegrees(double degrees) {
    return copyWith(rotation: degrees * math.pi / 180);
  }

  /// Advance rotation by 90° (0 → 90 → 180 → -90 → 0).
  OverlayText withNextQuarterTurn() {
    const steps = [0.0, 90.0, 180.0, -90.0];
    final current = rotationDegrees;
    var index = 0;
    var minDist = double.infinity;
    for (var i = 0; i < steps.length; i++) {
      final dist = (current - steps[i]).abs();
      if (dist < minDist) {
        minDist = dist;
        index = i;
      }
    }
    return withRotationDegrees(steps[(index + 1) % steps.length]);
  }

  /// Text alignment plus a matching horizontal placement on the canvas.
  OverlayText withTextAlign(TextAlign align) {
    final x = switch (align) {
      TextAlign.left || TextAlign.start => -0.82,
      TextAlign.right || TextAlign.end => 0.82,
      _ => 0.0,
    };
    return copyWith(
      textAlign: align,
      alignment: Alignment(x, alignment.y),
    );
  }
}
