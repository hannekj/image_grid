import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Empty-canvas call to action — just the primary pick-images button.
class EmptyCanvasHint extends StatelessWidget {
  const EmptyCanvasHint({
    super.key,
    required this.actionLabel,
    required this.onAction,
  });

  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: FilledButton(
        onPressed: onAction,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.cream,
          ),
        ),
      ),
    );
  }
}
