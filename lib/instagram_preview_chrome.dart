import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Soft Instagram-like chrome for preview only (not exported).
class InstagramPreviewChrome extends StatelessWidget {
  const InstagramPreviewChrome({
    super.key,
    required this.child,
    this.enabled = true,
    this.slideCount = 1,
    this.currentIndex = 0,
  });

  final Widget child;
  final bool enabled;
  final int slideCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: _ChromeOverlay(
            slideCount: slideCount,
            currentIndex: currentIndex,
          ),
        ),
      ],
    );
  }
}

class _ChromeOverlay extends StatelessWidget {
  const _ChromeOverlay({
    required this.slideCount,
    required this.currentIndex,
  });

  final int slideCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
            child: const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 20),
                child: Row(
                  children: [
                    _AvatarDot(),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'forhåndsvisning',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Icon(Icons.more_horiz, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.favorite_border, color: Colors.white, size: 22),
                      SizedBox(width: 14),
                      Icon(Icons.chat_bubble_outline, color: Colors.white, size: 21),
                      SizedBox(width: 14),
                      Icon(Icons.send_outlined, color: Colors.white, size: 21),
                      Spacer(),
                      Icon(Icons.bookmark_border, color: Colors.white, size: 22),
                    ],
                  ),
                  if (slideCount > 1) ...[
                    const SizedBox(height: 10),
                    _SlideDots(
                      count: slideCount,
                      currentIndex: currentIndex,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlideDots extends StatelessWidget {
  const _SlideDots({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  static const _maxDots = 8;

  @override
  Widget build(BuildContext context) {
    if (count <= _maxDots) {
      return Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            _Dot(active: i == currentIndex),
          ],
        ],
      );
    }

    return Text(
      '${currentIndex + 1}/$count',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
        color: AppTheme.matcha.withValues(alpha: 0.85),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 6 : 5,
      height: active ? 6 : 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: active ? 0.95 : 0.45),
      ),
    );
  }
}
