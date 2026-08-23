import 'package:flutter/material.dart';

import 'image_corner_handles.dart';

enum _Edge { top, bottom, left, right }

/// Corner + edge resize handles for image adjustment.
class ImageAdjustHandles extends StatelessWidget {
  const ImageAdjustHandles({
    super.key,
    required this.onScaleDelta,
    this.onInteractionChanged,
    this.handleSize = 26,
    this.outset = 4,
  });

  final ValueChanged<double> onScaleDelta;
  final ValueChanged<bool>? onInteractionChanged;
  final double handleSize;
  final double outset;

  @override
  Widget build(BuildContext context) {
    final offset = handleSize / 2 + outset;
    final edgeW = handleSize * 0.95;
    final edgeH = handleSize * 0.34;
    final edgeInset = offset - handleSize / 2;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        ImageCornerHandles(
          onScaleDelta: onScaleDelta,
          onInteractionChanged: onInteractionChanged,
          handleSize: handleSize,
          outset: outset,
        ),
        Positioned(
          top: -edgeInset,
          left: 0,
          right: 0,
          child: Center(
            child: _EdgeHandle(
              width: edgeW,
              height: edgeH,
              edge: _Edge.top,
              onScaleDelta: onScaleDelta,
              onInteractionChanged: onInteractionChanged,
            ),
          ),
        ),
        Positioned(
          bottom: -edgeInset,
          left: 0,
          right: 0,
          child: Center(
            child: _EdgeHandle(
              width: edgeW,
              height: edgeH,
              edge: _Edge.bottom,
              onScaleDelta: onScaleDelta,
              onInteractionChanged: onInteractionChanged,
            ),
          ),
        ),
        Positioned(
          left: -edgeInset,
          top: 0,
          bottom: 0,
          child: Center(
            child: _EdgeHandle(
              width: edgeH,
              height: edgeW,
              edge: _Edge.left,
              onScaleDelta: onScaleDelta,
              onInteractionChanged: onInteractionChanged,
            ),
          ),
        ),
        Positioned(
          right: -edgeInset,
          top: 0,
          bottom: 0,
          child: Center(
            child: _EdgeHandle(
              width: edgeH,
              height: edgeW,
              edge: _Edge.right,
              onScaleDelta: onScaleDelta,
              onInteractionChanged: onInteractionChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _EdgeHandle extends StatelessWidget {
  const _EdgeHandle({
    required this.width,
    required this.height,
    required this.edge,
    required this.onScaleDelta,
    required this.onInteractionChanged,
  });

  final double width;
  final double height;
  final _Edge edge;
  final ValueChanged<double> onScaleDelta;
  final ValueChanged<bool>? onInteractionChanged;

  double _edgeDelta(Offset delta) {
    final raw = switch (edge) {
      _Edge.bottom => delta.dy,
      _Edge.top => -delta.dy,
      _Edge.right => delta.dx,
      _Edge.left => -delta.dx,
    };
    return raw * 0.004;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onInteractionChanged?.call(true),
      onPanUpdate: (details) => onScaleDelta(_edgeDelta(details.delta)),
      onPanEnd: (_) => onInteractionChanged?.call(false),
      onPanCancel: () => onInteractionChanged?.call(false),
      child: SizedBox(
        width: width + 16,
        height: height + 16,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF2C3028), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(width: width, height: height),
          ),
        ),
      ),
    );
  }
}

class ImageRotateHandle extends StatelessWidget {
  const ImageRotateHandle({
    super.key,
    required this.onUpdate,
    this.onInteractionChanged,
  });

  final ValueChanged<double> onUpdate;
  final ValueChanged<bool>? onInteractionChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onInteractionChanged?.call(true),
      onPanUpdate: (details) => onUpdate(details.delta.dx * 0.012),
      onPanEnd: (_) => onInteractionChanged?.call(false),
      onPanCancel: () => onInteractionChanged?.call(false),
      child: SizedBox(
        width: 32,
        height: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2C3028), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.rotate_right,
            size: 17,
            color: Color(0xFF2C3028),
          ),
        ),
      ),
    );
  }
}
