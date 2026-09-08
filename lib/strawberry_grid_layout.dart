import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'heart_grid_layout.dart';

/// 2×2 portrait grid with the same checkerboard corner decorations as hearts,
/// but with realistic strawberries instead.
class StrawberryGridLayout {
  StrawberryGridLayout._();

  static const slotCount = HeartGridLayout.slotCount;
  static const columns = HeartGridLayout.columns;
  static const rows = HeartGridLayout.rows;

  static HeartGridMetrics metrics(double width, double height) =>
      HeartGridLayout.metrics(width, height);

  static bool showStrawberry(int row, int col) =>
      HeartGridLayout.showHeart(row, col);

  static void paintStrawberry(Canvas canvas, Offset center, double size) {
    if (size < 3) return;

    final body = _bodyPath(center, size);
    final bounds = body.getBounds();

    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF5A1A1A).withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.08),
    );

    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.1, -0.15),
          radius: 0.95,
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFE53935),
            Color(0xFFC62828),
            Color(0xFF8E1A1A),
          ],
          stops: [0.0, 0.38, 0.72, 1.0],
        ).createShader(bounds),
    );

    if (size >= 7) {
      _paintSeeds(canvas, center, size, body);
    }

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.25, size * 0.04)
        ..color = const Color(0xFF7F1414).withValues(alpha: 0.45),
    );

    final highlight = Path()
      ..moveTo(center.dx - size * 0.08, center.dy - size * 0.06)
      ..quadraticBezierTo(
        center.dx - size * 0.18,
        center.dy - size * 0.22,
        center.dx - size * 0.04,
        center.dy - size * 0.18,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.25, size * 0.035)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    _paintCalyx(canvas, center, size);
    _paintStem(canvas, center, size);
  }

  static Path _bodyPath(Offset center, double size) {
    final w = size * 0.78;
    final h = size * 0.9;
    final path = Path();
    path.moveTo(center.dx, center.dy + h * 0.46);
    path.cubicTo(
      center.dx - w * 0.14,
      center.dy + h * 0.34,
      center.dx - w * 0.56,
      center.dy + h * 0.1,
      center.dx - w * 0.5,
      center.dy - h * 0.16,
    );
    path.cubicTo(
      center.dx - w * 0.42,
      center.dy - h * 0.4,
      center.dx - w * 0.18,
      center.dy - h * 0.46,
      center.dx,
      center.dy - h * 0.4,
    );
    path.cubicTo(
      center.dx + w * 0.18,
      center.dy - h * 0.46,
      center.dx + w * 0.42,
      center.dy - h * 0.4,
      center.dx + w * 0.5,
      center.dy - h * 0.16,
    );
    path.cubicTo(
      center.dx + w * 0.56,
      center.dy + h * 0.1,
      center.dx + w * 0.14,
      center.dy + h * 0.34,
      center.dx,
      center.dy + h * 0.46,
    );
    path.close();
    return path;
  }

  static void _paintSeeds(
    Canvas canvas,
    Offset center,
    double size,
    Path clip,
  ) {
    final seedPaint = Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.9);
    final radius = math.max(0.35, size * 0.028);
    final offsets = [
      Offset(-0.18, -0.04),
      Offset(-0.06, 0.08),
      Offset(0.08, -0.02),
      Offset(0.2, 0.1),
      Offset(-0.1, 0.2),
      Offset(0.14, 0.22),
      Offset(0.0, 0.14),
      Offset(-0.22, 0.12),
    ];
    canvas.save();
    canvas.clipPath(clip);
    for (final offset in offsets) {
      canvas.drawCircle(
        center + Offset(offset.dx * size, offset.dy * size),
        radius,
        seedPaint,
      );
    }
    canvas.restore();
  }

  static void _paintCalyx(Canvas canvas, Offset center, double size) {
    final leafPaint = Paint()..color = const Color(0xFF388E3C);
    final darkLeaf = Paint()..color = const Color(0xFF2E7D32);
    final top = center.dy - size * 0.4;
    final leafW = size * 0.22;
    final leafH = size * 0.14;

    for (final angle in [-0.95, -0.2, 0.55]) {
      canvas.save();
      canvas.translate(center.dx, top);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(-leafW * 0.35, 0),
          width: leafW,
          height: leafH,
        ),
        angle.abs() > 0.5 ? darkLeaf : leafPaint,
      );
      canvas.restore();
    }
  }

  static void _paintStem(Canvas canvas, Offset center, double size) {
    final stemW = math.max(1.0, size * 0.11);
    final stemH = size * 0.2;
    final stemTop = center.dy - size * 0.52;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, stemTop),
          width: stemW,
          height: stemH,
        ),
        Radius.circular(stemW / 2),
      ),
      Paint()..color = const Color(0xFF33691E),
    );
  }
}

class StrawberryDecoration extends StatelessWidget {
  const StrawberryDecoration({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StrawberryDecorationPainter(size: size),
      ),
    );
  }
}

class _StrawberryDecorationPainter extends CustomPainter {
  const _StrawberryDecorationPainter({required this.size});

  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    StrawberryGridLayout.paintStrawberry(
      canvas,
      Offset(size / 2, size / 2),
      size,
    );
  }

  @override
  bool shouldRepaint(covariant _StrawberryDecorationPainter oldDelegate) =>
      oldDelegate.size != size;
}

class StrawberryGridFrame extends StatelessWidget {
  const StrawberryGridFrame({
    super.key,
    required this.slots,
    this.showStrawberries = true,
  });

  final List<Widget> slots;
  final bool showStrawberries;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == StrawberryGridLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final layout = StrawberryGridLayout.metrics(width, height);
        final berrySize = layout.heartSize;
        final inset = layout.heartInset;

        Widget cell(int index, int row, int col) {
          final slot = Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              slots[index],
              if (showStrawberries &&
                  StrawberryGridLayout.showStrawberry(row, col))
                Positioned(
                  left: inset,
                  bottom: inset,
                  child: IgnorePointer(
                    child: StrawberryDecoration(size: berrySize),
                  ),
                ),
            ],
          );

          return ClipRect(child: slot);
        }

        return ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              for (var row = 0; row < StrawberryGridLayout.rows; row++) ...[
                if (row > 0) SizedBox(height: layout.gap),
                Expanded(
                  child: Row(
                    children: [
                      for (var col = 0;
                          col < StrawberryGridLayout.columns;
                          col++) ...[
                        if (col > 0) SizedBox(width: layout.gap),
                        Expanded(
                          child: cell(
                            row * StrawberryGridLayout.columns + col,
                            row,
                            col,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
