import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 2×2 portrait grid with white gutters and checkerboard corner hearts.
class HeartGridLayout {
  HeartGridLayout._();

  static const slotCount = 4;
  static const columns = 2;
  static const rows = 2;

  static const _designWidth = 581.0;
  static const _designHeight = 1024.0;
  static const _designMargin = 5.0;
  static const _designGap = 6.0;

  static double gapForSize(double width, double height) {
    final scale = math.min(
      width / _designWidth,
      height / _designHeight,
    );
    return math.max(2.0, _designGap * scale);
  }

  static double heartInset(double width, double height) {
    final scale = math.min(
      width / _designWidth,
      height / _designHeight,
    );
    return math.max(10.0, 18 * scale);
  }

  static double heartSize(double width, double height) {
    final scale = math.min(
      width / _designWidth,
      height / _designHeight,
    );
    return math.max(14.0, 24 * scale);
  }

  static bool showHeart(int row, int col) => (row + col).isEven;
}

class HeartGridFrame extends StatelessWidget {
  const HeartGridFrame({
    super.key,
    required this.slots,
    this.showHearts = true,
  });

  final List<Widget> slots;
  final bool showHearts;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == HeartGridLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final gap = HeartGridLayout.gapForSize(width, height);
        final inset = HeartGridLayout.heartInset(width, height);
        final heartSize = HeartGridLayout.heartSize(width, height);

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
                    child: Icon(
                      Icons.favorite,
                      size: heartSize,
                      color: Colors.white,
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
                if (row > 0) SizedBox(height: gap),
                Expanded(
                  child: Row(
                    children: [
                      for (var col = 0; col < HeartGridLayout.columns; col++) ...[
                        if (col > 0) SizedBox(width: gap),
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
