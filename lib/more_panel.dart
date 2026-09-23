import 'package:flutter/material.dart';

import 'app_copy.dart';
import 'app_theme.dart';
import 'film_look.dart';
import 'overlay_text.dart';
import 'overlay_widget_controls.dart';

enum _MoreSection { home, stickers, filter }

/// Secondary editor actions under the dock’s Mer tool.
class MorePanel extends StatefulWidget {
  const MorePanel({
    super.key,
    required this.enabled,
    required this.onSaveDraft,
    required this.onSaveToPhotos,
    required this.onAddPathText,
    required this.onAddTemplate,
    required this.filter,
    required this.grain,
    required this.onFilterChanged,
    required this.onGrainChanged,
    required this.overlays,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddMessage,
    required this.onAddLocation,
    required this.onAddCoordinates,
    required this.onAddDate,
    required this.onAddTime,
    required this.onAddWeather,
    this.onAddPageNumber,
    required this.onChanged,
    required this.onRemove,
    required this.onEdit,
    this.openStickers = false,
  });

  final bool enabled;
  final VoidCallback onSaveDraft;
  final VoidCallback onSaveToPhotos;
  final VoidCallback onAddPathText;
  final VoidCallback onAddTemplate;
  final PhotoFilter filter;
  final bool grain;
  final ValueChanged<PhotoFilter> onFilterChanged;
  final ValueChanged<bool> onGrainChanged;
  final List<OverlayText> overlays;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddMessage;
  final VoidCallback onAddLocation;
  final VoidCallback onAddCoordinates;
  final VoidCallback onAddDate;
  final VoidCallback onAddTime;
  final VoidCallback onAddWeather;
  final VoidCallback? onAddPageNumber;
  final ValueChanged<OverlayText> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onEdit;
  final bool openStickers;

  @override
  State<MorePanel> createState() => _MorePanelState();
}

class _MorePanelState extends State<MorePanel> {
  late _MoreSection _section =
      widget.openStickers ? _MoreSection.stickers : _MoreSection.home;

  @override
  void didUpdateWidget(covariant MorePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openStickers && !oldWidget.openStickers) {
      _section = _MoreSection.stickers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_section) {
      _MoreSection.stickers => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackToMore(onTap: () => setState(() => _section = _MoreSection.home)),
            OverlayWidgetControls(
              overlays: widget.overlays,
              selectedIndex: widget.selectedIndex,
              onSelect: widget.onSelect,
              onAddMessage: widget.onAddMessage,
              onAddLocation: widget.onAddLocation,
              onAddCoordinates: widget.onAddCoordinates,
              onAddDate: widget.onAddDate,
              onAddTime: widget.onAddTime,
              onAddWeather: widget.onAddWeather,
              onAddPageNumber: widget.onAddPageNumber,
              onChanged: widget.onChanged,
              onRemove: widget.onRemove,
              onEdit: widget.onEdit,
            ),
          ],
        ),
      _MoreSection.filter => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackToMore(onTap: () => setState(() => _section = _MoreSection.home)),
            FilterLookControls(
              filter: widget.filter,
              grain: widget.grain,
              onFilterChanged: widget.onFilterChanged,
              onGrainChanged: widget.onGrainChanged,
            ),
          ],
        ),
      _MoreSection.home => SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return switch (index) {
                0 => _MoreTile(
                    icon: Icons.filter_vintage_outlined,
                    label: 'Filter',
                    onTap: () => setState(() => _section = _MoreSection.filter),
                  ),
                1 => _MoreTile(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Stickers',
                    onTap: () => setState(() => _section = _MoreSection.stickers),
                  ),
                2 => _MoreTile(
                    icon: Icons.gesture,
                    label: 'Tegnet tekst',
                    onTap: widget.onAddPathText,
                  ),
                3 => _MoreTile(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Mal',
                    onTap: widget.onAddTemplate,
                  ),
                4 => _MoreTile(
                    icon: Icons.bookmark_add_outlined,
                    label: AppCopy.saveDraft,
                    onTap: widget.enabled ? widget.onSaveDraft : null,
                  ),
                _ => _MoreTile(
                    icon: Icons.file_download_outlined,
                    label: AppCopy.saveToPhotos,
                    onTap: widget.enabled ? widget.onSaveToPhotos : null,
                  ),
              };
            },
          ),
        ),
    };
  }
}

class _BackToMore extends StatelessWidget {
  const _BackToMore({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Mer'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.muted,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
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

    return SizedBox(
      width: 80,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: AppTheme.mist,
              shape: const CircleBorder(),
              child: SizedBox(
                width: 34,
                height: 34,
                child: Icon(icon, size: 18, color: color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.15,
                fontWeight: FontWeight.w500,
                color: enabled
                    ? AppTheme.muted
                    : AppTheme.muted.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
