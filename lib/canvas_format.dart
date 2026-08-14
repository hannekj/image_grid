import 'package:flutter/material.dart';

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
    return Row(
      children: [
        for (final format in canvasFormats) ...[
          if (format != canvasFormats.first) const SizedBox(width: 8),
          Expanded(
            child: _FormatChip(
              format: format,
              selected: format.id == selected.id,
              compact: compact,
              onTap: () => onChanged(format),
            ),
          ),
        ],
      ],
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.format,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final CanvasFormat format;
  final bool selected;
  final bool compact;
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
          child: compact
              ? Text(
                  format.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black,
                  ),
                )
              : Column(
                  children: [
                    Text(
                      format.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      format.caption,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? Colors.white70
                            : const Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
