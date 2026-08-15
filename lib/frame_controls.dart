import 'package:flutter/material.dart';

import 'color_scrub_strip.dart';
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
          ColorScrubStrip(
            colors: [for (final option in strokeColors) option.color],
            labels: [for (final option in strokeColors) option.label],
            selected: color.color,
            onChanged: (next) {
              final match = strokeColors.firstWhere(
                (option) => option.color.toARGB32() == next.toARGB32(),
                orElse: () => strokeColors.first,
              );
              onColorChanged(match);
            },
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
