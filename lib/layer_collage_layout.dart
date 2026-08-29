import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Six overlapping portrait tiles — layered collage with white gutters.
///
/// Slot bounds measured from the reference mockup (580×1024).
class LayerCollageLayout {
  LayerCollageLayout._();

  static const slotCount = 6;

  static const _designWidth = 580.0;
  static const _designHeight = 1024.0;

  /// Gray photo areas from the reference image, ordered for z-index rendering.
  static const _slots = [
    _SlotSpec(index: 0, z: 0, x: 33, y: 76, w: 254, h: 304), // top-left
    _SlotSpec(index: 1, z: 1, x: 292, y: 24, w: 245, h: 247), // top-right
    _SlotSpec(index: 2, z: 2, x: 57, y: 385, w: 284, h: 415), // mid-left
    _SlotSpec(index: 3, z: 3, x: 238, y: 577, w: 308, h: 391), // right
    _SlotSpec(index: 4, z: 4, x: 43, y: 805, w: 190, h: 197), // bottom-left
    _SlotSpec(index: 5, z: 5, x: 238, y: 277, w: 254, h: 323), // center (front)
  ];

  static double _scaleFor(double width, double height) => math.min(
        width / _designWidth,
        height / _designHeight,
      );

  static double borderWidth(double width, double height) =>
      math.max(1.5, 5 * _scaleFor(width, height));

  static List<_PlacedSlot> placements(double width, double height) {
    final scale = _scaleFor(width, height);
    final offsetX = (width - _designWidth * scale) / 2;
    final offsetY = (height - _designHeight * scale) / 2;

    final specs = [..._slots]..sort((a, b) => a.z.compareTo(b.z));

    return [
      for (final spec in specs)
        _PlacedSlot(
          index: spec.index,
          rect: Rect.fromLTWH(
            offsetX + spec.x * scale,
            offsetY + spec.y * scale,
            spec.w * scale,
            spec.h * scale,
          ),
        ),
    ];
  }
}

class _SlotSpec {
  const _SlotSpec({
    required this.index,
    required this.z,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final int index;
  final int z;
  final double x;
  final double y;
  final double w;
  final double h;
}

class _PlacedSlot {
  const _PlacedSlot({
    required this.index,
    required this.rect,
  });

  final int index;
  final Rect rect;
}

class LayerCollageFrame extends StatelessWidget {
  const LayerCollageFrame({
    super.key,
    required this.slots,
  });

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == LayerCollageLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final placed = LayerCollageLayout.placements(width, height);
        final border = LayerCollageLayout.borderWidth(width, height);

        return ColoredBox(
          color: Colors.white,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final slot in placed)
                  Positioned.fromRect(
                    rect: slot.rect.inflate(border),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(border),
                        child: ClipRect(child: slots[slot.index]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
