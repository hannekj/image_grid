import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'app_theme.dart';
import 'overlay_text.dart';
import 'path_text_paint.dart';

/// Interactive path-text overlay (select, drag whole path, resize, edit).
class PathTextOverlay extends StatefulWidget {
  const PathTextOverlay({
    super.key,
    required this.overlay,
    required this.interactive,
    required this.onSelect,
    required this.onEdit,
    required this.onPathChanged,
    required this.onFontSizeChanged,
    this.onInteractionChanged,
  });

  final OverlayText overlay;
  final bool interactive;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final ValueChanged<List<Offset>> onPathChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool>? onInteractionChanged;

  @override
  State<PathTextOverlay> createState() => _PathTextOverlayState();
}

class _PathTextOverlayState extends State<PathTextOverlay> {
  bool _dragging = false;
  double _sizeStart = 22;
  double _sizeDragY = 0;

  @override
  Widget build(BuildContext context) {
    final points = widget.overlay.pathPoints ?? const <Offset>[];
    if (points.length < 2) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final pixels = PathTextPaint.toPixels(points, size);
        final handleAt = pixels[pixels.length ~/ 2];

        return Stack(
          fit: StackFit.expand,
          children: [
            _PathTextHitTarget(
              normalizedPath: points,
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
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
              ),
            ),
            if (widget.interactive)
              Positioned(
                left: handleAt.dx - 16,
                top: handleAt.dy - 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    _sizeStart = widget.overlay.fontSize;
                    _sizeDragY = 0;
                    widget.onInteractionChanged?.call(true);
                  },
                  onPanUpdate: (details) {
                    _sizeDragY += details.delta.dy;
                    final next = (_sizeStart - _sizeDragY * 0.35)
                        .clamp(overlayTextMinSize, overlayTextMaxSize);
                    widget.onFontSizeChanged(next.toDouble());
                  },
                  onPanEnd: (_) => widget.onInteractionChanged?.call(false),
                  onPanCancel: () => widget.onInteractionChanged?.call(false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.ink, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.text_fields,
                      size: 16,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Lets taps pass through to widgets below except near the drawn path.
class _PathTextHitTarget extends SingleChildRenderObjectWidget {
  const _PathTextHitTarget({
    required this.normalizedPath,
    required super.child,
  });

  final List<Offset> normalizedPath;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPathTextHitTarget(normalizedPath: normalizedPath);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPathTextHitTarget renderObject,
  ) {
    renderObject.normalizedPath = normalizedPath;
  }
}

class _RenderPathTextHitTarget extends RenderProxyBox {
  _RenderPathTextHitTarget({required this._normalizedPath});

  List<Offset> _normalizedPath;

  set normalizedPath(List<Offset> value) {
    if (identical(_normalizedPath, value)) return;
    _normalizedPath = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!PathTextPaint.hitTest(
      normalizedPath: _normalizedPath,
      size: size,
      localPosition: position,
    )) {
      return false;
    }
    return super.hitTest(result, position: position);
  }
}
