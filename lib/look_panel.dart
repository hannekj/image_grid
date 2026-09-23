import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editor_chrome.dart';
import 'frame_controls.dart';
import 'frame_style.dart';

/// Frame weight and colour controls for the Ramme dock tool.
class FramePanel extends StatelessWidget {
  const FramePanel({
    super.key,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.onKindChanged,
    required this.onColorChanged,
    required this.onThicknessChanged,
    this.onApplyToAll,
    this.applyToAllLabel,
  });

  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final ValueChanged<FrameKind> onKindChanged;
  final ValueChanged<StrokeColor> onColorChanged;
  final ValueChanged<StrokeThickness> onThicknessChanged;
  final VoidCallback? onApplyToAll;
  final String? applyToAllLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrameWeightControls(
          kind: kind,
          thickness: thickness,
          onKindChanged: onKindChanged,
          onThicknessChanged: onThicknessChanged,
        ),
        if (kind == FrameKind.stroke) ...[
          const SizedBox(height: EditorChrome.spaceSm),
          FrameColorControls(color: color, onColorChanged: onColorChanged),
        ],
        if (onApplyToAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onApplyToAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppTheme.matcha,
              ),
              child: Text(applyToAllLabel ?? 'Bruk på alle sider'),
            ),
          ),
      ],
    );
  }
}
