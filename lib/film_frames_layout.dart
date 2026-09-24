import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Contact-sheet style: black film borders around a 2×3 grid of windows.
class FilmFramesLayout {
  FilmFramesLayout._();

  static const slotCount = 6;
  static const columns = 2;
  static const rows = 3;
  static const defaultLabel = 'Filmrammer';

  static const bodyColor = Color(0xFF0A0A0A);
  static const markColor = Color(0xFFD8D4CC);
}

class FilmFramesFrame extends StatelessWidget {
  const FilmFramesFrame({
    super.key,
    required this.slots,
  });

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    assert(slots.length == FilmFramesLayout.slotCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final gap = shortest * 0.04;
        final padX = constraints.maxWidth * 0.05;
        final padY = constraints.maxHeight * 0.045;

        return ColoredBox(
          color: FilmFramesLayout.bodyColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(padX, padY, padX, padY),
            child: Column(
              children: [
                for (var row = 0; row < FilmFramesLayout.rows; row++) ...[
                  if (row > 0) SizedBox(height: gap),
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0;
                            col < FilmFramesLayout.columns;
                            col++) ...[
                          if (col > 0) SizedBox(width: gap),
                          Expanded(
                            child: _FilmFrameCell(
                              index: row * FilmFramesLayout.columns + col,
                              child: slots[
                                  row * FilmFramesLayout.columns + col],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilmFrameCell extends StatelessWidget {
  const _FilmFrameCell({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final edge = math.max(14.0, w * 0.14);
        final inset = math.max(2.5, math.min(w, h) * 0.03);
        final frameNo = 10 + index * 7;

        return ColoredBox(
          color: FilmFramesLayout.bodyColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: inset,
                top: inset,
                right: edge,
                bottom: inset,
                child: ColoredBox(
                  color: const Color(0xFF2C2C2C),
                  child: child,
                ),
              ),
              Positioned(
                right: 0,
                top: inset * 0.5,
                bottom: inset * 0.5,
                width: edge,
                child: _FilmEdgeMarks(
                  frameNumber: frameNo,
                  fontSize: (edge * 0.38).clamp(5.5, 9.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilmEdgeMarks extends StatelessWidget {
  const _FilmEdgeMarks({
    required this.frameNumber,
    required this.fontSize,
  });

  final int frameNumber;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = FilmFramesLayout.markColor.withValues(alpha: 0.88);
    final style = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
      height: 1.0,
    );

    return Column(
      children: [
        Text('$frameNumber', style: style),
        Icon(Icons.play_arrow, size: fontSize * 1.15, color: color),
        Expanded(
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'KODAK PORTRA 400',
                maxLines: 1,
                softWrap: false,
                style: style.copyWith(
                  fontSize: fontSize * 0.95,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
        Text('${(frameNumber + 3) % 100}', style: style),
      ],
    );
  }
}
