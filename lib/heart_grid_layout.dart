import 'dart:math' as math;

import 'package:flutter/material.dart';

enum HeartDecorationStyle { white, silver3d }

/// 2×2 portrait grid with white gutters and checkerboard corner hearts.
class HeartGridLayout {
  HeartGridLayout._();

  static const slotCount = 4;
  static const columns = 2;
  static const rows = 2;

  static const _designWidth = 581.0;
  static const _designHeight = 1024.0;
  static const _designGap = 6.0;

  static HeartGridMetrics metrics(double width, double height) {
    final scale = math.min(width / _designWidth, height / _designHeight);
    final gap = math.max(1.0, _designGap * scale);
    final cellWidth = (width - gap * (columns - 1)) / columns;
    final cellHeight = (height - gap * (rows - 1)) / rows;
    return HeartGridMetrics(
      gap: gap,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
  }

  static double gapForSize(double width, double height) =>
      metrics(width, height).gap;

  static bool showHeart(int row, int col) => (row + col).isEven;

  static Path heartPath(Offset center, double size) {
    final path = Path();
    final w = size * 0.92;
    final h = size * 0.84;
    path.moveTo(center.dx, center.dy + h * 0.32);
    path.cubicTo(
      center.dx - w * 0.52,
      center.dy - h * 0.08,
      center.dx - w * 0.52,
      center.dy - h * 0.62,
      center.dx,
      center.dy - h * 0.28,
    );
    path.cubicTo(
      center.dx + w * 0.52,
      center.dy - h * 0.62,
      center.dx + w * 0.52,
      center.dy - h * 0.08,
      center.dx,
      center.dy + h * 0.32,
    );
    path.close();
    return path;
  }

  static void paintHeart(
    Canvas canvas,
    Offset center,
    double size, {
    HeartDecorationStyle style = HeartDecorationStyle.white,
  }) {
    final path = heartPath(center, size);

    if (style == HeartDecorationStyle.white) {
      canvas.drawPath(path, Paint()..color = Colors.white);
      return;
    }

    final bounds = path.getBounds();
    final depth = math.max(0.6, size * 0.07);

    // Blurred shadow stays centered so the heart silhouette matches the white layout.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4A4A4A).withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 0.55),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFF8F8F8),
            Color(0xFFDADADA),
            Color(0xFF9A9A9A),
            Color(0xFF707070),
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ).createShader(bounds),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.4, size * 0.045)
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    final highlight = Path()
      ..moveTo(center.dx - size * 0.12, center.dy - size * 0.18)
      ..quadraticBezierTo(
        center.dx - size * 0.24,
        center.dy - size * 0.34,
        center.dx - size * 0.06,
        center.dy - size * 0.28,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.35, size * 0.035)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.75),
    );
  }
}

class HeartGridMetrics {
  const HeartGridMetrics({
    required this.gap,
    required this.cellWidth,
    required this.cellHeight,
  });

  final double gap;
  final double cellWidth;
  final double cellHeight;

  bool get _compactThumb => cellWidth < 48;

  double get heartSize {
    if (_compactThumb) {
      return math.min(cellHeight * 0.22, cellWidth * 0.36).clamp(3.5, 9.0);
    }
    return cellWidth * 0.095;
  }

  double get heartInset {
    if (_compactThumb) {
      return (cellWidth * 0.12).clamp(1.0, 2.5);
    }
    return math.max(1.0, cellWidth * 0.062);
  }

  Rect cellRect(int row, int col) {
    final left = col * (cellWidth + gap);
    final top = row * (cellHeight + gap);
    return Rect.fromLTWH(left, top, cellWidth, cellHeight);
  }

  Offset heartCenter(int row, int col) {
    final rect = cellRect(row, col);
    final size = heartSize;
    final inset = heartInset;
    return Offset(
      rect.left + inset + size / 2,
      rect.bottom - inset - size / 2,
    );
  }
}

class HeartDecoration extends StatelessWidget {
  const HeartDecoration({
    super.key,
    required this.size,
    this.style = HeartDecorationStyle.white,
  });

  final double size;
  final HeartDecorationStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeartDecorationPainter(size: size, style: style),
      ),
    );
  }
}

class _HeartDecorationPainter extends CustomPainter {
  const _HeartDecorationPainter({
    required this.size,
    required this.style,
  });

  final double size;
  final HeartDecorationStyle style;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    HeartGridLayout.paintHeart(
      canvas,
      Offset(size / 2, size / 2),
      size,
      style: style,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartDecorationPainter oldDelegate) =>
      oldDelegate.size != size || oldDelegate.style != style;
}

class HeartGridFrame extends StatelessWidget {
  const HeartGridFrame({
    super.key,
    required this.slots,
    this.showHearts = true,
    this.heartStyle = HeartDecorationStyle.white,
  });

  final List<Widget> slots;
  final bool showHearts;
  final HeartDecorationStyle heartStyle;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == HeartGridLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final layout = HeartGridLayout.metrics(width, height);
        final heartSize = layout.heartSize;
        final inset = layout.heartInset;

        Widget cell(int index, int row, int col) {
          final slot = Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              slots[index],
              if (showHearts && HeartGridLayout.showHeart(row, col))
                Positioned(
                  left: inset,
                  bottom: inset,
                  child: IgnorePointer(
                    child: HeartDecoration(
                      size: heartSize,
                      style: heartStyle,
                    ),
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
              for (var row = 0; row < HeartGridLayout.rows; row++) ...[
                if (row > 0) SizedBox(height: layout.gap),
                Expanded(
                  child: Row(
                    children: [
                      for (var col = 0; col < HeartGridLayout.columns; col++) ...[
                        if (col > 0) SizedBox(width: layout.gap),
                        Expanded(
                          child: cell(
                            row * HeartGridLayout.columns + col,
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
