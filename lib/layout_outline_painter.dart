import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'grid_layout.dart';

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

    if (layout.isReaction) {
      _paintReaction(canvas, size);
      return;
    }

    if (layout.isOverlayFrame) {
      _paintOverlayFrame(canvas, size);
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

  @override
  bool shouldRepaint(covariant LayoutOutlinePainter oldDelegate) {
    return oldDelegate.layout.id != layout.id ||
        oldDelegate.cellColor != cellColor ||
        oldDelegate.gapColor != gapColor;
  }
}
