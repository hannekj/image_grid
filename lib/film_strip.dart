import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

enum FilmStripAxis { horizontal, vertical }

/// Default body color for film strip layouts: a warm dark gray that reads as
/// film base without going all the way to black.
const Color defaultFilmStripColor = Color(0xFF5C574F);

/// Proportions of a 35mm strip, as fractions of the strip's short side, so a
/// strip reads the same at any size and any frame count.
class FilmStripMetrics {
  FilmStripMetrics._();

  /// Perforation row centre, measured in from the strip edge.
  static const perfCenter = 0.105;

  /// Perforation size along and across the strip.
  static const perfLength = 0.088;
  static const perfWidth = 0.062;
  static const perfRadius = 0.018;

  /// Centre-to-centre spacing of the perforations.
  static const perfPitch = 0.132;

  /// Strip edge to photo window.
  static const frameInset = 0.185;
  static const endMargin = 0.055;
  static const gutter = 0.035;
  static const frameRadius = 0.05;
  static const bodyRadius = 0.03;

  /// Windows are slightly landscape, like a real 35mm frame.
  static const frameAspect = 1.2;

  static double get frameWidth => (1 - frameInset * 2) * frameAspect;

  /// Strip length relative to its short side, for [frames] windows.
  static double lengthFor(int frames) =>
      endMargin * 2 + frames * frameWidth + (frames - 1) * gutter;
}

/// Classic 35mm-style film strip with punched sprocket holes.
class FilmStrip extends StatelessWidget {
  const FilmStrip({
    super.key,
    required this.slots,
    required this.axis,
    this.color = defaultFilmStripColor,
  });

  final List<Widget> slots;
  final FilmStripAxis axis;

  /// Body color of the film strip (Stil → Ramme → Farge).
  final Color color;

  bool get _horizontal => axis == FilmStripAxis.horizontal;

  @override
  Widget build(BuildContext context) {
    assert(slots.isNotEmpty);
    final ratio = FilmStripMetrics.lengthFor(slots.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _stripSize(constraints.biggest, ratio);
        final short = _horizontal ? size.height : size.width;
        final gutter = short * FilmStripMetrics.gutter;

        return Center(
          child: Transform.rotate(
            angle: _horizontal ? -0.022 : 0.026,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: CustomPaint(
                painter: FilmStripPainter(horizontal: _horizontal, color: color),
                child: Padding(
                  padding: _framePadding(short),
                  child: Flex(
                    direction: _horizontal ? Axis.horizontal : Axis.vertical,
                    children: [
                      for (var i = 0; i < slots.length; i++) ...[
                        if (i > 0)
                          SizedBox(
                            width: _horizontal ? gutter : null,
                            height: _horizontal ? null : gutter,
                          ),
                        Expanded(child: _window(slots[i], short)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Size _stripSize(Size available, double ratio) {
    if (_horizontal) {
      final short = math.min(
        available.height * 0.52,
        available.width * 0.94 / ratio,
      );
      return Size(short * ratio, short);
    }
    final short = math.min(
      available.width * 0.52,
      available.height * 0.94 / ratio,
    );
    return Size(short, short * ratio);
  }

  EdgeInsets _framePadding(double short) {
    final across = short * FilmStripMetrics.frameInset;
    final along = short * FilmStripMetrics.endMargin;
    return _horizontal
        ? EdgeInsets.fromLTRB(along, across, along, across)
        : EdgeInsets.fromLTRB(across, along, across, along);
  }

  Widget _window(Widget child, double short) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        short * FilmStripMetrics.frameRadius,
      ),
      child: SizedBox.expand(
        child: ColoredBox(color: AppTheme.mist, child: child),
      ),
    );
  }
}

class FilmStripPainter extends CustomPainter {
  const FilmStripPainter({
    required this.horizontal,
    required this.color,
    this.shadow = true,
  });

  final bool horizontal;
  final Color color;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    paintFilmStripBody(
      canvas,
      Offset.zero & size,
      horizontal: horizontal,
      color: color,
      shadow: shadow,
    );
  }

  @override
  bool shouldRepaint(covariant FilmStripPainter oldDelegate) =>
      oldDelegate.horizontal != horizontal ||
      oldDelegate.color != color ||
      oldDelegate.shadow != shadow;
}

/// Paints the film base into [rect]. The perforations are cut out of the path
/// rather than drawn in a contrasting colour, so whatever sits behind the
/// strip shows through them.
void paintFilmStripBody(
  Canvas canvas,
  Rect rect, {
  required bool horizontal,
  required Color color,
  bool shadow = true,
}) {
  final short = horizontal ? rect.height : rect.width;
  if (short <= 0 || rect.isEmpty) return;

  final body = _bodyPath(rect, horizontal);

  if (shadow) {
    canvas.drawPath(
      body.shift(Offset(0, short * 0.055)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(0.6, short * 0.08),
        ),
    );
  }

  canvas.drawPath(body, Paint()..color = color);

  // Slight sheen across the base so it reads as film stock, not flat paper.
  canvas.drawPath(
    body,
    Paint()
      ..shader = LinearGradient(
        begin: horizontal ? Alignment.topCenter : Alignment.centerLeft,
        end: horizontal ? Alignment.bottomCenter : Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.12),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect),
  );
}

Path _bodyPath(Rect rect, bool horizontal) {
  final short = horizontal ? rect.height : rect.width;
  final long = horizontal ? rect.width : rect.height;

  final path = Path()..fillType = PathFillType.evenOdd;
  path.addRRect(
    RRect.fromRectAndRadius(
      rect,
      Radius.circular(short * FilmStripMetrics.bodyRadius),
    ),
  );

  final pitch = short * FilmStripMetrics.perfPitch;
  if (pitch <= 0) return path;

  final count = math.max(2, (long / pitch).floor());
  final span = pitch * (count - 1);
  final origin = (horizontal ? rect.left : rect.top) + (long - span) / 2;

  final perfLong = short * FilmStripMetrics.perfLength;
  final perfShort = short * FilmStripMetrics.perfWidth;
  final radius = Radius.circular(short * FilmStripMetrics.perfRadius);
  final near = short * FilmStripMetrics.perfCenter;
  final rows = [near, short - near];

  for (var i = 0; i < count; i++) {
    final along = origin + pitch * i;
    for (final row in rows) {
      final center = horizontal
          ? Offset(along, rect.top + row)
          : Offset(rect.left + row, along);
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: horizontal ? perfLong : perfShort,
            height: horizontal ? perfShort : perfLong,
          ),
          radius,
        ),
      );
    }
  }

  return path;
}
