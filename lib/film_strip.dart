import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Number of photo frames in a film strip layout.
const int filmStripSlotCount = 4;

enum FilmStripAxis { horizontal, vertical }

const _defaultFilmColor = Color(0xFF141414);

/// Classic 35mm-style film strip with sprocket holes and photo frames.
class FilmStrip extends StatelessWidget {
  const FilmStrip({
    super.key,
    required this.slots,
    required this.axis,
    this.color = _defaultFilmColor,
  });

  final List<Widget> slots;
  final FilmStripAxis axis;

  /// Body color of the film strip (Look → Ramme → Farge).
  final Color color;

  bool get _horizontal => axis == FilmStripAxis.horizontal;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == filmStripSlotCount);
    final body = color;
    final band = _darken(body, 0.35);
    final holes = _contrastingHoleColor(body);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _stripSize(constraints.biggest);
        return Center(
          child: Transform.rotate(
            angle: _horizontal ? -0.03 : 0.035,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: body,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _SprocketPainter(
                    horizontal: _horizontal,
                    bandColor: band,
                    holeColor: holes,
                  ),
                  child: Padding(
                    padding: _contentPadding(size),
                    child: _horizontal
                        ? Row(
                            children: [
                              for (var i = 0; i < slots.length; i++) ...[
                                if (i > 0) SizedBox(width: size.height * 0.045),
                                Expanded(child: _frame(slots[i])),
                              ],
                            ],
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < slots.length; i++) ...[
                                if (i > 0) SizedBox(height: size.width * 0.045),
                                Expanded(child: _frame(slots[i])),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Size _stripSize(Size available) {
    if (_horizontal) {
      final maxWidth = available.width * 0.92;
      final maxHeight = available.height * 0.42;
      // Rough 35mm strip: ~4 frames wide, aspect ~3.4:1
      final height = math.min(maxHeight, maxWidth / 3.35);
      final width = height * 3.35;
      return Size(width, height);
    }

    final maxWidth = available.width * 0.42;
    final maxHeight = available.height * 0.92;
    final width = math.min(maxWidth, maxHeight / 3.35);
    final height = width * 3.35;
    return Size(width, height);
  }

  EdgeInsets _contentPadding(Size size) {
    if (_horizontal) {
      final sprocket = size.height * 0.16;
      final end = size.height * 0.08;
      return EdgeInsets.fromLTRB(end, sprocket, end, sprocket);
    }
    final sprocket = size.width * 0.16;
    final end = size.width * 0.08;
    return EdgeInsets.fromLTRB(sprocket, end, sprocket, end);
  }

  Widget _frame(Widget child) {
    return ColoredBox(
      color: AppTheme.mist,
      child: child,
    );
  }
}

Color _darken(Color color, double amount) {
  final h = HSLColor.fromColor(color);
  return h
      .withLightness((h.lightness * (1.0 - amount)).clamp(0.0, 1.0))
      .toColor();
}

Color _contrastingHoleColor(Color body) {
  final luminance = body.computeLuminance();
  return luminance > 0.45 ? const Color(0xFF1A1A1A) : const Color(0xFFE8E4DC);
}

class _SprocketPainter extends CustomPainter {
  const _SprocketPainter({
    required this.horizontal,
    required this.bandColor,
    required this.holeColor,
  });

  final bool horizontal;
  final Color bandColor;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final holePaint = Paint()..color = holeColor;
    final bandPaint = Paint()..color = bandColor;

    if (horizontal) {
      final bandH = size.height * 0.145;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, bandH), bandPaint);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - bandH, size.width, bandH),
        bandPaint,
      );
      _paintHolesAlong(
        canvas,
        holePaint,
        along: size.width,
        centerA: bandH / 2,
        centerB: size.height - bandH / 2,
        holeW: size.height * 0.055,
        holeH: size.height * 0.075,
        count: 18,
        horizontalTrack: true,
      );
    } else {
      final bandW = size.width * 0.145;
      canvas.drawRect(Rect.fromLTWH(0, 0, bandW, size.height), bandPaint);
      canvas.drawRect(
        Rect.fromLTWH(size.width - bandW, 0, bandW, size.height),
        bandPaint,
      );
      _paintHolesAlong(
        canvas,
        holePaint,
        along: size.height,
        centerA: bandW / 2,
        centerB: size.width - bandW / 2,
        holeW: size.width * 0.075,
        holeH: size.width * 0.055,
        count: 18,
        horizontalTrack: false,
      );
    }
  }

  void _paintHolesAlong(
    Canvas canvas,
    Paint paint, {
    required double along,
    required double centerA,
    required double centerB,
    required double holeW,
    required double holeH,
    required int count,
    required bool horizontalTrack,
  }) {
    final spacing = along / (count + 1);
    final radius = Radius.circular(math.min(holeW, holeH) * 0.28);

    for (var i = 1; i <= count; i++) {
      final t = spacing * i;
      final rectA = horizontalTrack
          ? Rect.fromCenter(
              center: Offset(t, centerA),
              width: holeW,
              height: holeH,
            )
          : Rect.fromCenter(
              center: Offset(centerA, t),
              width: holeW,
              height: holeH,
            );
      final rectB = horizontalTrack
          ? Rect.fromCenter(
              center: Offset(t, centerB),
              width: holeW,
              height: holeH,
            )
          : Rect.fromCenter(
              center: Offset(centerB, t),
              width: holeW,
              height: holeH,
            );
      canvas.drawRRect(RRect.fromRectAndRadius(rectA, radius), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rectB, radius), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SprocketPainter oldDelegate) =>
      oldDelegate.horizontal != horizontal ||
      oldDelegate.bandColor != bandColor ||
      oldDelegate.holeColor != holeColor;
}
