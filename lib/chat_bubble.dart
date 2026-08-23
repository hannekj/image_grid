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

  static const _tailExtent = 8.0;
  static const _tailDrop = 3.0;

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
          14,
          9,
          tailRight ? 14 + _tailExtent : 14,
          10 + (showTail ? _tailDrop : 0),
        ).copyWith(
          left: tailLeft ? 14 + _tailExtent : 14,
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

  static const _radius = 18.0;
  static const _tailCorner = 4.0;
  static const _tailExtent = 8.0;
  static const _tailDrop = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final path = !showTail
        ? _roundRectPath(size)
        : tailSide == BubbleTailSide.right
            ? _outgoingPath(size)
            : _incomingPath(size);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  static Path _roundRectPath(Size size) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(_radius),
        ),
      );
  }

  /// Outgoing — small tail at bottom-right, drawn in reserved padding.
  static Path _outgoingPath(Size size) {
    final w = size.width;
    final h = size.height;
    const r = _radius;
    const rt = _tailCorner;
    const tail = _tailExtent;
    const drop = _tailDrop;
    final bodyRight = w - tail;

    return Path()
      ..moveTo(r, 0)
      ..lineTo(bodyRight - r, 0)
      ..arcToPoint(Offset(bodyRight, r), radius: const Radius.circular(r))
      ..lineTo(bodyRight, h - drop - rt - 5)
      ..arcToPoint(
        Offset(bodyRight - rt, h - drop - 5),
        radius: const Radius.circular(rt),
      )
      ..quadraticBezierTo(w, h, bodyRight - 1, h - drop - 4)
      ..lineTo(r, h - drop)
      ..arcToPoint(Offset(0, h - drop - r), radius: const Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))
      ..close();
  }

  /// Incoming — small tail at bottom-left.
  static Path _incomingPath(Size size) {
    final w = size.width;
    final h = size.height;
    const r = _radius;
    const rt = _tailCorner;
    const tail = _tailExtent;
    const drop = _tailDrop;
    final bodyLeft = tail;

    return Path()
      ..moveTo(bodyLeft + r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, h - drop - r)
      ..arcToPoint(Offset(w - r, h - drop), radius: const Radius.circular(r))
      ..lineTo(bodyLeft + rt + 2, h - drop)
      ..quadraticBezierTo(0, h, bodyLeft + rt, h - drop - 4)
      ..lineTo(bodyLeft + rt, h - drop - rt - 5)
      ..arcToPoint(
        Offset(bodyLeft, h - drop - rt - 5),
        radius: const Radius.circular(rt),
      )
      ..lineTo(bodyLeft, r)
      ..arcToPoint(Offset(bodyLeft + r, 0), radius: const Radius.circular(r))
      ..close();
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
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return LocationPill(
      color: locationPillColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
