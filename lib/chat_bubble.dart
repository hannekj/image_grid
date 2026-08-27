import 'dart:math' as math;

import 'package:flutter/material.dart';

enum BubbleTailSide { left, right }

/// iMessage outgoing blue.
const chatBubbleBlue = Color(0xFF007AFF);

/// iMessage incoming gray.
const chatBubbleGray = Color(0xFFE9E9EB);

/// Dark pill for location widgets.
const locationPillColor = Color(0xFF3A3A3C);

/// iMessage-style speech bubble with tail protruding outside the body.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.color,
    required this.tailSide,
    required this.child,
    this.showTail = true,
  });

  final Color color;
  final BubbleTailSide tailSide;
  final Widget child;
  final bool showTail;

  /// Horizontal room reserved outside the body for the tail nub.
  static const _tailExtent = 5.0;

  @override
  Widget build(BuildContext context) {
    final tailRight = showTail && tailSide == BubbleTailSide.right;
    final tailLeft = showTail && tailSide == BubbleTailSide.left;

    return CustomPaint(
      painter: _ChatBubblePainter(
        color: color,
        tailSide: tailSide,
        showTail: showTail,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tailLeft ? 15 + _tailExtent : 15,
          9,
          tailRight ? 15 + _tailExtent : 15,
          10,
        ),
        child: child,
      ),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  const _ChatBubblePainter({
    required this.color,
    required this.tailSide,
    required this.showTail,
  });

  final Color color;
  final BubbleTailSide tailSide;
  final bool showTail;

  static const _maxRadius = 18.0;
  static const _tailExtent = ChatBubble._tailExtent;

  @override
  void paint(Canvas canvas, Size size) {
    final path = !showTail
        ? _roundRectPath(size)
        : _tailedPath(size, mirrored: tailSide == BubbleTailSide.left);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true
        ..style = PaintingStyle.fill,
    );
  }

  static double _radiusFor(double bodyHeight) {
    return math.min(_maxRadius, bodyHeight * 0.4);
  }

  static Path _roundRectPath(Size size) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(_radiusFor(size.height)),
        ),
      );
  }

  /// Body plus the small iMessage tail nub that hooks off the bottom-right
  /// corner, leaving a shallow notch above the corner. Mirrored for incoming.
  static Path _tailedPath(Size size, {required bool mirrored}) {
    final w = size.width;
    final h = size.height;
    final bw = w - _tailExtent;
    final r = _radiusFor(h);
    // Tail geometry scales with the corner radius so it stays constant once
    // the bubble grows past a single line, the way iMessage draws it.
    final t = math.min(_tailExtent, r * 0.25);

    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, bw, h),
          Radius.circular(r),
        ),
      );

    final tail = Path()
      ..moveTo(bw - r * 0.10, h - r * 1.05)
      ..cubicTo(
        bw + r * 0.06,
        h - r * 0.62,
        bw + r * 0.16,
        h - r * 0.36,
        bw + t,
        h - r * 0.19,
      )
      // Rounded outer tip.
      ..cubicTo(
        bw + t * 1.02,
        h - r * 0.08,
        bw + t * 0.78,
        h - r * 0.10,
        bw + t * 0.42,
        h - r * 0.13,
      )
      // Concave underside carving the notch above the corner.
      ..cubicTo(
        bw - r * 0.06,
        h - r * 0.18,
        bw - r * 0.28,
        h - r * 0.30,
        bw - r * 0.45,
        h - r * 0.42,
      )
      ..close();

    final path = Path.combine(PathOperation.union, body, tail);

    if (!mirrored) return path;

    return path.transform(
      (Matrix4.identity()
            ..translateByDouble(w, 0, 0, 1)
            ..scaleByDouble(-1, 1, 1, 1))
          .storage,
    );
  }

  @override
  bool shouldRepaint(covariant _ChatBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.tailSide != tailSide ||
        oldDelegate.showTail != showTail;
  }
}

/// Rounded pill for location — no tail.
class LocationPill extends StatelessWidget {
  const LocationPill({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }
}

/// Fixed-size preview bubble for picker UI.
class ChatBubblePreview extends StatelessWidget {
  const ChatBubblePreview({
    super.key,
    this.label = 'Melding',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return ChatBubble(
      color: chatBubbleBlue,
      tailSide: BubbleTailSide.right,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          height: 1.22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Fixed-size preview pill for picker UI.
class LocationPillPreview extends StatelessWidget {
  const LocationPillPreview({
    super.key,
    this.label = 'Sted',
    this.icon = Icons.location_on,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 118),
      child: LocationPill(
        color: locationPillColor,
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
