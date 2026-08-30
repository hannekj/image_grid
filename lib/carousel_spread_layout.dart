import 'package:flutter/material.dart';

/// Two-page spread: two stacked small images on one half and a panorama
/// spanning both carousel slides on the other half (mirrored on page two).
class CarouselSpreadLayout {
  const CarouselSpreadLayout({
    required this.id,
    required this.label,
    required this.smallSlotCount,
    this.hasSpanImage = false,
  });

  final String id;
  final String label;
  final int smallSlotCount;
  final bool hasSpanImage;

  int get slotCount => smallSlotCount;
}

const carouselSpreadLayouts = [
  CarouselSpreadLayout(
    id: 'spread-span',
    label: '2 små + stort',
    smallSlotCount: 2,
    hasSpanImage: true,
  ),
];

bool isCarouselSpreadStep(String? step) =>
    step != null && step.startsWith('spread-');

CarouselSpreadLayout carouselSpreadLayout(String layoutId) {
  return carouselSpreadLayouts.firstWhere(
    (layout) => layout.id == layoutId,
    orElse: () => carouselSpreadLayouts.first,
  );
}

/// Page 0: small slots on the left, span panel on the right.
/// Page 1: span panel on the left, small slots on the right (mirror).
class SpreadSpanFrame extends StatelessWidget {
  const SpreadSpanFrame({
    super.key,
    required this.pageIndex,
    required this.gap,
    required this.smallSlotBuilder,
    required this.spanBuilder,
  });

  final int pageIndex;
  final double gap;
  final Widget Function(int slotIndex) smallSlotBuilder;
  final Widget Function(double panelWidth, double panelHeight) spanBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final halfWidth = width / 2;
        final rowGap = gap;
        final rowHeight = (height - rowGap) / 2;
        final smallOnLeft = pageIndex == 0;

        final smallColumn = SizedBox(
          width: halfWidth,
          height: height,
          child: Column(
            children: [
              SizedBox(height: rowHeight, child: smallSlotBuilder(0)),
              SizedBox(height: rowGap),
              SizedBox(height: rowHeight, child: smallSlotBuilder(1)),
            ],
          ),
        );

        final spanColumn = SizedBox(
          width: halfWidth,
          height: height,
          child: spanBuilder(halfWidth, height),
        );

        return Row(
          children: [
            if (smallOnLeft) smallColumn else spanColumn,
            if (smallOnLeft) spanColumn else smallColumn,
          ],
        );
      },
    );
  }
}
