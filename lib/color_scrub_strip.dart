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
    this.swatchWidth = 30,
  });

  final List<Color> colors;
  final List<String>? labels;
  final Color selected;
  final ValueChanged<Color> onChanged;
  final double height;
  final double swatchWidth;

  @override
  State<ColorScrubStrip> createState() => _ColorScrubStripState();
}

class _ColorScrubStripState extends State<ColorScrubStrip> {
  static const _gap = 4.0;

  final _controller = ScrollController();
  int? _scrubIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _stride => widget.swatchWidth + _gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Listener(
        onPointerDown: (event) => _selectAtGlobal(event.position),
        onPointerMove: (event) {
          if (event.down) _selectAtGlobal(event.position);
        },
        onPointerUp: (_) => setState(() => _scrubIndex = null),
        onPointerCancel: (_) => setState(() => _scrubIndex = null),
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 8),
          itemCount: widget.colors.length,
          separatorBuilder: (context, index) => const SizedBox(width: _gap),
          itemBuilder: (context, index) {
            final color = widget.colors[index];
            final selected = color.toARGB32() == widget.selected.toARGB32() ||
                _scrubIndex == index;
            return SizedBox(
              width: widget.swatchWidth,
              child: _Swatch(
                color: color,
                label: widget.labels != null && index < widget.labels!.length
                    ? widget.labels![index]
                    : null,
                selected: selected,
              ),
            );
          },
        ),
      ),
    );
  }

  void _selectAtGlobal(Offset global) {
    if (widget.colors.isEmpty || !_controller.hasClients) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(global);
    final dx = local.dx + _controller.offset;
    final index = (dx / _stride).floor().clamp(0, widget.colors.length - 1);
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
