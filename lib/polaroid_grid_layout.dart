import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dump_layout.dart';

/// Six Polaroid frames in a 2×3 grid on a cream canvas.
class PolaroidGridLayout {
  PolaroidGridLayout._();

  static const slotCount = 6;
  static const columns = 2;
  static const rows = 3;
  static const defaultLabel = 'Polaroid 2×3';

  /// Outer frame aspect (width : height), matching single [PolaroidFrame].
  static const frameAspect = 1.22;

  /// Warm grey paper — closer to instant film stock than pure white.
  static const paperColor = Color(0xFFE4E2DC);
}

class PolaroidGridFrame extends StatelessWidget {
  const PolaroidGridFrame({
    super.key,
    required this.slots,
  });

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == PolaroidGridLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        // Room between prints; outer margin stays tight so the set still fills.
        final gap = math.min(width, height) * 0.042;
        final padX = width * 0.032;
        final padY = height * 0.028;

        final availW = width - padX * 2;
        final availH = height - padY * 2;

        final byWidth = (availW - gap * (PolaroidGridLayout.columns - 1)) /
            PolaroidGridLayout.columns;
        final byHeight = (availH - gap * (PolaroidGridLayout.rows - 1)) /
            PolaroidGridLayout.rows /
            PolaroidGridLayout.frameAspect;
        final frameW = math.min(byWidth, byHeight);
        final frameH = frameW * PolaroidGridLayout.frameAspect;

        final contentW = frameW * PolaroidGridLayout.columns +
            gap * (PolaroidGridLayout.columns - 1);
        final contentH = frameH * PolaroidGridLayout.rows +
            gap * (PolaroidGridLayout.rows - 1);

        final edge = frameW * 0.048;
        final bottom = frameH * 0.2;

        return Center(
          child: SizedBox(
            width: contentW,
            height: contentH,
            child: Column(
              children: [
                for (var row = 0; row < PolaroidGridLayout.rows; row++) ...[
                  if (row > 0) SizedBox(height: gap),
                  SizedBox(
                    height: frameH,
                    child: Row(
                      children: [
                        for (var col = 0;
                            col < PolaroidGridLayout.columns;
                            col++) ...[
                          if (col > 0) SizedBox(width: gap),
                          SizedBox(
                            width: frameW,
                            height: frameH,
                            child: PolaroidFrame(
                              paperColor: PolaroidGridLayout.paperColor,
                              textured: true,
                              padding: EdgeInsets.fromLTRB(
                                edge,
                                edge,
                                edge,
                                bottom,
                              ),
                              shadowBlur: math.max(3, frameW * 0.03),
                              shadowOffset: Offset(0, frameW * 0.015),
                              child: slots[row * PolaroidGridLayout.columns +
                                  col],
                            ),
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
