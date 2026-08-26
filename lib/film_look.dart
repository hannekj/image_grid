import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum PhotoFilter { original, blackAndWhite, fade, warm, cool, contrast }

/// Luminance grayscale.
const _blackAndWhiteMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

/// Soft washed look — lower contrast, lifted shadows.
const _fadeMatrix = <double>[
  0.78, 0.08, 0.08, 0, 28,
  0.08, 0.78, 0.08, 0, 28,
  0.08, 0.08, 0.78, 0, 28,
  0, 0, 0, 1, 0,
];

/// Golden / warm cast.
const _warmMatrix = <double>[
  1.12, 0.04, 0, 0, 12,
  0.02, 0.98, 0, 0, 4,
  0, 0, 0.82, 0, 0,
  0, 0, 0, 1, 0,
];

/// Cool blue cast.
const _coolMatrix = <double>[
  0.86, 0, 0.04, 0, 0,
  0, 0.96, 0.04, 0, 6,
  0.04, 0.04, 1.14, 0, 18,
  0, 0, 0, 1, 0,
];

/// Punchier contrast.
const _contrastMatrix = <double>[
  1.35, 0, 0, 0, -36,
  0, 1.35, 0, 0, -36,
  0, 0, 1.35, 0, -36,
  0, 0, 0, 1, 0,
];

/// Identity matrix — keeps [ColorFiltered] in the tree for every filter so
/// image slots are not remounted (and pan/zoom reset) when switching looks.
const _identityMatrix = <double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

extension PhotoFilterX on PhotoFilter {
  String get label => switch (this) {
        PhotoFilter.original => 'Original',
        PhotoFilter.blackAndWhite => 'S/H',
        PhotoFilter.fade => 'Fade',
        PhotoFilter.warm => 'Varm',
        PhotoFilter.cool => 'Cool',
        PhotoFilter.contrast => 'Kontrast',
      };

  ColorFilter get colorFilter => switch (this) {
        PhotoFilter.original =>
          const ColorFilter.matrix(_identityMatrix),
        PhotoFilter.blackAndWhite =>
          const ColorFilter.matrix(_blackAndWhiteMatrix),
        PhotoFilter.fade => const ColorFilter.matrix(_fadeMatrix),
        PhotoFilter.warm => const ColorFilter.matrix(_warmMatrix),
        PhotoFilter.cool => const ColorFilter.matrix(_coolMatrix),
        PhotoFilter.contrast => const ColorFilter.matrix(_contrastMatrix),
      };
}

Widget applyPhotoFilter(PhotoFilter filter, Widget child) {
  return ColorFiltered(colorFilter: filter.colorFilter, child: child);
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

String filmDateLabel([DateTime? date]) {
  final value = date ?? DateTime.now();
  final month = _norwegianMonths[value.month - 1];
  return '${value.day}. $month ${value.year}';
}

class FilmLookLayer extends StatelessWidget {
  const FilmLookLayer({
    super.key,
    required this.grain,
    required this.dateStamp,
    this.date,
  });

  final bool grain;
  final bool dateStamp;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    if (!grain && !dateStamp) return const SizedBox.expand();

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (grain)
            const CustomPaint(
              painter: GrainPainter(),
              child: SizedBox.expand(),
            ),
          if (dateStamp)
            Align(
              alignment: const Alignment(-0.78, 0.86),
              child: Text(
                filmDateLabel(date),
                style: GoogleFonts.specialElite(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0xCC000000), blurRadius: 8),
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GrainPainter extends CustomPainter {
  const GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final count = (size.width * size.height / 52).round().clamp(180, 1200);
    final light = Paint()..color = const Color(0x28FFFFFF);
    final dark = Paint()..color = const Color(0x24000000);

    for (var i = 0; i < count; i++) {
      final speckle = i.isEven ? light : dark;
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          1.2,
          1.2,
        ),
        speckle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GrainPainter oldDelegate) => false;
}

class FilterLookControls extends StatelessWidget {
  const FilterLookControls({
    super.key,
    required this.filter,
    required this.grain,
    required this.onFilterChanged,
    required this.onGrainChanged,
  });

  final PhotoFilter filter;
  final bool grain;
  final ValueChanged<PhotoFilter> onFilterChanged;
  final ValueChanged<bool> onGrainChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final option in PhotoFilter.values)
        LookToggleChip(
          label: option.label,
          selected: filter == option,
          expand: false,
          onTap: () => onFilterChanged(option),
        ),
      LookToggleChip(
        label: 'Korn',
        selected: grain,
        expand: false,
        onTap: () => onGrainChanged(!grain),
      ),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: chips.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) => chips[index],
    );
  }
}

class LookControls extends StatelessWidget {
  const LookControls({
    super.key,
    required this.grain,
    required this.dateStamp,
    required this.onGrainChanged,
    required this.onDateStampChanged,
  });

  final bool grain;
  final bool dateStamp;
  final ValueChanged<bool> onGrainChanged;
  final ValueChanged<bool> onDateStampChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LookToggleChip(
            label: 'Korn',
            selected: grain,
            onTap: () => onGrainChanged(!grain),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LookToggleChip(
            label: 'Dato',
            selected: dateStamp,
            onTap: () => onDateStampChanged(!dateStamp),
          ),
        ),
      ],
    );
  }
}

class LookToggleChip extends StatelessWidget {
  const LookToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: expand ? 0 : 12,
        vertical: 10,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? const Color(0xFF2C3028) : const Color(0xFF6F7668),
        ),
      ),
    );

    return Material(
      color: selected
          ? const Color(0xFF7E8F72).withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}
