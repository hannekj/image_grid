import 'package:flutter/material.dart';

enum ImageCorner { topLeft, topRight, bottomLeft, bottomRight }

extension ImageCornerX on ImageCorner {
  bool get isLeft =>
      this == ImageCorner.topLeft || this == ImageCorner.bottomLeft;
  bool get isTop => this == ImageCorner.topLeft || this == ImageCorner.topRight;
}

/// Corner drag handles for scaling images — sit mostly outside the frame.
class ImageCornerHandles extends StatelessWidget {
  const ImageCornerHandles({
    super.key,
    required this.onScaleDelta,
    this.handleSize = 26,
    this.outset = 4,
    this.onInteractionChanged,
  });

  final ValueChanged<double> onScaleDelta;
  final double handleSize;
  /// How far past the frame edge the handle center sits.
  final double outset;
  final ValueChanged<bool>? onInteractionChanged;

  double _sizeDelta(Offset delta, ImageCorner corner) {
    final raw = switch (corner) {
      ImageCorner.bottomRight => delta.dx + delta.dy,
      ImageCorner.bottomLeft => -delta.dx + delta.dy,
      ImageCorner.topRight => delta.dx - delta.dy,
      ImageCorner.topLeft => -delta.dx - delta.dy,
    };
    return raw * 0.004;
  }

  @override
  Widget build(BuildContext context) {
    final offset = handleSize / 2 + outset;
    final knob = handleSize * 0.62;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        for (final corner in ImageCorner.values)
          Positioned(
            left: corner.isLeft ? -offset : null,
            right: corner.isLeft ? null : -offset,
            top: corner.isTop ? -offset : null,
            bottom: corner.isTop ? null : -offset,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => onInteractionChanged?.call(true),
              onPanUpdate: (details) {
                onScaleDelta(_sizeDelta(details.delta, corner));
              },
              onPanEnd: (_) => onInteractionChanged?.call(false),
              onPanCancel: () => onInteractionChanged?.call(false),
              child: SizedBox(
                width: handleSize,
                height: handleSize,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2C3028),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(width: knob, height: knob),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
