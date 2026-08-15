import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

String filmDateLabel([DateTime? date]) {
  final value = date ?? DateTime.now();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.month)}.${two(value.day)}.${two(value.year % 100)}';
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
                  fontSize: 14,
                  letterSpacing: 1.4,
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: selected ? Colors.black : const Color(0xFFCCCCCC),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
