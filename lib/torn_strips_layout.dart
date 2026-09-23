import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Three equal portrait strips separated by torn-paper seams.
class TornStripsLayout {
  TornStripsLayout._();

  static const slotCount = 3;
  static const defaultLabel = 'Rivne striper';

  /// Vertical room a torn seam needs on either side of the cut.
  static double tearHeight(double height) =>
      math.max(5.0, math.min(14.0, height * 0.017));
}

class TornStripsFrame extends StatelessWidget {
  const TornStripsFrame({
    super.key,
    required this.slots,
  });

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == TornStripsLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final stripHeight = height / TornStripsLayout.slotCount;
        final tear = TornStripsLayout.tearHeight(height);

        return ColoredBox(
          color: _paperBase,
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < TornStripsLayout.slotCount; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: stripHeight * i,
                  height: stripHeight,
                  child: ClipRect(child: slots[i]),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _TornSeamsPainter(
                      stripHeight: stripHeight,
                      tear: tear,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Thumbnail / outline helper for shelf previews.
void paintTornStripsOutline(
  Canvas canvas,
  Size size, {
  required Color cellColor,
}) {
  canvas.drawRect(Offset.zero & size, Paint()..color = cellColor);

  final stripHeight = size.height / TornStripsLayout.slotCount;
  final tear = math.max(2.0, size.height * 0.022);
  for (var s = 1; s < TornStripsLayout.slotCount; s++) {
    _paintSeam(
      canvas,
      width: size.width,
      y: stripHeight * s,
      tear: tear,
      seed: _seamSeed(s - 1),
    );
  }
}

const _paperBase = Color(0xFFF6F5F2);

int _seamSeed(int seamIndex) => 17 + seamIndex * 101;

class _TornSeamsPainter extends CustomPainter {
  const _TornSeamsPainter({
    required this.stripHeight,
    required this.tear,
  });

  final double stripHeight;
  final double tear;

  @override
  void paint(Canvas canvas, Size size) {
    for (var s = 1; s < TornStripsLayout.slotCount; s++) {
      _paintSeam(
        canvas,
        width: size.width,
        y: stripHeight * s,
        tear: tear,
        seed: _seamSeed(s - 1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TornSeamsPainter oldDelegate) =>
      oldDelegate.stripHeight != stripHeight || oldDelegate.tear != tear;
}

/// Ragged white paper edge laid over the seam at [y], with the strip above
/// casting a soft shadow on the strip below.
void _paintSeam(
  Canvas canvas, {
  required double width,
  required double y,
  required double tear,
  required int seed,
}) {
  final ribbon = _ribbon(width: width, y: y, tear: tear, seed: seed);
  final band = Path()..addPolygon(ribbon.top, false);
  for (var i = ribbon.bottom.length - 1; i >= 0; i--) {
    band.lineTo(ribbon.bottom[i].dx, ribbon.bottom[i].dy);
  }
  band.close();

  final lowerEdge = Path()..addPolygon(ribbon.bottom, false);

  canvas.save();
  final shadowArea = Path.from(lowerEdge)
    ..lineTo(width, y + tear * 3)
    ..lineTo(0, y + tear * 3)
    ..close();
  canvas.clipPath(shadowArea);
  canvas.drawPath(
    lowerEdge.shift(Offset(0, tear * 0.22)),
    Paint()
      ..color = const Color(0x4A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tear * 0.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(0.7, tear * 0.28),
      ),
  );
  canvas.restore();

  canvas.drawPath(
    band,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, y - tear),
        Offset(0, y + tear),
        const [Color(0xFFFFFFFF), Color(0xFFFBFAF7), Color(0xFFE4E1DB)],
        const [0.0, 0.5, 1.0],
      ),
  );

  // Crushed fibres inside the torn edge.
  canvas.save();
  canvas.clipPath(band);
  final fibre = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.5, tear * 0.07);
  final fibreCount = math.max(20, (width / 7).round());
  for (var i = 0; i < fibreCount; i++) {
    final u = i / fibreCount;
    final n = _noise(u * 47, seed + 303);
    final m = _noise(u * 19, seed + 401);
    final x = width * u;
    final len = width * (0.006 + 0.022 * m);
    final start = Offset(x, y + tear * (n - 0.5) * 1.6);
    fibre.color = Color.fromARGB(
      (22 + 46 * n).round(),
      126,
      118,
      108,
    );
    canvas.drawLine(
      start,
      Offset(x + len, start.dy + (m - 0.5) * tear * 0.3),
      fibre,
    );
  }
  canvas.restore();

  // Loose fibres hanging over the strip below.
  final hair = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(0.5, tear * 0.055);
  final hairCount = math.max(24, (width / 9).round());
  for (var i = 0; i < hairCount; i++) {
    final u = (i + 0.5) / hairCount;
    final n = _hash(i, seed + 509);
    if (n < 0.45) continue;
    final anchor = ribbon.bottom[(u * (ribbon.bottom.length - 1)).round()];
    hair.color = Color.fromARGB((90 + 110 * n).round(), 255, 255, 255);
    canvas.drawLine(
      anchor,
      Offset(
        anchor.dx + (n - 0.5) * tear * 0.5,
        anchor.dy + tear * (0.06 + 0.18 * n),
      ),
      hair,
    );
  }

  // Soften the cut where the picture above meets the paper edge.
  canvas.drawPath(
    Path()..addPolygon(ribbon.top, false),
    Paint()
      ..color = const Color(0x4DFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, tear * 0.06),
  );
}

class _Ribbon {
  const _Ribbon(this.top, this.bottom);

  final List<Offset> top;
  final List<Offset> bottom;
}

/// Outlines of the torn paper edge. Both curves always straddle [y], so the
/// pictures meeting at the seam stay hidden underneath.
_Ribbon _ribbon({
  required double width,
  required double y,
  required double tear,
  required int seed,
}) {
  final count = math.max(60, (width / 2).round());
  final top = <Offset>[];
  final bottom = <Offset>[];

  for (var i = 0; i <= count; i++) {
    final u = i / count;
    final x = width * u;

    // Long wander plus shorter rips decide where the tear runs.
    final drift = tear *
        (_signed(_noise(u * 2.4, seed)) * 0.55 +
            _signed(_noise(u * 8.3, seed + 37)) * 0.22);
    // Exposed paper core: mostly a hairline, now and then a wider flap.
    final width01 = _noise(u * 6.1, seed + 211);
    final flap = _noise(u * 2.9, seed + 347);
    final core = tear *
        (0.05 + 0.34 * width01 * width01 + 0.3 * flap * flap * flap);
    // Per-point grain keeps the outline fibrous rather than smooth.
    final grainTop = tear * 0.1 * _signed(_hash(i, seed + 91));
    final grainBottom = tear * 0.1 * _signed(_hash(i, seed + 157));

    // Occasional fibre gives way and takes a deeper bite.
    final bite = _noise(u * 4.7, seed + 271);
    final extra = bite > 0.9 ? tear * (bite - 0.9) * 2.6 : 0.0;

    final above = math.max(0.3, core - drift + grainTop);
    final below = math.max(0.3, core + drift + grainBottom + extra);
    top.add(Offset(x, y - above));
    bottom.add(Offset(x, y + below));
  }

  return _Ribbon(top, bottom);
}

double _signed(double unit) => unit * 2 - 1;

double _noise(double x, int seed) {
  final i = x.floor();
  final f = x - i;
  final a = _hash(i, seed);
  final b = _hash(i + 1, seed);
  final t = f * f * (3 - 2 * f);
  return a + (b - a) * t;
}

double _hash(int i, int seed) {
  var h = (i * 0x27d4eb2d) ^ (seed * 0x165667b1);
  h = (h ^ (h >> 15)) * 0x2545f491;
  h = h ^ (h >> 13);
  return (h & 0xffffff) / 0xffffff;
}
