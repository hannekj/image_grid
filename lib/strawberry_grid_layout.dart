import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'heart_grid_layout.dart';

/// 2×2 portrait grid with the same checkerboard corner placement as the heart
/// layout, decorated with painted strawberries.
class StrawberryGridLayout {
  StrawberryGridLayout._();

  static const slotCount = HeartGridLayout.slotCount;
  static const columns = HeartGridLayout.columns;
  static const rows = HeartGridLayout.rows;

  /// A berry needs more room than the heart glyph to read as fruit.
  static const _sizeFactor = 1.75;

  /// Body extents relative to the berry box centre, in units of [berrySize].
  static const _bodyTop = -0.26;
  static const _bodyBottom = 0.46;
  static const _bodyHalfWidth = 0.34;

  static HeartGridMetrics metrics(double width, double height) =>
      HeartGridLayout.metrics(width, height);

  static bool showStrawberry(int row, int col) =>
      HeartGridLayout.showHeart(row, col);

  static double berrySize(HeartGridMetrics metrics) =>
      metrics.heartSize * _sizeFactor;

  static Offset berryCenter(HeartGridMetrics metrics, int row, int col) {
    final rect = metrics.cellRect(row, col);
    final size = berrySize(metrics);
    final inset = metrics.heartInset;
    return Offset(
      rect.left + inset + size / 2,
      rect.bottom - inset - size / 2,
    );
  }

  static void paintStrawberry(Canvas canvas, Offset center, double size) {
    if (size < 3) return;

    final top = center.dy + size * _bodyTop;
    final bottom = center.dy + size * _bodyBottom;
    final bodyHeight = bottom - top;
    final halfWidth = size * _bodyHalfWidth;

    final body = _bodyPath(center, size);
    final bounds = body.getBounds();

    _paintDropShadow(canvas, body, size);
    _paintFlesh(canvas, body, bounds);
    if (size >= 11) {
      _paintSeeds(canvas, body, center.dx, top, bodyHeight, halfWidth, size);
    }
    _paintRimShade(canvas, body, bounds);
    if (size >= 8) _paintGloss(canvas, center, size);
    _paintCalyx(canvas, center, size, top);
  }

  /// Berry silhouette: broad shoulders with a small dip under the calyx,
  /// tapering to a soft point.
  static Path _bodyPath(Offset center, double size) {
    final top = center.dy + size * _bodyTop;
    final bottom = center.dy + size * _bodyBottom;
    final h = bottom - top;
    final w = size * _bodyHalfWidth;

    return Path()
      ..moveTo(center.dx, top + h * 0.02)
      ..cubicTo(
        center.dx - w * 0.66,
        top,
        center.dx - w,
        top + h * 0.13,
        center.dx - w,
        top + h * 0.37,
      )
      ..cubicTo(
        center.dx - w,
        top + h * 0.71,
        center.dx - w * 0.4,
        bottom,
        center.dx,
        bottom,
      )
      ..cubicTo(
        center.dx + w * 0.4,
        bottom,
        center.dx + w,
        top + h * 0.71,
        center.dx + w,
        top + h * 0.37,
      )
      ..cubicTo(
        center.dx + w,
        top + h * 0.13,
        center.dx + w * 0.66,
        top,
        center.dx,
        top + h * 0.02,
      )
      ..close();
  }

  static void _paintDropShadow(Canvas canvas, Path body, double size) {
    canvas.save();
    canvas.translate(size * 0.015, size * 0.03);
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF460C0C).withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(0.6, size * 0.055),
        ),
    );
    canvas.restore();
  }

  static void _paintFlesh(Canvas canvas, Path body, Rect bounds) {
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.34, -0.52),
          radius: 1.18,
          colors: [
            Color(0xFFFF9077),
            Color(0xFFF4553C),
            Color(0xFFDA2C24),
            Color(0xFFAA1B1B),
            Color(0xFF75100F),
          ],
          stops: [0.0, 0.26, 0.55, 0.82, 1.0],
        ).createShader(bounds),
    );
  }

  /// Darkens the lower body and the rim so the berry reads as round.
  static void _paintRimShade(Canvas canvas, Path body, Rect bounds) {
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF56090A).withValues(alpha: 0.4),
          ],
          stops: const [0.5, 1.0],
        ).createShader(bounds),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF6B0D0D).withValues(alpha: 0.22),
            Colors.transparent,
            const Color(0xFF6B0D0D).withValues(alpha: 0.26),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(bounds),
    );
    canvas.restore();
  }

  static void _paintGloss(Canvas canvas, Offset center, double size) {
    final rect = Rect.fromCenter(
      center: Offset(center.dx - size * 0.13, center.dy - size * 0.1),
      width: size * 0.21,
      height: size * 0.12,
    );
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.55);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawOval(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(0.4, size * 0.032),
        ),
    );
    canvas.restore();
  }

  static void _paintSeeds(
    Canvas canvas,
    Path body,
    double centerX,
    double top,
    double bodyHeight,
    double halfWidth,
    double size,
  ) {
    final seedWidth = size * 0.026;
    final seedHeight = size * 0.042;
    final pitBlur = math.max(0.3, size * 0.014);

    canvas.save();
    canvas.clipPath(body);

    for (final row in _seedRows) {
      final y = top + bodyHeight * (0.08 + row.t * 0.84);
      for (final x in row.xs) {
        final lit = 1.0 - 0.36 * x.abs();
        canvas.save();
        canvas.translate(centerX + halfWidth * row.spread * x, y);
        canvas.rotate(x * 0.5);

        // Each achene sits in a shallow pit.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, seedHeight * 0.24),
            width: seedWidth * 1.8,
            height: seedHeight * 1.4,
          ),
          Paint()
            ..color = const Color(0xFF660D0D).withValues(alpha: 0.4)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, pitBlur),
        );

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: seedWidth,
            height: seedHeight,
          ),
          Paint()
            ..color = Color.lerp(
              const Color(0xFFA8813C),
              const Color(0xFFF2DEA2),
              lit,
            )!,
        );

        canvas.restore();
      }
    }
    canvas.restore();
  }

  static void _paintCalyx(
    Canvas canvas,
    Offset center,
    double size,
    double top,
  ) {
    final origin = Offset(center.dx, top + size * 0.035);

    if (size < 8) {
      canvas.drawOval(
        Rect.fromCenter(
          center: origin,
          width: size * 0.42,
          height: size * 0.2,
        ),
        Paint()..color = const Color(0xFF3E7C31),
      );
      return;
    }

    final length = size * 0.27;
    final halfW = size * 0.062;

    // Back sepals fan upward, the stem rises between them, and the front
    // sepals drape forward over the shoulders.
    for (final sepal in _backSepals) {
      _drawSepal(
        canvas,
        origin,
        sepal.angle,
        length * sepal.scale,
        halfW,
        _sepalDark,
      );
    }

    _paintStem(canvas, center, size, top);

    for (final sepal in _frontSepals) {
      _drawSepal(
        canvas,
        origin,
        sepal.angle,
        length * sepal.scale * 0.82,
        halfW * 0.92,
        _sepalLit,
      );
    }

    canvas.drawCircle(
      origin,
      size * 0.032,
      Paint()..color = const Color(0xFF35692A),
    );
  }

  static void _drawSepal(
    Canvas canvas,
    Offset origin,
    double angle,
    double length,
    double halfWidth,
    Color color,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-halfWidth, -length * 0.52, 0, -length)
        ..quadraticBezierTo(halfWidth, -length * 0.52, 0, 0)
        ..close(),
      Paint()..color = color,
    );
    canvas.restore();
  }

  static void _paintStem(
    Canvas canvas,
    Offset center,
    double size,
    double top,
  ) {
    final base = Offset(center.dx, top + size * 0.04);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          base.dx - size * 0.045,
          base.dy - size * 0.16,
          base.dx + size * 0.01,
          base.dy - size * 0.29,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size * 0.048)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF4C7F2E),
    );
  }
}

const _sepalDark = Color(0xFF3B7A2E);
const _sepalLit = Color(0xFF5CA945);

class _Sepal {
  const _Sepal(this.angle, this.scale);

  /// Radians from straight up, positive toward the right.
  final double angle;
  final double scale;
}

const _backSepals = [
  _Sepal(-1.58, 0.82),
  _Sepal(-1.02, 1.0),
  _Sepal(-0.48, 0.88),
  _Sepal(0.06, 1.02),
  _Sepal(0.6, 0.86),
  _Sepal(1.12, 0.98),
  _Sepal(1.62, 0.8),
];

const _frontSepals = [
  _Sepal(-2.3, 0.9),
  _Sepal(-1.78, 0.72),
  _Sepal(-0.78, 0.95),
  _Sepal(-0.22, 0.8),
  _Sepal(0.34, 0.92),
  _Sepal(0.86, 0.76),
  _Sepal(1.9, 0.86),
  _Sepal(2.34, 0.9),
];

class _SeedRow {
  const _SeedRow(this.t, this.spread, this.xs);

  /// Position down the body, 0 at the shoulders and 1 at the tip.
  final double t;

  /// How far the row reaches toward the silhouette at this height.
  final double spread;

  /// Seed positions across the row, -1 to 1.
  final List<double> xs;
}

const _seedRows = [
  _SeedRow(0.06, 0.72, [-0.62, -0.21, 0.21, 0.62]),
  _SeedRow(0.20, 0.90, [-0.80, -0.40, 0.0, 0.40, 0.80]),
  _SeedRow(0.34, 0.99, [-0.66, -0.22, 0.22, 0.66]),
  _SeedRow(0.48, 0.95, [-0.82, -0.40, 0.02, 0.44, 0.82]),
  _SeedRow(0.61, 0.83, [-0.60, -0.18, 0.24, 0.64]),
  _SeedRow(0.73, 0.66, [-0.50, -0.06, 0.40]),
  _SeedRow(0.84, 0.48, [-0.42, 0.04, 0.46]),
  _SeedRow(0.93, 0.28, [-0.32, 0.3]),
];

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
        final berrySize = StrawberryGridLayout.berrySize(layout);
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
