import 'package:flutter/material.dart';

import 'frame_style.dart';

class FrameControls extends StatelessWidget {
  const FrameControls({
    super.key,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.onKindChanged,
    required this.onColorChanged,
    required this.onThicknessChanged,
  });

  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final ValueChanged<FrameKind> onKindChanged;
  final ValueChanged<StrokeColor> onColorChanged;
  final ValueChanged<StrokeThickness> onThicknessChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'Ingen ramme',
                selected: kind == FrameKind.none,
                onTap: () => onKindChanged(FrameKind.none),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChoiceChip(
                label: 'Ramme',
                selected: kind == FrameKind.stroke,
                onTap: () => onKindChanged(FrameKind.stroke),
              ),
            ),
          ],
        ),
        if (kind == FrameKind.stroke) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 30,
            child: Row(
              children: [
                for (var i = 0; i < strokeColors.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: _ColorSwatch(
                      option: strokeColors[i],
                      selected: strokeColors[i].color.toARGB32() ==
                          color.color.toARGB32(),
                      onTap: () => onColorChanged(strokeColors[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final option in strokeThicknesses) ...[
                if (option != strokeThicknesses.first) const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceChip(
                    label: option.label,
                    selected: option.width == thickness.width,
                    onTap: () => onThicknessChanged(option),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: selected ? Colors.black : const Color(0xFFCCCCCC),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StrokeColor option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = option.color.computeLuminance() > 0.82;

    return Semantics(
      button: true,
      label: option.label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: option.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2C3028)
                  : isLight
                  ? const Color(0xFFCCCCCC)
                  : option.color,
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
