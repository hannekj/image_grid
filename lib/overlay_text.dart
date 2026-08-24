import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'editor_colors.dart';
import 'chat_bubble.dart';

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

List<Color> get overlayBubbleColors => [
      chatBubbleBlue,
      locationPillColor,
      const Color(0xFF34C759),
      chatBubbleGray,
      const Color(0xFF5856D6),
      ...editorSwatchColors,
    ];

List<String> get overlayBubbleColorLabels => [
      'Blå',
      'Mørk',
      'Grønn',
      'Grå',
      'Lilla',
      ...editorSwatchLabels,
    ];

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

enum OverlayKind { text, message, location, date, time, weather, pageNumber }

enum OverlayTextEffect { none, shadow, outline }

Color overlayContrastColor(Color color) {
  return color.computeLuminance() > 0.55 ? const Color(0xFF111111) : Colors.white;
}

const _norwegianMonths = [
  'januar',
  'februar',
  'mars',
  'april',
  'mai',
  'juni',
  'juli',
  'august',
  'september',
  'oktober',
  'november',
  'desember',
];

String overlayDateLabel([DateTime? date]) {
  final value = date ?? DateTime.now();
  final month = _norwegianMonths[value.month - 1];
  return '${value.day}. $month ${value.year}';
}

String overlayTimeLabel([DateTime? date]) {
  final value = date ?? DateTime.now();
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class WeatherPreset {
  const WeatherPreset({
    required this.id,
    required this.icon,
    required this.temp,
  });

  final String id;
  final IconData icon;
  final String temp;

  /// Stable storage — no emoji (avoids missing-glyph / overlap bugs).
  String get value => '$id|$temp';
}

const overlayWeatherPresets = [
  WeatherPreset(id: 'sun', icon: Icons.wb_sunny_outlined, temp: '22°'),
  WeatherPreset(id: 'partly', icon: Icons.wb_cloudy_outlined, temp: '16°'),
  WeatherPreset(id: 'cloud', icon: Icons.cloud_outlined, temp: '12°'),
  WeatherPreset(id: 'rain', icon: Icons.water_drop_outlined, temp: '8°'),
  WeatherPreset(id: 'snow', icon: Icons.ac_unit, temp: '−2°'),
  WeatherPreset(id: 'fog', icon: Icons.foggy, temp: '6°'),
];

String overlayWeatherLabel() => overlayWeatherPresets.first.value;

IconData overlayWeatherIconForId(String id) {
  for (final preset in overlayWeatherPresets) {
    if (preset.id == id) return preset.icon;
  }
  return Icons.wb_sunny_outlined;
}

/// Maps a weather sticker value to a Material icon + plain label (no emoji).
(IconData icon, String label) overlayWeatherParts(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return (Icons.wb_sunny_outlined, 'Vær');
  }

  final pipe = trimmed.indexOf('|');
  if (pipe > 0) {
    final id = trimmed.substring(0, pipe);
    final temp = trimmed.substring(pipe + 1).trim();
    return (
      overlayWeatherIconForId(id),
      temp.isEmpty ? 'Vær' : temp,
    );
  }

  // Legacy emoji values from older stickers.
  const prefixes = <(String, IconData)>[
    ('☀️', Icons.wb_sunny_outlined),
    ('☀', Icons.wb_sunny_outlined),
    ('⛅', Icons.wb_cloudy_outlined),
    ('☁️', Icons.cloud_outlined),
    ('☁', Icons.cloud_outlined),
    ('🌧', Icons.water_drop_outlined),
    ('⛈️', Icons.thunderstorm_outlined),
    ('⛈', Icons.thunderstorm_outlined),
    ('❄️', Icons.ac_unit),
    ('❄', Icons.ac_unit),
    ('🌫', Icons.foggy),
  ];

  for (final (prefix, icon) in prefixes) {
    if (trimmed.startsWith(prefix)) {
      final rest = trimmed.substring(prefix.length).trim();
      return (icon, rest.isEmpty ? 'Vær' : rest);
    }
  }

  return (Icons.wb_sunny_outlined, trimmed);
}

String overlayPageNumberLabel(int index, int total) {
  final safeTotal = total < 1 ? 1 : total;
  final safeIndex = index.clamp(0, safeTotal - 1) + 1;
  return '$safeIndex/$safeTotal';
}

String overlayDefaultValue(OverlayKind kind) {
  return switch (kind) {
    OverlayKind.date => overlayDateLabel(),
    OverlayKind.time => overlayTimeLabel(),
    OverlayKind.weather => overlayWeatherLabel(),
    OverlayKind.pageNumber => '1/1',
    OverlayKind.location => '',
    OverlayKind.message => '',
    OverlayKind.text => '',
  };
}

IconData overlayKindIcon(OverlayKind kind) {
  return switch (kind) {
    OverlayKind.location => Icons.location_on,
    OverlayKind.message => Icons.chat_bubble_outline,
    OverlayKind.date => Icons.calendar_today_outlined,
    OverlayKind.time => Icons.schedule,
    OverlayKind.weather => Icons.wb_sunny_outlined,
    OverlayKind.pageNumber => Icons.tag,
    OverlayKind.text => Icons.title,
  };
}

String overlayKindLabel(OverlayKind kind) {
  return switch (kind) {
    OverlayKind.location => 'Sted',
    OverlayKind.message => 'Melding',
    OverlayKind.date => 'Dato',
    OverlayKind.time => 'Klokke',
    OverlayKind.weather => 'Vær',
    OverlayKind.pageNumber => 'Side',
    OverlayKind.text => 'Tekst',
  };
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
    this.bubbleColor,
    this.tailSide = BubbleTailSide.right,
  });

  factory OverlayText.create({
    required String value,
    required int index,
    OverlayKind kind = OverlayKind.text,
    OverlayText? styleFrom,
  }) {
    if (kind == OverlayKind.location) {
      const bubble = locationPillColor;
      final base = styleFrom != null && styleFrom.kind == OverlayKind.location
          ? styleFrom
          : null;
      final bubbleColor = base?.bubbleColor ?? bubble;
      return OverlayText(
        value: value,
        kind: OverlayKind.location,
        bubbleColor: bubbleColor,
        color: base?.color ?? overlayContrastColor(bubbleColor),
        fontSize: base?.fontSize ?? 15,
        fontId: 'sans',
        alignment: base?.alignment ?? const Alignment(-0.72, 0.72),
        textAlign: TextAlign.left,
        effect: OverlayTextEffect.none,
        tailSide: base?.tailSide ?? BubbleTailSide.left,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      );
    }

    if (kind == OverlayKind.message) {
      const bubble = chatBubbleBlue;
      final base = styleFrom != null && styleFrom.kind == OverlayKind.message
          ? styleFrom
          : null;
      final bubbleColor = base?.bubbleColor ?? bubble;
      return OverlayText(
        value: value,
        kind: OverlayKind.message,
        bubbleColor: bubbleColor,
        color: base?.color ?? overlayContrastColor(bubbleColor),
        fontSize: base?.fontSize ?? 17,
        fontId: base?.fontId ?? 'sans',
        alignment: base?.alignment ?? const Alignment(0.72, 0.72),
        textAlign: TextAlign.left,
        effect: OverlayTextEffect.none,
        tailSide: base?.tailSide ?? BubbleTailSide.right,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
      );
    }

    if (kind == OverlayKind.date ||
        kind == OverlayKind.time ||
        kind == OverlayKind.weather ||
        kind == OverlayKind.pageNumber) {
      const bubble = locationPillColor;
      final base = styleFrom != null && styleFrom.kind == kind ? styleFrom : null;
      final bubbleColor = base?.bubbleColor ?? bubble;
      final alignment = switch (kind) {
        OverlayKind.date => const Alignment(-0.55, 0.78),
        OverlayKind.time => const Alignment(0.55, 0.78),
        OverlayKind.pageNumber => const Alignment(0.72, -0.78),
        _ => const Alignment(0.0, -0.72),
      };
      return OverlayText(
        value: value,
        kind: kind,
        bubbleColor: bubbleColor,
        color: base?.color ?? overlayContrastColor(bubbleColor),
        fontSize: base?.fontSize ?? (kind == OverlayKind.pageNumber ? 14 : 15),
        fontId: 'sans',
        alignment: base?.alignment ?? alignment,
        textAlign: TextAlign.left,
        effect: OverlayTextEffect.none,
        plateStyle: const OverlayPlateStyle(tone: OverlayPlateTone.none),
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
  Color? bubbleColor;
  BubbleTailSide tailSide;

  bool get isLocation => kind == OverlayKind.location;

  bool get isMessage => kind == OverlayKind.message;

  bool get isDate => kind == OverlayKind.date;

  bool get isTime => kind == OverlayKind.time;

  bool get isWeather => kind == OverlayKind.weather;

  bool get isPageNumber => kind == OverlayKind.pageNumber;

  bool get isPill =>
      isLocation || isDate || isTime || isWeather || isPageNumber;

  bool get isBubble => isMessage || isPill;

  bool get isWidgetOverlay => isBubble;

  Color get effectiveBubbleColor {
    if (bubbleColor != null) return bubbleColor!;
    if (isPill) return locationPillColor;
    return tailSide == BubbleTailSide.left ? chatBubbleGray : chatBubbleBlue;
  }

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
    Color? bubbleColor,
    BubbleTailSide? tailSide,
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
      bubbleColor: bubbleColor ?? this.bubbleColor,
      tailSide: tailSide ?? this.tailSide,
    );
  }

  OverlayText withBubbleColor(Color color) {
    return copyWith(
      bubbleColor: color,
      color: overlayContrastColor(color),
    );
  }

  OverlayText withTailSide(BubbleTailSide side) {
    return copyWith(
      tailSide: side,
      alignment: Alignment(
        side == BubbleTailSide.left ? -0.72 : 0.72,
        alignment.y,
      ),
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
