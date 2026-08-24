import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'canvas_format.dart';
import 'editor_chrome.dart';
import 'grid_layout.dart';
import 'layout_outline_painter.dart';

class LayoutStrip extends StatefulWidget {
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
  State<LayoutStrip> createState() => _LayoutStripState();
}

class _LayoutStripState extends State<LayoutStrip> {
  late LayoutGroup _group = _groupForSelected();

  LayoutGroup _groupForSelected() {
    for (final layout in gridLayouts) {
      if (layout.id == widget.selectedLayoutId) return layout.group;
    }
    return LayoutGroup.classic;
  }

  @override
  void didUpdateWidget(covariant LayoutStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLayoutId != widget.selectedLayoutId) {
      final next = _groupForSelected();
      if (next != _group) _group = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final layouts = layoutsInGroup(_group);

    return SizedBox(
      height: EditorChrome.panelHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: EditorChrome.tabRowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: LayoutGroup.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: EditorChrome.spaceSm),
              itemBuilder: (context, index) {
                final group = LayoutGroup.values[index];
                return EditorSegmentTab(
                  label: group.label,
                  selected: _group == group,
                  onTap: () => setState(() => _group = group),
                );
              },
            ),
          ),
          const SizedBox(height: EditorChrome.spaceMd),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < layouts.length; i++) ...[
                    if (i > 0) const SizedBox(width: EditorChrome.spaceMd),
                    _LayoutThumb(
                      layout: layouts[i],
                      format: widget.format,
                      selected: layouts[i].id == widget.selectedLayoutId,
                      onTap: () => widget.onLayoutSelected(layouts[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
    final aspect = format.aspectRatio;
    final height = LayoutStrip.thumbHeight;
    final width = height * aspect;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.matcha : AppTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: ColoredBox(
            color: AppTheme.cream,
            child: CustomPaint(
              painter: LayoutOutlinePainter(layout: layout),
            ),
          ),
        ),
      ),
    );
  }
}
