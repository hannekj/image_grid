import 'package:flutter/material.dart';

/// Three horizontal photo strips (3×3) with wide vertical gutters, edge to edge.
class StripGridLayout {
  StripGridLayout._();

  static const slotCount = 9;
  static const columns = 3;
  static const rows = 3;

  static double verticalPadding(double height) => height * 0.06;

  static double rowGap(double height) => height * 0.11;
}

class StripGridFrame extends StatelessWidget {
  const StripGridFrame({
    super.key,
    required this.slots,
  });

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == StripGridLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pad = StripGridLayout.verticalPadding(height);
        final gap = StripGridLayout.rowGap(height);
        final rowHeight =
            (height - pad * 2 - gap * (StripGridLayout.rows - 1)) /
                StripGridLayout.rows;

        return SizedBox(
          width: width,
          height: height,
          child: Column(
            children: [
              SizedBox(height: pad),
              for (var row = 0; row < StripGridLayout.rows; row++) ...[
                if (row > 0) SizedBox(height: gap),
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      for (var col = 0; col < StripGridLayout.columns; col++)
                        Expanded(
                          child: slots[
                              row * StripGridLayout.columns + col],
                        ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: pad),
            ],
          ),
        );
      },
    );
  }
}
