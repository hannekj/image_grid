import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Soft Instagram-like chrome for preview only (not exported).
class InstagramPreviewChrome extends StatelessWidget {
  const InstagramPreviewChrome({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const IgnorePointer(
          child: _ChromeOverlay(),
        ),
      ],
    );
  }
}

class _ChromeOverlay extends StatelessWidget {
  const _ChromeOverlay();

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
            child: const Padding(
              padding: EdgeInsets.fromLTRB(14, 28, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _Dot(active: true),
                      SizedBox(width: 5),
                      _Dot(),
                      SizedBox(width: 5),
                      _Dot(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
