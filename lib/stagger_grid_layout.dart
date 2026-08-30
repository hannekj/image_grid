import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Two staggered columns of portrait photos — four slots, wide outer margin.
class StaggerGridLayout {
  StaggerGridLayout._();

  static const slotCount = 4;

  /// Width divided by height for each cell.
  static const portraitAspect = 3 / 4;

  static double outerPadding(double width, double height) =>
      math.min(width, height) * 0.085;

  static double gap(double width, double height) =>
      math.min(width, height) * 0.028;

  static StaggerMetrics metrics(double width, double height) {
    final pad = outerPadding(width, height);
    final gutter = gap(width, height);
    final availW = width - pad * 2;
    final availH = height - pad * 2;

    var cellW = (availW - gutter) / 2;
    var cellH = cellW / portraitAspect;

    var contentH = cellH * 2.5 + gutter;
    if (contentH > availH) {
      cellH = (availH - gutter) / 2.5;
      cellW = cellH * portraitAspect;
      contentH = cellH * 2.5 + gutter;
    }

    var contentW = cellW * 2 + gutter;
    if (contentW > availW) {
      cellW = (availW - gutter) / 2;
      cellH = cellW / portraitAspect;
      contentW = cellW * 2 + gutter;
      contentH = cellH * 2.5 + gutter;
      if (contentH > availH) {
        cellH = (availH - gutter) / 2.5;
        cellW = cellH * portraitAspect;
        contentW = cellW * 2 + gutter;
        contentH = cellH * 2.5 + gutter;
      }
    }

    final originX = (width - contentW) / 2;
    final originY = (height - contentH) / 2;

    return StaggerMetrics(
      cellWidth: cellW,
      cellHeight: cellH,
      gap: gutter,
      originX: originX,
      originY: originY,
    );
  }
}

class StaggerMetrics {
  const StaggerMetrics({
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
    required this.originX,
    required this.originY,
  });

  final double cellWidth;
  final double cellHeight;
  final double gap;
  final double originX;
  final double originY;

  Rect slotRect(int index) {
    final w = cellWidth;
    final h = cellHeight;
    final g = gap;
    final x0 = originX;
    final y0 = originY;
    final x1 = originX + w + g;
    final half = h / 2;

    return switch (index) {
      0 => Rect.fromLTWH(x0, y0, w, h),
      1 => Rect.fromLTWH(x0, y0 + h + g, w, h),
      2 => Rect.fromLTWH(x1, y0 + half, w, h),
      3 => Rect.fromLTWH(x1, y0 + half + h + g, w, h),
      _ => Rect.zero,
    };
  }
}

class StaggerGridFrame extends StatelessWidget {
  const StaggerGridFrame({
    super.key,
    required this.slots,
  });

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == StaggerGridLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final metrics = StaggerGridLayout.metrics(width, height);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < StaggerGridLayout.slotCount; i++)
                Positioned.fromRect(
                  rect: metrics.slotRect(i),
                  child: slots[i],
                ),
            ],
          ),
        );
      },
    );
  }
}
