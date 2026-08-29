import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'checker_grid_layout.dart';
import 'grid_layout.dart';
import 'heart_grid_layout.dart';
import 'layer_collage_layout.dart';
import 'stagger_grid_layout.dart';
import 'strip_grid_layout.dart';

class LayoutOutlinePainter extends CustomPainter {
  const LayoutOutlinePainter({
    required this.layout,
    this.cellColor = AppTheme.leaf,
    this.gapColor = Colors.white,
    this.gap = 2.5,
  });

  final GridLayout layout;
  final Color cellColor;
  final Color gapColor;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = gapColor);

    if (layout.isDump) {
      _paintDump(canvas, size);
      return;
    }

    if (layout.isBooth) {
      _paintBooth(canvas, size);
      return;
    }

    if (layout.isFilmStrip) {
      _paintFilmStrip(canvas, size, layout.isFilmHorizontal);
      return;
    }

    if (layout.isReaction) {
      _paintReaction(canvas, size);
      return;
    }

    if (layout.isOverlayFrame) {
      _paintOverlayFrame(canvas, size);
      return;
    }

    if (layout.isAlbumGrid) {
      _paintAlbumGrid(canvas, size);
      return;
    }

    if (layout.isStripGrid) {
      _paintStripGrid(canvas, size);
      return;
    }

    if (layout.isStaggerGrid) {
      _paintStaggerGrid(canvas, size);
      return;
    }

    if (layout.isLayerCollage) {
      _paintLayerCollage(canvas, size);
      return;
    }

    if (layout.isHeartGrid) {
      _paintHeartGrid(canvas, size);
      return;
    }

    if (layout.isCheckerGrid) {
      _paintCheckerGrid(canvas, size);
      return;
    }

    final cellPaint = Paint()..color = cellColor;
    final rowFlexTotal = layout.rowFlexTotal;
    final rowCount = layout.rows.length;
    final availableHeight = size.height - gap * (rowCount - 1);
    var y = 0.0;

    for (var r = 0; r < rowCount; r++) {
      final row = layout.rows[r];
      final rowHeight = availableHeight * row.flex / rowFlexTotal;
      var cellFlexTotal = 0;
      for (final cell in row.cells) {
        cellFlexTotal += cell;
      }

      final colCount = row.cells.length;
      final availableWidth = size.width - gap * (colCount - 1);
      var x = 0.0;

      for (var c = 0; c < colCount; c++) {
        final cellWidth = availableWidth * row.cells[c] / cellFlexTotal;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cellWidth, rowHeight),
            const Radius.circular(1.5),
          ),
          cellPaint,
        );
        x += cellWidth + gap;
      }

      y += rowHeight + gap;
    }
  }

  void _paintDump(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.cream);
    final maxWidth = size.width * 0.72;
    final maxHeight = size.height * 0.82;
    final width = maxWidth < maxHeight / 1.22 ? maxWidth : maxHeight / 1.22;
    final height = width * 1.22;
    final polaroid = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: height,
    );
    canvas.drawRect(polaroid, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTRB(
        polaroid.left + width * 0.08,
        polaroid.top + width * 0.08,
        polaroid.right - width * 0.08,
        polaroid.bottom - height * 0.22,
      ),
      Paint()..color = cellColor,
    );
  }

  void _paintBooth(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.cream);
    final width = size.shortestSide * 0.38;
    final height = width * 2.55;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.04);
    final strip = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
    canvas.drawRect(strip, Paint()..color = Colors.white);

    final insetX = width * 0.10;
    final top = -height / 2 + width * 0.10;
    final bottom = height / 2 - width * 0.28;
    final cellGap = width * 0.06;
    final cellHeight = (bottom - top - cellGap * 2) / 3;
    final cellPaint = Paint()..color = cellColor;

    for (var i = 0; i < 3; i++) {
      final y = top + i * (cellHeight + cellGap);
      canvas.drawRect(
        Rect.fromLTRB(-width / 2 + insetX, y, width / 2 - insetX, y + cellHeight),
        cellPaint,
      );
    }
    canvas.restore();
  }

  void _paintFilmStrip(Canvas canvas, Size size, bool horizontal) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.cream);
    final filmPaint = Paint()..color = const Color(0xFF1A1A1A);
    final holePaint = Paint()..color = const Color(0xFFE8E4DC);
    final cellPaint = Paint()..color = cellColor;

    late Rect strip;
    if (horizontal) {
      final height = size.height * 0.34;
      final width = math.min(size.width * 0.90, height * 3.2);
      strip = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: width,
        height: height,
      );
    } else {
      final width = size.width * 0.34;
      final height = math.min(size.height * 0.90, width * 3.2);
      strip = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: width,
        height: height,
      );
    }

    canvas.save();
    canvas.translate(strip.center.dx, strip.center.dy);
    canvas.rotate(horizontal ? -0.03 : 0.035);
    final local = Rect.fromCenter(
      center: Offset.zero,
      width: strip.width,
      height: strip.height,
    );
    canvas.drawRect(local, filmPaint);

    final holeCount = 8;
    if (horizontal) {
      final band = local.height * 0.16;
      final holeW = local.height * 0.055;
      final holeH = local.height * 0.07;
      final spacing = local.width / (holeCount + 1);
      for (var i = 1; i <= holeCount; i++) {
        final x = local.left + spacing * i;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, local.top + band / 2),
              width: holeW,
              height: holeH,
            ),
            const Radius.circular(0.6),
          ),
          holePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, local.bottom - band / 2),
              width: holeW,
              height: holeH,
            ),
            const Radius.circular(0.6),
          ),
          holePaint,
        );
      }
      final insetY = local.height * 0.20;
      final insetX = local.width * 0.05;
      final gap = local.width * 0.025;
      final cellW = (local.width - insetX * 2 - gap * 3) / 4;
      final cellH = local.height - insetY * 2;
      for (var i = 0; i < 4; i++) {
        final x = local.left + insetX + i * (cellW + gap);
        canvas.drawRect(
          Rect.fromLTWH(x, local.top + insetY, cellW, cellH),
          cellPaint,
        );
      }
    } else {
      final band = local.width * 0.16;
      final holeW = local.width * 0.07;
      final holeH = local.width * 0.055;
      final spacing = local.height / (holeCount + 1);
      for (var i = 1; i <= holeCount; i++) {
        final y = local.top + spacing * i;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(local.left + band / 2, y),
              width: holeW,
              height: holeH,
            ),
            const Radius.circular(0.6),
          ),
          holePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(local.right - band / 2, y),
              width: holeW,
              height: holeH,
            ),
            const Radius.circular(0.6),
          ),
          holePaint,
        );
      }
      final insetX = local.width * 0.20;
      final insetY = local.height * 0.05;
      final gap = local.height * 0.025;
      final cellW = local.width - insetX * 2;
      final cellH = (local.height - insetY * 2 - gap * 3) / 4;
      for (var i = 0; i < 4; i++) {
        final y = local.top + insetY + i * (cellH + gap);
        canvas.drawRect(
          Rect.fromLTWH(local.left + insetX, y, cellW, cellH),
          cellPaint,
        );
      }
    }
    canvas.restore();
  }

  void _paintReaction(Canvas canvas, Size size) {
    final cellPaint = Paint()..color = cellColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(1.5)),
      cellPaint,
    );

    final inset = size.shortestSide * 0.30;
    final margin = size.shortestSide * 0.06;
    final radius = inset * 0.18;
    final rect = Rect.fromLTWH(
      size.width - margin - inset,
      size.height - margin - inset,
      inset,
      inset,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = gapColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(1.2),
        Radius.circular(radius * 0.85),
      ),
      cellPaint,
    );
  }

  void _paintOverlayFrame(Canvas canvas, Size size) {
    final cellPaint = Paint()..color = cellColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(1.5)),
      cellPaint,
    );

    final frameWidth = size.width * 0.62;
    final frameHeight = size.height * 0.68;
    final frame = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.52),
      width: frameWidth,
      height: frameHeight,
    );
    final border = size.shortestSide * 0.045;

    canvas.drawRect(frame, Paint()..color = Colors.white);
    canvas.drawRect(
      frame.deflate(border),
      Paint()..color = gapColor,
    );
    canvas.drawRect(
      frame.deflate(border * 1.35),
      cellPaint,
    );
  }

  void _paintAlbumGrid(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.cream);

    final cellPaint = Paint()..color = cellColor;
    const columns = 3;
    const rows = 4;

    final gridWidth = size.width * 0.78;
    final gridHeight = size.height * 0.82;
    final gap = math.min(size.width, size.height) * 0.042;

    final cellSize = math.min(
      (gridWidth - gap * (columns - 1)) / columns,
      (gridHeight - gap * (rows - 1)) / rows,
    );
    final contentWidth = cellSize * columns + gap * (columns - 1);
    final contentHeight = cellSize * rows + gap * (rows - 1);
    final origin = Offset(
      (size.width - contentWidth) / 2,
      (size.height - contentHeight) / 2,
    );

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final left = origin.dx + col * (cellSize + gap);
        final top = origin.dy + row * (cellSize + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, cellSize, cellSize),
            const Radius.circular(1),
          ),
          cellPaint,
        );
      }
    }
  }

  void _paintStripGrid(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final cellPaint = Paint()..color = cellColor;
    const columns = StripGridLayout.columns;
    const rows = StripGridLayout.rows;

    final pad = StripGridLayout.verticalPadding(size.height);
    final gap = StripGridLayout.rowGap(size.height);
    final rowHeight = (size.height - pad * 2 - gap * (rows - 1)) / rows;
    final cellWidth = size.width / columns;

    for (var row = 0; row < rows; row++) {
      final top = pad + row * (rowHeight + gap);
      for (var col = 0; col < columns; col++) {
        final left = col * cellWidth;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, cellWidth, rowHeight),
            const Radius.circular(1),
          ),
          cellPaint,
        );
      }
    }
  }

  void _paintStaggerGrid(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final cellPaint = Paint()..color = cellColor;
    final metrics = StaggerGridLayout.metrics(size.width, size.height);

    for (var i = 0; i < StaggerGridLayout.slotCount; i++) {
      final rect = metrics.slotRect(i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        cellPaint,
      );
    }
  }

  void _paintLayerCollage(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final cellPaint = Paint()..color = cellColor;
    final placed = LayerCollageLayout.placements(size.width, size.height);
    final border = LayerCollageLayout.borderWidth(size.width, size.height);

    for (final slot in placed) {
      final inner = slot.rect.deflate(border);
      canvas.drawRect(inner, cellPaint);
      canvas.drawRect(
        inner,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = border,
      );
    }
  }

  void _paintHeartGrid(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final cellPaint = Paint()..color = cellColor;
    const columns = HeartGridLayout.columns;
    const rows = HeartGridLayout.rows;
    final gap = HeartGridLayout.gapForSize(size.width, size.height);
    final inset = HeartGridLayout.heartInset(size.width, size.height);
    final heartSize = HeartGridLayout.heartSize(size.width, size.height);

    final cellWidth = (size.width - gap * (columns - 1)) / columns;
    final cellHeight = (size.height - gap * (rows - 1)) / rows;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final left = col * (cellWidth + gap);
        final top = row * (cellHeight + gap);
        canvas.drawRect(
          Rect.fromLTWH(left, top, cellWidth, cellHeight),
          cellPaint,
        );

        if (!HeartGridLayout.showHeart(row, col)) continue;

        final heartCenter = Offset(
          left + inset + heartSize / 2,
          top + cellHeight - inset - heartSize / 2,
        );
        _paintHeartIcon(canvas, heartCenter, heartSize);
      }
    }
  }

  void _paintHeartIcon(Canvas canvas, Offset center, double size) {
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
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  void _paintCheckerGrid(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final cellPaint = Paint()..color = cellColor;
    final textPaint = Paint()..color = Colors.white;
    const columns = 3;
    const rows = 3;

    final gap = CheckerGridLayout.gapForSize(size.width, size.height);
    final cellWidth = (size.width - gap * (columns - 1)) / columns;
    final cellHeight = (size.height - gap * (rows - 1)) / rows;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final flatIndex = row * columns + col;
        final left = col * (cellWidth + gap);
        final top = row * (cellHeight + gap);
        final rect = Rect.fromLTWH(left, top, cellWidth, cellHeight);
        final isText =
            flatIndex == 1 || flatIndex == 3 || flatIndex == 5 || flatIndex == 7;
        canvas.drawRect(rect, isText ? textPaint : cellPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LayoutOutlinePainter oldDelegate) {
    return oldDelegate.layout.id != layout.id ||
        oldDelegate.cellColor != cellColor ||
        oldDelegate.gapColor != gapColor;
  }
}
