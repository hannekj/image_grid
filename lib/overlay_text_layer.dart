import 'package:flutter/material.dart';

import 'overlay_text.dart';

class OverlayTextLayer extends StatelessWidget {
  const OverlayTextLayer({
    super.key,
    required this.overlay,
    required this.onAlignmentChanged,
    required this.onEdit,
    this.interactive = true,
  });

  final OverlayText overlay;
  final ValueChanged<Alignment> onAlignmentChanged;
  final VoidCallback onEdit;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: overlay.alignment,
          child: GestureDetector(
            onTap: interactive ? onEdit : null,
            onPanUpdate: interactive
                ? (details) {
                    final next = Alignment(
                      (overlay.alignment.x +
                              details.delta.dx / (constraints.maxWidth / 2))
                          .clamp(-1.0, 1.0),
                      (overlay.alignment.y +
                              details.delta.dy / (constraints.maxHeight / 2))
                          .clamp(-1.0, 1.0),
                    );
                    onAlignmentChanged(next);
                  }
                : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.86,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: overlay.plate
                      ? (overlay.color.computeLuminance() > 0.5
                            ? const Color(0x99000000)
                            : const Color(0x99FFFFFF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: interactive
                      ? Border.all(color: const Color(0x66FFFFFF))
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    overlay.value,
                    textAlign: TextAlign.center,
                    style: overlayFontById(overlay.fontId).style(
                      color: overlay.color,
                      fontSize: overlay.fontSize,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
