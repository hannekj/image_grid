import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'overlay_text.dart';

/// Utilities for painting repeating text along a polyline path.
class PathTextPaint {
  static const minPathLength = 28.0;

  static List<Offset> toPixels(List<Offset> normalized, Size size) {
    return [
      for (final point in normalized)
        Offset(
          point.dx.clamp(0.0, 1.0) * size.width,
          point.dy.clamp(0.0, 1.0) * size.height,
        ),
    ];
  }

  static List<Offset> toNormalized(List<Offset> pixels, Size size) {
    if (size.width <= 0 || size.height <= 0) return const [];
    return [
      for (final point in pixels)
        Offset(
          (point.dx / size.width).clamp(0.0, 1.0),
          (point.dy / size.height).clamp(0.0, 1.0),
        ),
    ];
  }

  static double pathLength(List<Offset> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  static List<double> cumulativeLengths(List<Offset> points) {
    final lengths = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      lengths[i] = lengths[i - 1] + (points[i] - points[i - 1]).distance;
    }
    return lengths;
  }

  static (Offset position, double angle) sampleAt(
    List<Offset> points,
    List<double> lengths,
    double distance,
  ) {
    final total = lengths.last;
    final d = distance.clamp(0.0, total);
    var i = 1;
    while (i < lengths.length && lengths[i] < d) {
      i += 1;
    }
    final prev = points[i - 1];
    final next = points[math.min(i, points.length - 1)];
    final segStart = lengths[i - 1];
    final segLen = lengths[math.min(i, lengths.length - 1)] - segStart;
    final t = segLen < 0.001 ? 0.0 : ((d - segStart) / segLen).clamp(0.0, 1.0);
    final position = Offset.lerp(prev, next, t)!;
    final delta = next - prev;
    final angle = delta.distance < 0.001 ? 0.0 : math.atan2(delta.dy, delta.dx);
    return (position, angle);
  }

  static void paintAlongPath({
    required Canvas canvas,
    required Size size,
    required List<Offset> normalizedPath,
    required String text,
    required TextStyle style,
    double letterSpacing = 0,
  }) {
    if (normalizedPath.length < 2) return;
    final content = text.trim().isEmpty ? '•' : text;
    final points = toPixels(normalizedPath, size);
    final lengths = cumulativeLengths(points);
    final total = lengths.last;
    if (total < 2) return;

    final chars = content.characters.toList(growable: false);
    if (chars.isEmpty) return;

    final painter = TextPainter(textDirection: ui.TextDirection.ltr);
    var distance = 0.0;
    var charIndex = 0;

    while (distance < total - 1) {
      final ch = chars[charIndex % chars.length];
      painter.text = TextSpan(text: ch, style: style);
      painter.layout();
      final width = math.max(painter.width, 1.0);
      final mid = distance + width / 2;
      if (mid > total) break;

      final (position, angle) = sampleAt(points, lengths, mid);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle);
      painter.paint(canvas, Offset(-width / 2, -painter.height / 2));
      canvas.restore();

      distance += width + letterSpacing;
      charIndex += 1;
      if (charIndex > 4000) break;
    }
  }

  static bool hitTest({
    required List<Offset> normalizedPath,
    required Size size,
    required Offset localPosition,
    double threshold = 28,
  }) {
    if (normalizedPath.length < 2) return false;
    final points = toPixels(normalizedPath, size);
    for (var i = 1; i < points.length; i++) {
      if (_distanceToSegment(localPosition, points[i - 1], points[i]) <=
          threshold) {
        return true;
      }
    }
    return false;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final length2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (length2 < 0.001) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / length2)
        .clamp(0.0, 1.0);
    final closest = a + ab * t;
    return (p - closest).distance;
  }

  static TextStyle styleFor(OverlayText overlay) {
    return overlay.textStyle();
  }
}

class PathTextPainter extends CustomPainter {
  const PathTextPainter({
    required this.normalizedPath,
    required this.text,
    required this.style,
    this.letterSpacing = 0,
    this.showGuide = false,
    this.selected = false,
  });

  final List<Offset> normalizedPath;
  final String text;
  final TextStyle style;
  final double letterSpacing;
  final bool showGuide;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    if ((showGuide || selected) && normalizedPath.length >= 2) {
      final points = PathTextPaint.toPixels(normalizedPath, size);
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: selected ? 0.45 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.5 : 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    PathTextPaint.paintAlongPath(
      canvas: canvas,
      size: size,
      normalizedPath: normalizedPath,
      text: text,
      style: style,
      letterSpacing: letterSpacing,
    );
  }

  @override
  bool shouldRepaint(covariant PathTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.letterSpacing != letterSpacing ||
        oldDelegate.showGuide != showGuide ||
        oldDelegate.selected != selected ||
        oldDelegate.normalizedPath != normalizedPath;
  }
}
