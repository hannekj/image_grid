import 'package:flutter/material.dart';

/// Floating toolbar for a selected image — replace, and optional actions.
class ImageAdjustToolbar extends StatelessWidget {
  const ImageAdjustToolbar({
    super.key,
    required this.onReplace,
    this.onDuplicate,
    this.onDelete,
    this.onLockToggle,
    this.locked = false,
  });

  final VoidCallback onReplace;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onLockToggle;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              _ToolbarIcon(
                icon: Icons.delete_outline,
                tooltip: 'Fjern bilde',
                onTap: onDelete!,
              ),
            if (onDuplicate != null)
              _ToolbarIcon(
                icon: Icons.control_point_duplicate,
                tooltip: 'Dupliser slide',
                onTap: onDuplicate!,
              ),
            if (onLockToggle != null)
              _ToolbarIcon(
                icon: locked ? Icons.lock : Icons.lock_open_outlined,
                tooltip: locked ? 'Lås opp' : 'Lås',
                onTap: onLockToggle!,
              ),
            _ToolbarIcon(
              icon: Icons.add_photo_alternate_outlined,
              tooltip: 'Bytt bilde',
              onTap: onReplace,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
