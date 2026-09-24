import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Classic instant-print border. Optional paper tint + grain for grids.
class PolaroidFrame extends StatelessWidget {
  const PolaroidFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 8, 32),
    this.shadowBlur = 16,
    this.shadowOffset = const Offset(1, 6),
    this.paperColor = Colors.white,
    this.textured = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double shadowBlur;
  final Offset shadowOffset;
  final Color paperColor;
  final bool textured;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paperColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: textured ? 0.16 : 0.22),
            blurRadius: shadowBlur,
            offset: shadowOffset,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (textured)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _PolaroidPaperGrainPainter()),
              ),
            ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Soft fibre grain drawn only where the paper shows (photo covers the centre).
class _PolaroidPaperGrainPainter extends CustomPainter {
  const _PolaroidPaperGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // Warm grey wash so the stock reads off-white, not pure paper white.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x14A8A49C),
    );

    final rng = math.Random(42);
    final speck = Paint()..style = PaintingStyle.fill;
    final count = math.max(80, (w * h / 28).round());
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final a = 10 + rng.nextInt(28);
      speck.color = Color.fromARGB(a, 120, 115, 108);
      canvas.drawCircle(Offset(x, y), 0.35 + rng.nextDouble() * 0.55, speck);
    }

    // Soft vignette toward the outer edge.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w * 0.5, h * 0.42),
          math.max(w, h) * 0.72,
          const [Color(0x00000000), Color(0x14000000)],
          const [0.55, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _PolaroidPaperGrainPainter oldDelegate) => false;
}
