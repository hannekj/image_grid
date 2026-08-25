import 'package:flutter/material.dart';

/// Airport-style split-flap / flip clock for time stickers.
class FlipClockDisplay extends StatelessWidget {
  const FlipClockDisplay({
    super.key,
    required this.time,
    this.digitHeight = 42,
    this.flapColor = const Color(0xFFE5E5EA),
    this.digitColor = const Color(0xFF1C1C1E),
    this.splitColor,
  });

  final String time;
  final double digitHeight;
  final Color flapColor;
  final Color digitColor;
  final Color? splitColor;

  /// Digits HHMM from values like `19:45`, `12 55`, or `1255`.
  static String digitsFrom(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) return digits.substring(0, 4);
    if (digits.isEmpty) {
      final now = DateTime.now();
      return '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';
    }
    return digits.padLeft(4, '0');
  }

  @override
  Widget build(BuildContext context) {
    final digits = digitsFrom(time);
    final flapWidth = digitHeight * 0.62;
    final gap = digitHeight * 0.08;
    final groupGap = digitHeight * 0.22;
    final radius = digitHeight * 0.12;
    final fontSize = digitHeight * 0.72;
    final lineColor = splitColor ?? digitColor;

    Widget flap(String char) {
      return _FlipFlap(
        digit: char,
        width: flapWidth,
        height: digitHeight,
        radius: radius,
        fontSize: fontSize,
        flapColor: flapColor,
        digitColor: digitColor,
        splitColor: lineColor,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        flap(digits[0]),
        SizedBox(width: gap),
        flap(digits[1]),
        SizedBox(width: groupGap),
        flap(digits[2]),
        SizedBox(width: gap),
        flap(digits[3]),
      ],
    );
  }
}

class _FlipFlap extends StatelessWidget {
  const _FlipFlap({
    required this.digit,
    required this.width,
    required this.height,
    required this.radius,
    required this.fontSize,
    required this.flapColor,
    required this.digitColor,
    required this.splitColor,
  });

  final String digit;
  final double width;
  final double height;
  final double radius;
  final double fontSize;
  final Color flapColor;
  final Color digitColor;
  final Color splitColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: flapColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: height * 0.08,
              offset: Offset(0, height * 0.04),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  digit,
                  style: TextStyle(
                    color: digitColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w300,
                    height: 1,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              // Soft top/bottom shade for flap depth.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.08),
                      ],
                      stops: const [0, 0.35, 0.65, 1],
                    ),
                  ),
                ),
              ),
              // Split line through the middle.
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 1.2,
                  color: splitColor.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
