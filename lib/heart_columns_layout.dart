import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'heart_grid_layout.dart';

/// Two full-height portrait columns with inward-facing corner hearts.
class HeartColumnsLayout {
  HeartColumnsLayout._();

  static const slotCount = 2;
  static const columns = 2;

  static const _designWidth = 581.0;
  static const _designHeight = 1024.0;
  static const _designGap = 6.0;

  static HeartColumnsMetrics metrics(double width, double height) {
    final scale = math.min(width / _designWidth, height / _designHeight);
    final gap = math.max(1.0, _designGap * scale);
    final cellWidth = (width - gap * (columns - 1)) / columns;
    return HeartColumnsMetrics(
      gap: gap,
      cellWidth: cellWidth,
      cellHeight: height,
    );
  }
}

class HeartColumnsMetrics {
  const HeartColumnsMetrics({
    required this.gap,
    required this.cellWidth,
    required this.cellHeight,
  });

  final double gap;
  final double cellWidth;
  final double cellHeight;

  bool get _compactThumb => cellWidth < 48;

  /// Larger than the 2×2 heart grids (~9.5% of cell width).
  double get heartSize {
    if (_compactThumb) {
      return math.min(cellHeight * 0.28, cellWidth * 0.46).clamp(4.0, 11.0);
    }
    return cellWidth * 0.135;
  }

  double get heartInset {
    if (_compactThumb) {
      return (cellWidth * 0.1).clamp(1.0, 3.0);
    }
    return math.max(1.0, cellWidth * 0.07);
  }

  Rect cellRect(int col) {
    final left = col * (cellWidth + gap);
    return Rect.fromLTWH(left, 0, cellWidth, cellHeight);
  }

  Offset heartCenter(int col) {
    final rect = cellRect(col);
    final size = heartSize;
    final inset = heartInset;
    final centerY = rect.bottom - inset - size / 2;
    final centerX = col == 0
        ? rect.right - inset - size / 2
        : rect.left + inset + size / 2;
    return Offset(centerX, centerY);
  }
}

class HeartColumnsFrame extends StatelessWidget {
  const HeartColumnsFrame({
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
    assert(slots.length == HeartColumnsLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final layout = HeartColumnsLayout.metrics(width, height);
        final heartSize = layout.heartSize;
        final inset = layout.heartInset;

        Widget cell(int index, int col) {
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              slots[index],
              if (showHearts)
                Positioned(
                  left: col == 0 ? null : inset,
                  right: col == 0 ? inset : null,
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
        }

        return ColoredBox(
          color: Colors.white,
          child: Row(
            children: [
              for (var col = 0; col < HeartColumnsLayout.columns; col++) ...[
                if (col > 0) SizedBox(width: layout.gap),
                Expanded(child: cell(col, col)),
              ],
            ],
          ),
        );
      },
    );
  }
}
