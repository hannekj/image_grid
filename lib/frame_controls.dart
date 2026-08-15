import 'package:flutter/material.dart';

import 'color_scrub_strip.dart';
import 'frame_style.dart';

class FrameKindControls extends StatelessWidget {
  const FrameKindControls({
    super.key,
    required this.kind,
    required this.onKindChanged,
  });

  final FrameKind kind;
  final ValueChanged<FrameKind> onKindChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FrameChoiceChip(
            label: 'Ingen ramme',
            selected: kind == FrameKind.none,
            onTap: () => onKindChanged(FrameKind.none),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FrameChoiceChip(
            label: 'Ramme',
            selected: kind == FrameKind.stroke,
            onTap: () => onKindChanged(FrameKind.stroke),
          ),
        ),
      ],
    );
  }
}

class FrameColorControls extends StatelessWidget {
  const FrameColorControls({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  final StrokeColor color;
  final ValueChanged<StrokeColor> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return ColorScrubStrip(
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
    );
  }
}

class FrameThicknessControls extends StatelessWidget {
  const FrameThicknessControls({
    super.key,
    required this.thickness,
    required this.onThicknessChanged,
  });

  final StrokeThickness thickness;
  final ValueChanged<StrokeThickness> onThicknessChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in strokeThicknesses) ...[
          if (option != strokeThicknesses.first) const SizedBox(width: 8),
          Expanded(
            child: FrameChoiceChip(
              label: option.label,
              selected: option.width == thickness.width,
              onTap: () => onThicknessChanged(option),
            ),
          ),
        ],
      ],
    );
  }
}

class FrameChoiceChip extends StatelessWidget {
  const FrameChoiceChip({
    super.key,
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
