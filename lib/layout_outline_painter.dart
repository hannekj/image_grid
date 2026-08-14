import 'package:flutter/material.dart';

import 'grid_layout.dart';

class LayoutOutlinePainter extends CustomPainter {
  const LayoutOutlinePainter({required this.layout});

  final GridLayout layout;

  static const _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    final inset = _stroke / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - _stroke,
      size.height - _stroke,
    );
    canvas.drawRect(rect, paint);

    final rowFlexTotal = layout.rowFlexTotal;
    var y = inset;

    for (var r = 0; r < layout.rows.length; r++) {
      final row = layout.rows[r];
      final rowHeight = rect.height * row.flex / rowFlexTotal;
      final nextY = y + rowHeight;

      if (r < layout.rows.length - 1) {
        canvas.drawLine(
          Offset(inset, nextY),
          Offset(size.width - inset, nextY),
          paint,
        );
      }

      var cellFlexTotal = 0;
      for (final cell in row.cells) {
        cellFlexTotal += cell;
      }

      var x = inset;
      for (var c = 0; c < row.cells.length - 1; c++) {
        x += rect.width * row.cells[c] / cellFlexTotal;
        canvas.drawLine(Offset(x, y), Offset(x, nextY), paint);
      }

      y = nextY;
    }
  }

  @override
  bool shouldRepaint(covariant LayoutOutlinePainter oldDelegate) {
    return oldDelegate.layout.id != layout.id;
  }
}
