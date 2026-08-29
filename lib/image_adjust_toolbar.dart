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
    this.compact = false,
  });

  final VoidCallback onReplace;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onLockToggle;
  final bool locked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 18 : 22),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 4,
          vertical: compact ? 0 : 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              _ToolbarIcon(
                icon: Icons.delete_outline,
                tooltip: 'Fjern bilde',
                onTap: onDelete!,
                compact: compact,
              ),
            if (onDuplicate != null)
              _ToolbarIcon(
                icon: Icons.control_point_duplicate,
                tooltip: 'Dupliser slide',
                onTap: onDuplicate!,
                compact: compact,
              ),
            if (onLockToggle != null)
              _ToolbarIcon(
                icon: locked ? Icons.lock : Icons.lock_open_outlined,
                tooltip: locked ? 'Lås opp' : 'Lås',
                onTap: onLockToggle!,
                compact: compact,
              ),
            _ToolbarIcon(
              icon: Icons.add_photo_alternate_outlined,
              tooltip: 'Bytt bilde',
              onTap: onReplace,
              compact: compact,
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
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: compact ? 18 : 20),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.all(compact ? 6 : 8),
      constraints: BoxConstraints(
        minWidth: compact ? 30 : 36,
        minHeight: compact ? 30 : 36,
      ),
    );
  }
}
