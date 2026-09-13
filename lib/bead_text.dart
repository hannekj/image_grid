import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'overlay_text.dart';

/// Original plastic alphabet-bead lettering (not third-party assets).
///
/// Cubes with rounded corners, a soft plastic sheen, and contrast glyphs —
/// the friendship-bracelet look without shipping anyone else's font files.
class BeadText extends StatelessWidget {
  const BeadText({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    this.textAlign = TextAlign.center,
    this.maxWidth,
  });

  final String text;
  final Color color;
  final double fontSize;
  final TextAlign textAlign;
  final double? maxWidth;

  /// Side length of one bead cube.
  double get beadSize => (fontSize * 1.28).clamp(14.0, 72.0);

  double get _gap => beadSize * 0.08;

  double get _spaceWidth => beadSize * 0.42;

  @override
  Widget build(BuildContext context) {
    final lines = text.isEmpty ? const [''] : text.split('\n');
    final align = switch (textAlign) {
      TextAlign.left || TextAlign.start => WrapAlignment.start,
      TextAlign.right || TextAlign.end => WrapAlignment.end,
      _ => WrapAlignment.center,
    };
    final cross = switch (textAlign) {
      TextAlign.left || TextAlign.start => CrossAxisAlignment.start,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };

    Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) SizedBox(height: _gap * 1.4),
          _BeadLine(
            text: lines[i],
            color: color,
            beadSize: beadSize,
            gap: _gap,
            spaceWidth: _spaceWidth,
            alignment: align,
          ),
        ],
      ],
    );

    if (maxWidth != null) {
      column = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: column,
      );
    }
    return column;
  }
}

class _BeadLine extends StatelessWidget {
  const _BeadLine({
    required this.text,
    required this.color,
    required this.beadSize,
    required this.gap,
    required this.spaceWidth,
    required this.alignment,
  });

  final String text;
  final Color color;
  final double beadSize;
  final double gap;
  final double spaceWidth;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      // Keep a hit-target so selection chrome isn't ~0px wide.
      return SizedBox(width: beadSize * 0.75, height: beadSize * 0.35);
    }

    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final rune in text.runes)
          _glyph(String.fromCharCode(rune)),
      ],
    );
  }

  Widget _glyph(String raw) {
    if (raw == ' ') {
      return SizedBox(width: spaceWidth, height: beadSize);
    }
    // Classic cube beads show capitals; keep digits/symbols as-is.
    final glyph = RegExp(r'[a-zæøåäöü]').hasMatch(raw)
        ? raw.toUpperCase()
        : raw;
    return _AlphabetBead(
      glyph: glyph,
      color: color,
      size: beadSize,
    );
  }
}

class _AlphabetBead extends StatelessWidget {
  const _AlphabetBead({
    required this.glyph,
    required this.color,
    required this.size,
  });

  final String glyph;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Very light text colors make white beads vanish on the cream canvas —
    // fall back to a warm plastic body so the letters stay readable.
    final body = color.computeLuminance() > 0.85
        ? const Color(0xFFF2EDE4)
        : color;
    final letterColor = overlayContrastColor(body);
    final radius = size * 0.18;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BeadPainter(color: body, radius: radius),
        child: Center(
          child: Text(
            glyph,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: size * 0.48,
              fontWeight: FontWeight.w700,
              height: 1,
              color: letterColor,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _BeadPainter extends CustomPainter {
  const _BeadPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Soft drop under the bead.
    canvas.drawRRect(
      rrect.shift(Offset(0, size.height * 0.06)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          math.max(0.8, size.shortestSide * 0.08),
        ),
    );

    // Plastic body.
    canvas.drawRRect(rrect, Paint()..color = color);

    // Top-left gloss.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.10),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );

    // Inner rim so the cube edge reads at small sizes.
    canvas.drawRRect(
      rrect.deflate(size.shortestSide * 0.04),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, size.shortestSide * 0.035)
        ..color = Colors.black.withValues(alpha: 0.12),
    );

    // Tiny specular streak.
    final streak = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.12,
        size.width * 0.42,
        size.height * 0.12,
      ),
      Radius.circular(radius * 0.6),
    );
    canvas.drawRRect(
      streak,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _BeadPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
