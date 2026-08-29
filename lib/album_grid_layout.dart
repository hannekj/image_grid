import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Instagram-style 3×4 photo grid: small square cells, wide gutters, thick outer frame.
class AlbumGridFrame extends StatelessWidget {
  const AlbumGridFrame({
    super.key,
    required this.slots,
    this.columns = 3,
    this.rows = 4,
  });

  static const slotCount = 12;

  final List<Widget> slots;
  final int columns;
  final int rows;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == columns * rows);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final gridWidth = width * 0.78;
        final gridHeight = height * 0.82;
        final gap = math.min(width, height) * 0.042;

        final cellSize = math.min(
          (gridWidth - gap * (columns - 1)) / columns,
          (gridHeight - gap * (rows - 1)) / rows,
        );
        final contentWidth = cellSize * columns + gap * (columns - 1);
        final contentHeight = cellSize * rows + gap * (rows - 1);

        return Center(
          child: SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: Column(
              children: [
                for (var row = 0; row < rows; row++) ...[
                  if (row > 0) SizedBox(height: gap),
                  SizedBox(
                    height: cellSize,
                    child: Row(
                      children: [
                        for (var col = 0; col < columns; col++) ...[
                          if (col > 0) SizedBox(width: gap),
                          SizedBox(
                            width: cellSize,
                            height: cellSize,
                            child: slots[row * columns + col],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
