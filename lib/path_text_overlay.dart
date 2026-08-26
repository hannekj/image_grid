import 'package:flutter/material.dart';

import 'overlay_text.dart';
import 'path_text_paint.dart';

/// Interactive path-text overlay (select, drag whole path, edit).
class PathTextOverlay extends StatefulWidget {
  const PathTextOverlay({
    super.key,
    required this.overlay,
    required this.interactive,
    required this.onSelect,
    required this.onEdit,
    required this.onPathChanged,
    this.onInteractionChanged,
  });

  final OverlayText overlay;
  final bool interactive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final ValueChanged<List<Offset>> onPathChanged;
  final ValueChanged<bool>? onInteractionChanged;

  @override
  State<PathTextOverlay> createState() => _PathTextOverlayState();
}

class _PathTextOverlayState extends State<PathTextOverlay> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final points = widget.overlay.pathPoints ?? const <Offset>[];
    if (points.length < 2) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final hit = PathTextPaint.hitTest(
              normalizedPath: points,
              size: size,
              localPosition: details.localPosition,
            );
            if (hit) widget.onSelect();
          },
          onDoubleTapDown: (details) {
            final hit = PathTextPaint.hitTest(
              normalizedPath: points,
              size: size,
              localPosition: details.localPosition,
            );
            if (hit) widget.onEdit();
          },
          onPanStart: widget.interactive
              ? (details) {
                  final hit = PathTextPaint.hitTest(
                    normalizedPath: points,
                    size: size,
                    localPosition: details.localPosition,
                  );
                  _dragging = hit;
                  if (hit) widget.onInteractionChanged?.call(true);
                }
              : null,
          onPanUpdate: widget.interactive
              ? (details) {
                  if (!_dragging) return;
                  final dx = details.delta.dx / size.width;
                  final dy = details.delta.dy / size.height;
                  final next = [
                    for (final point in points)
                      Offset(
                        (point.dx + dx).clamp(0.0, 1.0),
                        (point.dy + dy).clamp(0.0, 1.0),
                      ),
                  ];
                  widget.onPathChanged(next);
                }
              : null,
          onPanEnd: widget.interactive
              ? (_) {
                  if (!_dragging) return;
                  _dragging = false;
                  widget.onInteractionChanged?.call(false);
                }
              : null,
          onPanCancel: widget.interactive
              ? () {
                  if (!_dragging) return;
                  _dragging = false;
                  widget.onInteractionChanged?.call(false);
                }
              : null,
          child: CustomPaint(
            painter: PathTextPainter(
              normalizedPath: points,
              text: widget.overlay.value,
              style: PathTextPaint.styleFor(widget.overlay),
              letterSpacing: widget.overlay.letterSpacing,
              selected: widget.interactive,
            ),
          ),
        );
      },
    );
  }
}
