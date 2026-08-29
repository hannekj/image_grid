import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 3×3 checkerboard: five image slots and four editable text tiles, edge to edge.
class CheckerGridLayout {
  CheckerGridLayout._();

  static const slotCount = 5;
  static const labelCount = 4;

  static const defaultLabels = ['summer', 'recap', '2026', 'days'];

  /// Flat grid indices (row-major) that hold images, in slot order.
  static const imageCells = [0, 2, 4, 6, 8];

  /// Flat grid indices that hold text, in label order.
  static const textCells = [1, 3, 5, 7];

  static double gapForSize(double width, double height) => 0;
}

class CheckerGridFrame extends StatelessWidget {
  const CheckerGridFrame({
    super.key,
    required this.imageSlots,
    required this.labels,
    this.onEditLabel,
    this.showChrome = true,
  });

  final List<Widget> imageSlots;
  final List<String> labels;
  final void Function(int labelIndex)? onEditLabel;
  final bool showChrome;

  @override
  Widget build(BuildContext context) {
    assert(imageSlots.length == CheckerGridLayout.slotCount);
    assert(labels.length == CheckerGridLayout.labelCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = CheckerGridLayout.gapForSize(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        Widget cell(int flatIndex) {
          final imageSlotIndex =
              CheckerGridLayout.imageCells.indexOf(flatIndex);
          if (imageSlotIndex >= 0) {
            return imageSlots[imageSlotIndex];
          }

          final labelIndex = CheckerGridLayout.textCells.indexOf(flatIndex);
          final label = labels[labelIndex];
          final tile = ColoredBox(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                    letterSpacing: -0.2,
                    color: const Color(0xFF9A9A9A),
                  ),
                ),
              ),
            ),
          );

          if (!showChrome || onEditLabel == null) return tile;

          return Material(
            color: Colors.white,
            child: InkWell(
              onTap: () => onEditLabel!(labelIndex),
              child: tile,
            ),
          );
        }

        return Column(
          children: [
            for (var row = 0; row < 3; row++) ...[
              if (row > 0) SizedBox(height: gap),
              Expanded(
                child: Row(
                  children: [
                    for (var col = 0; col < 3; col++) ...[
                      if (col > 0) SizedBox(width: gap),
                      Expanded(child: cell(row * 3 + col)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
