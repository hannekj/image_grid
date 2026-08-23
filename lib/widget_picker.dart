import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'chat_bubble.dart';

/// Compact row of widget options with inline previews.
class WidgetPickerGrid extends StatelessWidget {
  const WidgetPickerGrid({
    super.key,
    required this.onAddMessage,
    required this.onAddLocation,
  });

  final VoidCallback onAddMessage;
  final VoidCallback onAddLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WidgetPreviewCard(
            label: 'Melding',
            onTap: onAddMessage,
            child: Transform.scale(
              scale: 0.82,
              alignment: Alignment.centerLeft,
              child: const ChatBubblePreview(label: 'Hei!'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: WidgetPreviewCard(
            label: 'Sted',
            onTap: onAddLocation,
            child: Transform.scale(
              scale: 0.82,
              alignment: Alignment.centerLeft,
              child: const LocationPillPreview(label: 'Oslo'),
            ),
          ),
        ),
      ],
    );
  }
}

class WidgetPreviewCard extends StatelessWidget {
  const WidgetPreviewCard({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
