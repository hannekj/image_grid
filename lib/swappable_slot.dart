import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Long-press drag to swap images between slots.
class SwappableSlot extends StatelessWidget {
  const SwappableSlot({
    super.key,
    required this.index,
    required this.imageBytes,
    required this.showChrome,
    required this.onSwap,
    required this.child,
  });

  final int index;
  final Uint8List? imageBytes;
  final bool showChrome;
  final void Function(int from, int to) onSwap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onSwap(details.data, index),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        final wrapped = ColoredBox(
          color: hovering ? const Color(0x22000000) : Colors.transparent,
          child: child,
        );

        if (bytes == null) return wrapped;

        return LongPressDraggable<int>(
          data: index,
          maxSimultaneousDrags: showChrome ? 1 : 0,
          feedback: Material(
            elevation: 6,
            child: SizedBox(
              width: 96,
              height: 96,
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: wrapped),
          child: wrapped,
        );
      },
    );
  }
}
