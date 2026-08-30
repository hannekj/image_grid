import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'path_text_paint.dart';

/// Full-canvas gesture layer for drawing repeating path text.
class PathTextDrawLayer extends StatefulWidget {
  const PathTextDrawLayer({
    super.key,
    required this.text,
    required this.style,
    required this.letterSpacing,
    required this.onComplete,
    required this.onCancel,
  });

  final String text;
  final TextStyle style;
  final double letterSpacing;
  final ValueChanged<List<Offset>> onComplete;
  final VoidCallback onCancel;

  @override
  State<PathTextDrawLayer> createState() => _PathTextDrawLayerState();
}

class _PathTextDrawLayerState extends State<PathTextDrawLayer> {
  final List<Offset> _pixels = [];
  Size? _size;

  void _append(Offset local) {
    if (_pixels.isEmpty) {
      _pixels.add(local);
      return;
    }
    if ((local - _pixels.last).distance < 3) return;
    _pixels.add(local);
  }

  void _finish() {
    final size = _size;
    if (size == null) {
      widget.onCancel();
      return;
    }
    final length = PathTextPaint.pathLength(_pixels);
    if (_pixels.length < 2 || length < PathTextPaint.minPathLength) {
      widget.onCancel();
      return;
    }
    widget.onComplete(PathTextPaint.toNormalized(_pixels, size));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Material(
            color: AppTheme.ink.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tegn med fingeren — teksten følger streken',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Avbryt'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _size = constraints.biggest;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  setState(() {
                    _pixels
                      ..clear()
                      ..add(details.localPosition);
                  });
                },
                onPanUpdate: (details) {
                  setState(() => _append(details.localPosition));
                },
                onPanEnd: (_) => _finish(),
                onPanCancel: () {
                  setState(() => _pixels.clear());
                },
                child: CustomPaint(
                  painter: PathTextPainter(
                    normalizedPath: _size == null || _pixels.isEmpty
                        ? const []
                        : PathTextPaint.toNormalized(_pixels, _size!),
                    text: widget.text,
                    style: widget.style,
                    letterSpacing: widget.letterSpacing,
                    showGuide: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
