import 'package:flutter/material.dart';

import 'canvas_format.dart';
import 'grid_layout.dart';
import 'layout_outline_painter.dart';

class LayoutStrip extends StatelessWidget {
  const LayoutStrip({
    super.key,
    required this.format,
    required this.selectedLayoutId,
    required this.onLayoutSelected,
  });

  final CanvasFormat format;
  final String selectedLayoutId;
  final ValueChanged<GridLayout> onLayoutSelected;

  static const thumbHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final layout in gridLayouts) ...[
            if (layout != gridLayouts.first) const SizedBox(width: 10),
            _LayoutThumb(
              layout: layout,
              format: format,
              selected: layout.id == selectedLayoutId,
              onTap: () => onLayoutSelected(layout),
            ),
          ],
        ],
      ),
    );
  }
}

class _LayoutThumb extends StatelessWidget {
  const _LayoutThumb({
    required this.layout,
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final GridLayout layout;
  final CanvasFormat format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = LayoutStrip.thumbHeight * format.aspectRatio;

    return Tooltip(
      message: layout.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: LayoutStrip.thumbHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? Colors.black : const Color(0xFFD5D5D0),
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: LayoutOutlinePainter(layout: layout),
          ),
        ),
      ),
    );
  }
}
