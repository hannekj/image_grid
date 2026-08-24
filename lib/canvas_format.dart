import 'package:flutter/material.dart';

import 'editor_chrome.dart';

class CanvasFormat {
  const CanvasFormat({
    required this.id,
    required this.label,
    required this.caption,
    required this.width,
    required this.height,
  });

  final String id;
  final String label;
  final String caption;
  final double width;
  final double height;

  double get aspectRatio => width / height;
}

const canvasFormats = [
  CanvasFormat(
    id: 'portrait',
    label: '4:5',
    caption: 'Innlegg',
    width: 1080,
    height: 1350,
  ),
  CanvasFormat(
    id: 'square',
    label: '1:1',
    caption: 'Kvadrat',
    width: 1080,
    height: 1080,
  ),
  CanvasFormat(
    id: 'story',
    label: '9:16',
    caption: 'Story',
    width: 1080,
    height: 1920,
  ),
];

class FormatChips extends StatelessWidget {
  const FormatChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final CanvasFormat selected;
  final ValueChanged<CanvasFormat> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: EditorChrome.panelHeight,
      child: Align(
        alignment: Alignment.center,
        child: Row(
          children: [
            for (final format in canvasFormats) ...[
              if (format != canvasFormats.first)
                const SizedBox(width: EditorChrome.spaceSm),
              Expanded(
                child: EditorChoiceTile(
                  label: format.label,
                  caption: format.caption,
                  selected: format.id == selected.id,
                  compact: compact,
                  onTap: () => onChanged(format),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
