import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Empty-canvas nudge with one clear next step (optional second action).
///
/// Rendered as a floating card so it can sit over the empty canvas instead of
/// taking a band of its own below it.
class EmptyCanvasHint extends StatelessWidget {
  const EmptyCanvasHint({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;
    final onSecondaryAction = onSecondary;
    final hasSecondary = secondary != null && onSecondaryAction != null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _HintAction(
                label: actionLabel,
                primary: true,
                onPressed: onAction,
              ),
              if (hasSecondary)
                _HintAction(
                  label: secondary,
                  primary: false,
                  onPressed: onSecondaryAction,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintAction extends StatelessWidget {
  const _HintAction({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

    return SizedBox(
      height: 38,
      child: primary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(shape: shape),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.matcha,
                side: const BorderSide(color: AppTheme.line),
                shape: shape,
              ),
              child: Text(label),
            ),
    );
  }
}
