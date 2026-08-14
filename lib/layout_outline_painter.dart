import 'package:flutter/material.dart';

import 'grid_layout.dart';

class LayoutOutlinePainter extends CustomPainter {
  const LayoutOutlinePainter({
    required this.layout,
    this.cellColor = const Color(0xFFB7B2A8),
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
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8E0D4));
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

  @override
  bool shouldRepaint(covariant LayoutOutlinePainter oldDelegate) {
    return oldDelegate.layout.id != layout.id ||
        oldDelegate.cellColor != cellColor ||
        oldDelegate.gapColor != gapColor;
  }
}
