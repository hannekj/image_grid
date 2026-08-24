import 'package:flutter/material.dart';

import 'color_scrub_strip.dart';
import 'editor_chrome.dart';
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
          child: EditorChoiceTile(
            label: 'Ingen ramme',
            selected: kind == FrameKind.none,
            compact: true,
            onTap: () => onKindChanged(FrameKind.none),
          ),
        ),
        const SizedBox(width: EditorChrome.spaceSm),
        Expanded(
          child: EditorChoiceTile(
            label: 'Ramme',
            selected: kind == FrameKind.stroke,
            compact: true,
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
          if (option != strokeThicknesses.first)
            const SizedBox(width: EditorChrome.spaceSm),
          Expanded(
            child: EditorChoiceTile(
              label: option.label,
              selected: option.width == thickness.width,
              compact: true,
              onTap: () => onThicknessChanged(option),
            ),
          ),
        ],
      ],
    );
  }
}
