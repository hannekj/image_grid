import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'color_scrub_strip.dart';
import 'overlay_text.dart';
import 'widget_picker.dart';

enum _WidgetSection { color, font }

class OverlayWidgetControls extends StatefulWidget {
  const OverlayWidgetControls({
    super.key,
    required this.overlays,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddMessage,
    required this.onAddLocation,
    required this.onChanged,
    required this.onRemove,
    required this.onEdit,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddMessage;
  final VoidCallback onAddLocation;
  final ValueChanged<OverlayText> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onEdit;

  @override
  State<OverlayWidgetControls> createState() => _OverlayWidgetControlsState();
}

class _OverlayWidgetControlsState extends State<OverlayWidgetControls> {
  _WidgetSection _section = _WidgetSection.color;

  List<int> get _bubbleIndexes => [
        for (var i = 0; i < widget.overlays.length; i++)
          if (widget.overlays[i].isBubble) i,
      ];

  OverlayText? get _current {
    final index = widget.selectedIndex;
    if (index == null || index < 0 || index >= widget.overlays.length) {
      return null;
    }
    final overlay = widget.overlays[index];
    return overlay.isBubble ? overlay : null;
  }

  List<_WidgetSection> _sectionsFor(OverlayText current) {
    return [
      _WidgetSection.color,
      if (current.isMessage) _WidgetSection.font,
    ];
  }

  @override
  void didUpdateWidget(covariant OverlayWidgetControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _current;
    if (current != null && !_sectionsFor(current).contains(_section)) {
      _section = _WidgetSection.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bubbleIndexes.isEmpty) {
      return WidgetPickerGrid(
        onAddMessage: widget.onAddMessage,
        onAddLocation: widget.onAddLocation,
      );
    }

    final current = _current;
    if (current == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WidgetPickerGrid(
            onAddMessage: widget.onAddMessage,
            onAddLocation: widget.onAddLocation,
          ),
          const SizedBox(height: 8),
          const Text(
            'Velg en widget på bildet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ],
      );
    }

    final sections = _sectionsFor(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_bubbleIndexes.length > 1)
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _bubbleIndexes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, listIndex) {
                      final index = _bubbleIndexes[listIndex];
                      final overlay = widget.overlays[index];
                      final selected = widget.selectedIndex == index;
                      final label = overlay.value.trim().isEmpty
                          ? overlay.isLocation
                              ? 'Sted ${listIndex + 1}'
                              : 'Melding ${listIndex + 1}'
                          : overlay.value;
                      return _WidgetChip(
                        label: label,
                        selected: selected,
                        isLocation: overlay.isLocation,
                        onTap: () {
                          if (selected) {
                            widget.onEdit(index);
                          } else {
                            widget.onSelect(index);
                          }
                        },
                      );
                    },
                  ),
                ),
              )
            else
              const Spacer(),
            IconButton(
              tooltip: current.isLocation ? 'Rediger sted' : 'Rediger melding',
              onPressed: widget.selectedIndex == null
                  ? null
                  : () => widget.onEdit(widget.selectedIndex!),
              icon: const Icon(Icons.edit_outlined, size: 20),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Legg til melding',
              onPressed: widget.onAddMessage,
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Legg til sted',
              onPressed: widget.onAddLocation,
              icon: const Icon(Icons.location_on_outlined, size: 20),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Fjern',
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 12),
            itemCount: sections.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final section = sections[index];
              return _SectionTab(
                label: switch (section) {
                  _WidgetSection.color => 'Boble',
                  _WidgetSection.font => 'Font',
                },
                selected: _section == section,
                onTap: () => setState(() => _section = section),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        switch (_section) {
          _WidgetSection.color => ColorScrubStrip(
              colors: overlayBubbleColors,
              labels: overlayBubbleColorLabels,
              selected: current.effectiveBubbleColor,
              onChanged: (color) =>
                  widget.onChanged(current.withBubbleColor(color)),
            ),
          _WidgetSection.font => SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: overlayFonts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final font = overlayFonts[index];
                  final selected = current.fontId == font.id;
                  return _FontChip(
                    font: font,
                    selected: selected,
                    onTap: () =>
                        widget.onChanged(current.copyWith(fontId: font.id)),
                  );
                },
              ),
            ),
        },
      ],
    );
  }
}

class _WidgetChip extends StatelessWidget {
  const _WidgetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isLocation,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isLocation;

  @override
  Widget build(BuildContext context) {
    final short = label.length > 14 ? '${label.substring(0, 14)}…' : label;
    return Material(
      color: selected ? const Color(0xFF2C3028) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLocation
                    ? Icons.location_on
                    : Icons.chat_bubble_outline,
                size: 14,
                color: selected ? Colors.white : AppTheme.muted,
              ),
              const SizedBox(width: 4),
              Text(
                short,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2C3028) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final OverlayFont font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.black : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: selected ? Colors.black : const Color(0xFFCCCCCC),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            font.label,
            style: font.style(
              fontSize: 13,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
