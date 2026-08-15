import 'package:flutter/material.dart';

import 'overlay_text.dart';

class OverlayTextLayer extends StatelessWidget {
  const OverlayTextLayer({
    super.key,
    required this.overlay,
    required this.onAlignmentChanged,
    required this.onFontSizeChanged,
    required this.onEdit,
    this.interactive = true,
  });

  final OverlayText overlay;
  final ValueChanged<Alignment> onAlignmentChanged;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onEdit;
  final bool interactive;

  static const _handleSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Padding(
          padding: EdgeInsets.all(interactive ? _handleSize / 2 : 0),
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
                border: overlay.plate && interactive
                    ? Border.all(color: const Color(0x66FFFFFF), width: 1)
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: overlay.plate ? 12 : 4,
                  vertical: overlay.plate ? 8 : 2,
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
        );

        if (!interactive) {
          return Align(alignment: overlay.alignment, child: box);
        }

        return Align(
          alignment: overlay.alignment,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onEdit,
                onPanUpdate: (details) {
                  final next = Alignment(
                    (overlay.alignment.x +
                            details.delta.dx / (constraints.maxWidth / 2))
                        .clamp(-1.0, 1.0),
                    (overlay.alignment.y +
                            details.delta.dy / (constraints.maxHeight / 2))
                        .clamp(-1.0, 1.0),
                  );
                  onAlignmentChanged(next);
                },
                child: box,
              ),
              ..._Corner.values.map((corner) {
                return Positioned(
                  left: corner.isLeft ? 0 : null,
                  right: corner.isLeft ? null : 0,
                  top: corner.isTop ? 0 : null,
                  bottom: corner.isTop ? null : 0,
                  child: _ResizeHandle(
                    corner: corner,
                    onUpdate: (delta) {
                      final next = (overlay.fontSize +
                              _sizeDelta(delta, corner))
                          .clamp(overlayTextMinSize, overlayTextMaxSize);
                      onFontSizeChanged(next);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  double _sizeDelta(Offset delta, _Corner corner) {
    final raw = switch (corner) {
      _Corner.bottomRight => delta.dx + delta.dy,
      _Corner.bottomLeft => -delta.dx + delta.dy,
      _Corner.topRight => delta.dx - delta.dy,
      _Corner.topLeft => -delta.dx - delta.dy,
    };
    return raw * 0.35;
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

extension on _Corner {
  bool get isLeft => this == _Corner.topLeft || this == _Corner.bottomLeft;
  bool get isTop => this == _Corner.topLeft || this == _Corner.topRight;
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.corner,
    required this.onUpdate,
  });

  final _Corner corner;
  final ValueChanged<Offset> onUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onUpdate(details.delta),
      child: SizedBox(
        width: OverlayTextLayer._handleSize,
        height: OverlayTextLayer._handleSize,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2C3028), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
  }
}
