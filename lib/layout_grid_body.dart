import 'package:flutter/material.dart';

import 'grid_layout.dart';

/// Classic row/column grid body shared by collage and carousel grid slides.
class LayoutGridBody extends StatelessWidget {
  const LayoutGridBody({
    super.key,
    required this.layout,
    required this.gap,
    required this.slotBuilder,
  });

  final GridLayout layout;
  final double gap;
  final Widget Function(int index) slotBuilder;

  @override
  Widget build(BuildContext context) {
    var index = 0;
    final rows = <Widget>[];

    for (var r = 0; r < layout.rows.length; r++) {
      final row = layout.rows[r];
      if (r > 0) rows.add(SizedBox(height: gap));

      final cells = <Widget>[];
      for (var c = 0; c < row.cells.length; c++) {
        if (c > 0) cells.add(SizedBox(width: gap));
        final slotIndex = index;
        index += 1;
        cells.add(
          Expanded(
            flex: row.cells[c],
            child: slotBuilder(slotIndex),
          ),
        );
      }

      rows.add(
        Expanded(
          flex: row.flex,
          child: Row(children: cells),
        ),
      );
    }

    return Column(children: rows);
  }
}
