import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Centered page indicators with a sliding window when there are many slides.
class CarouselPageDots extends StatelessWidget {
  const CarouselPageDots({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.onTap,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _maxVisible = 5;
  static const _dotSpacing = 6.0;
  static const _tapSize = 24.0;

  int get _windowStart {
    if (count <= _maxVisible) return 0;
    final half = _maxVisible ~/ 2;
    var start = currentIndex - half;
    if (start < 0) return 0;
    if (start + _maxVisible > count) return count - _maxVisible;
    return start;
  }

  int get _windowEnd => math.min(_windowStart + _maxVisible, count);

  double _edgeScale(int index) {
    if (count <= _maxVisible) return 1;
    final start = _windowStart;
    final end = _windowEnd - 1;
    if (index == start && start > 0) return 0.55;
    if (index == end && end < count - 1) return 0.55;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    final start = _windowStart;
    final end = _windowEnd;

    return SizedBox(
      height: 32,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = start; index < end; index++) ...[
              if (index > start) const SizedBox(width: _dotSpacing),
              _DotButton(
                active: index == currentIndex,
                scale: _edgeScale(index),
                onTap: () => onTap(index),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DotButton extends StatelessWidget {
  const _DotButton({
    required this.active,
    required this.scale,
    required this.onTap,
  });

  final bool active;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = active ? 7.0 : 6.0;
    final size = base * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: CarouselPageDots._tapSize,
          height: CarouselPageDots._tapSize,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppTheme.matcha
                    : AppTheme.muted.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
