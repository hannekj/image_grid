import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorScrubStrip extends StatefulWidget {
  const ColorScrubStrip({
    super.key,
    required this.colors,
    required this.selected,
    required this.onChanged,
    this.labels,
    this.height = 32,
  });

  final List<Color> colors;
  final List<String>? labels;
  final Color selected;
  final ValueChanged<Color> onChanged;
  final double height;

  @override
  State<ColorScrubStrip> createState() => _ColorScrubStripState();
}

class _ColorScrubStripState extends State<ColorScrubStrip> {
  static const _gap = 3.0;

  int? _scrubIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _selectAt(details.localPosition.dx, constraints.maxWidth),
            onHorizontalDragStart: (details) {
              _selectAt(details.localPosition.dx, constraints.maxWidth);
            },
            onHorizontalDragUpdate: (details) {
              _selectAt(details.localPosition.dx, constraints.maxWidth);
            },
            onHorizontalDragEnd: (_) => setState(() => _scrubIndex = null),
            onHorizontalDragCancel: () => setState(() => _scrubIndex = null),
            child: Row(
              children: [
                for (var i = 0; i < widget.colors.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: _Swatch(
                      color: widget.colors[i],
                      label: widget.labels != null && i < widget.labels!.length
                          ? widget.labels![i]
                          : null,
                      selected: widget.colors[i].toARGB32() ==
                              widget.selected.toARGB32() ||
                          _scrubIndex == i,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectAt(double dx, double width) {
    if (widget.colors.isEmpty || width <= 0) return;
    final index = (dx / width * widget.colors.length)
        .floor()
        .clamp(0, widget.colors.length - 1);
    final color = widget.colors[index];
    final changed = color.toARGB32() != widget.selected.toARGB32();

    if (_scrubIndex != index) {
      setState(() => _scrubIndex = index);
      if (changed) HapticFeedback.selectionClick();
    }
    if (changed) widget.onChanged(color);
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    this.label,
  });

  final Color color;
  final String? label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isLight = color.computeLuminance() > 0.82;

    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected
                ? const Color(0xFF2C3028)
                : isLight
                ? const Color(0xFFCCCCCC)
                : color,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
