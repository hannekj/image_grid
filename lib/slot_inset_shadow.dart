import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Soft diffuse shadows along slot edges — defines the drop zone without a frame.
class SlotInsetShadow extends StatelessWidget {
  const SlotInsetShadow({
    super.key,
    this.emphasized = true,
  });

  /// Stronger shading for empty slots awaiting an image.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiffuseInsetShadowPainter(emphasized: emphasized),
      size: Size.infinite,
    );
  }
}

class _DiffuseInsetShadowPainter extends CustomPainter {
  const _DiffuseInsetShadowPainter({required this.emphasized});

  final bool emphasized;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final shortest = size.shortestSide;
    final depth = math.min(
      shortest * (emphasized ? 0.38 : 0.30),
      emphasized ? 44.0 : 34.0,
    );
    final peak = emphasized ? 0.085 : 0.05;
    // Softer than ink — reads as a gentle recess on mist, not a hard edge.
    const tint = AppTheme.muted;

    _edge(
      canvas,
      rect: Rect.fromLTWH(0, 0, size.width, depth),
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      peak: peak,
      tint: tint,
    );
    _edge(
      canvas,
      rect: Rect.fromLTWH(0, size.height - depth, size.width, depth),
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      peak: peak,
      tint: tint,
    );
    _edge(
      canvas,
      rect: Rect.fromLTWH(0, 0, depth, size.height),
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      peak: peak * 0.92,
      tint: tint,
    );
    _edge(
      canvas,
      rect: Rect.fromLTWH(size.width - depth, 0, depth, size.height),
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      peak: peak * 0.92,
      tint: tint,
    );
  }

  void _edge(
    Canvas canvas, {
    required Rect rect,
    required Alignment begin,
    required Alignment end,
    required double peak,
    required Color tint,
  }) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [
          tint.withValues(alpha: peak),
          tint.withValues(alpha: peak * 0.55),
          tint.withValues(alpha: peak * 0.18),
          tint.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.28, 0.62, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _DiffuseInsetShadowPainter oldDelegate) {
    return oldDelegate.emphasized != emphasized;
  }
}
