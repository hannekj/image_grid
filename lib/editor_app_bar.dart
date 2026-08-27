import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Compact icon-only editor chrome: back · [undo redo …] · share.
class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorAppBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onShare,
    required this.moreEnabled,
    required this.moreItems,
    required this.onMoreSelected,
    this.sharing = false,
    this.shareEnabled = false,
    this.shareLabel,
    this.previewing = false,
    this.onTogglePreview,
    this.previewEnabled = false,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback? onShare;
  final bool sharing;
  final bool shareEnabled;
  final String? shareLabel;
  final bool moreEnabled;
  final List<PopupMenuEntry<String>> moreItems;
  final ValueChanged<String> onMoreSelected;
  final bool previewing;
  final VoidCallback? onTogglePreview;
  final bool previewEnabled;

  static const _barHeight = 48.0;

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.mist,
      foregroundColor: AppTheme.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _barHeight,
      centerTitle: true,
      titleSpacing: 0,
      title: const SizedBox.shrink(),
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _CircleIconButton(
            tooltip: 'Tilbake',
            icon: Icons.chevron_left_rounded,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      actions: [
        _IconCluster(
          children: [
            _ClusterIconButton(
              tooltip: 'Angre',
              icon: Icons.undo_rounded,
              onPressed: canUndo ? onUndo : null,
            ),
            _ClusterIconButton(
              tooltip: 'Gjør om',
              icon: Icons.redo_rounded,
              onPressed: canRedo ? onRedo : null,
            ),
            if (onTogglePreview != null)
              _ClusterIconButton(
                tooltip: previewing
                    ? 'Avslutt forhåndsvisning'
                    : 'Forhåndsvis',
                icon: previewing
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onPressed: previewEnabled ? onTogglePreview : null,
              ),
            PopupMenuButton<String>(
              tooltip: 'Mer',
              enabled: moreEnabled,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              offset: const Offset(0, 40),
              onSelected: onMoreSelected,
              itemBuilder: (context) => moreItems,
              child: Icon(
                Icons.more_horiz_rounded,
                size: 22,
                color: moreEnabled
                    ? AppTheme.ink
                    : AppTheme.ink.withValues(alpha: 0.28),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: _CircleIconButton(
            tooltip: shareLabel ?? 'Del',
            icon: sharing ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
            onPressed: shareEnabled && !sharing ? onShare : null,
          ),
        ),
      ],
      automaticallyImplyLeading: false,
    );
  }
}

class _IconCluster extends StatelessWidget {
  const _IconCluster({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cream,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 16,
                  color: AppTheme.line.withValues(alpha: 0.8),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _ClusterIconButton extends StatelessWidget {
  const _ClusterIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(
        icon,
        size: 20,
        color: enabled ? AppTheme.ink : AppTheme.ink.withValues(alpha: 0.28),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.cream,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 22,
              color: enabled ? AppTheme.ink : AppTheme.ink.withValues(alpha: 0.28),
            ),
          ),
        ),
      ),
    );
  }
}
