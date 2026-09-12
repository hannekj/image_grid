import 'package:flutter/material.dart';

import 'color_scrub_strip.dart';
import 'editor_chrome.dart';
import 'frame_style.dart';

/// Turning the frame on and choosing its width is one decision for the user,
/// so it is one row of options with "Ingen" as the off state.
class FrameWeightControls extends StatelessWidget {
  const FrameWeightControls({
    super.key,
    required this.kind,
    required this.thickness,
    required this.onKindChanged,
    required this.onThicknessChanged,
  });

  final FrameKind kind;
  final StrokeThickness thickness;
  final ValueChanged<FrameKind> onKindChanged;
  final ValueChanged<StrokeThickness> onThicknessChanged;

  @override
  Widget build(BuildContext context) {
    final hasFrame = kind == FrameKind.stroke;

    return Row(
      children: [
        Expanded(
          child: EditorChoiceTile(
            label: 'Ingen',
            selected: !hasFrame,
            compact: true,
            onTap: () => onKindChanged(FrameKind.none),
          ),
        ),
        for (final option in strokeThicknesses) ...[
          const SizedBox(width: EditorChrome.spaceSm),
          Expanded(
            child: EditorChoiceTile(
              label: option.label,
              selected: hasFrame && option.width == thickness.width,
              compact: true,
              onTap: () {
                onThicknessChanged(option);
                if (!hasFrame) onKindChanged(FrameKind.stroke);
              },
            ),
          ),
        ],
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

