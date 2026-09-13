import 'package:flutter/material.dart';

import 'app_copy.dart';
import 'app_theme.dart';
import 'editor_chrome.dart';

/// Secondary editor actions under the dock’s Mer tool.
class MorePanel extends StatelessWidget {
  const MorePanel({
    super.key,
    required this.enabled,
    required this.onSaveDraft,
    required this.onSaveToPhotos,
    required this.onAddPathText,
  });

  final bool enabled;
  final VoidCallback onSaveDraft;
  final VoidCallback onSaveToPhotos;
  final VoidCallback onAddPathText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MoreTile(
            icon: Icons.gesture,
            label: 'Tegnet tekst',
            onTap: onAddPathText,
          ),
        ),
        Expanded(
          child: _MoreTile(
            icon: Icons.bookmark_add_outlined,
            label: AppCopy.saveDraft,
            onTap: enabled ? onSaveDraft : null,
          ),
        ),
        Expanded(
          child: _MoreTile(
            icon: Icons.file_download_outlined,
            label: AppCopy.saveToPhotos,
            onTap: enabled ? onSaveToPhotos : null,
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppTheme.ink : AppTheme.ink.withValues(alpha: 0.28);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: AppTheme.mist,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(icon, size: 22, color: color),
              ),
            ),
            const SizedBox(height: EditorChrome.spaceSm),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w500,
                color: enabled ? AppTheme.muted : AppTheme.muted.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
