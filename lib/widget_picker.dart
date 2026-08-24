import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editor_chrome.dart';

/// Compact row of sticker options — icons, not white cards.
class WidgetPickerGrid extends StatelessWidget {
  const WidgetPickerGrid({
    super.key,
    required this.onAddMessage,
    required this.onAddLocation,
    required this.onAddDate,
    required this.onAddTime,
    required this.onAddWeather,
    this.onAddPageNumber,
  });

  final VoidCallback onAddMessage;
  final VoidCallback onAddLocation;
  final VoidCallback onAddDate;
  final VoidCallback onAddTime;
  final VoidCallback onAddWeather;
  final VoidCallback? onAddPageNumber;

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, VoidCallback)>[
      ('Melding', Icons.chat_bubble_outline, onAddMessage),
      ('Sted', Icons.place_outlined, onAddLocation),
      ('Dato', Icons.calendar_today_outlined, onAddDate),
      ('Klokke', Icons.schedule, onAddTime),
      ('Vær', Icons.wb_sunny_outlined, onAddWeather),
      if (onAddPageNumber != null)
        ('Side', Icons.tag, onAddPageNumber!),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: EditorChrome.spaceSm),
      itemBuilder: (context, index) {
        final item = items[index];
        return SizedBox(
          width: 64,
          child: _PickerTile(
            label: item.$1,
            icon: item.$2,
            onTap: item.$3,
          ),
        );
      },
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppTheme.ink),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
