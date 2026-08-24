import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Shared spacing and quiet chrome for editor tool panels.
class EditorChrome {
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;

  /// One fixed height for the active tool panel body.
  static const panelHeight = 148.0;
  static const tabRowHeight = 36.0;
}

/// Text segment — selected weight + underline, no white pills.
class EditorSegmentTab extends StatelessWidget {
  const EditorSegmentTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: EditorChrome.tabRowHeight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppTheme.ink : AppTheme.muted,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 2,
                width: selected ? 18 : 0,
                decoration: BoxDecoration(
                  color: AppTheme.matcha,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet selectable tile — mist fill when selected, no white chip.
class EditorChoiceTile extends StatelessWidget {
  const EditorChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.caption,
    this.compact = false,
  });

  final String label;
  final String? caption;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.matcha.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppTheme.ink : AppTheme.muted,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: selected
                        ? AppTheme.muted
                        : AppTheme.muted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
