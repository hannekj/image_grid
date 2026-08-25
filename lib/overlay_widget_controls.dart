import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'color_scrub_strip.dart';
import 'editor_chrome.dart';
import 'overlay_text.dart';
import 'widget_picker.dart';

enum _WidgetSection { color, format, font }

class OverlayWidgetControls extends StatefulWidget {
  const OverlayWidgetControls({
    super.key,
    required this.overlays,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddMessage,
    required this.onAddLocation,
    required this.onAddDate,
    required this.onAddTime,
    required this.onAddWeather,
    this.onAddPageNumber,
    required this.onChanged,
    required this.onRemove,
    required this.onEdit,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddMessage;
  final VoidCallback onAddLocation;
  final VoidCallback onAddDate;
  final VoidCallback onAddTime;
  final VoidCallback onAddWeather;
  final VoidCallback? onAddPageNumber;
  final ValueChanged<OverlayText> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onEdit;

  @override
  State<OverlayWidgetControls> createState() => _OverlayWidgetControlsState();
}

class _OverlayWidgetControlsState extends State<OverlayWidgetControls> {
  _WidgetSection _section = _WidgetSection.color;
  bool _adding = false;

  List<int> get _widgetIndexes => [
        for (var i = 0; i < widget.overlays.length; i++)
          if (widget.overlays[i].isWidgetOverlay) i,
      ];

  OverlayText? get _current {
    final index = widget.selectedIndex;
    if (index == null || index < 0 || index >= widget.overlays.length) {
      return null;
    }
    final overlay = widget.overlays[index];
    return overlay.isWidgetOverlay ? overlay : null;
  }

  List<_WidgetSection> _sectionsFor(OverlayText current) {
    return [
      _WidgetSection.color,
      if (current.isDate) _WidgetSection.format,
      if (current.isMessage) _WidgetSection.font,
    ];
  }

  Widget get _picker => WidgetPickerGrid(
        onAddMessage: () {
          setState(() => _adding = false);
          widget.onAddMessage();
        },
        onAddLocation: () {
          setState(() => _adding = false);
          widget.onAddLocation();
        },
        onAddDate: () {
          setState(() => _adding = false);
          widget.onAddDate();
        },
        onAddTime: () {
          setState(() => _adding = false);
          widget.onAddTime();
        },
        onAddWeather: () {
          setState(() => _adding = false);
          widget.onAddWeather();
        },
        onAddPageNumber: widget.onAddPageNumber == null
            ? null
            : () {
                setState(() => _adding = false);
                widget.onAddPageNumber!();
              },
      );

  @override
  void didUpdateWidget(covariant OverlayWidgetControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _current;
    if (current != null && !_sectionsFor(current).contains(_section)) {
      _section = _WidgetSection.color;
    }
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex != null) {
      _adding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_widgetIndexes.isEmpty || _adding) {
      return _picker;
    }

    final current = _current;
    if (current == null) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Velg en sticker på bildet',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          ),
          IconButton(
            tooltip: 'Legg til',
            onPressed: () => setState(() => _adding = true),
            icon: const Icon(Icons.add),
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
            Expanded(
              child: SizedBox(
                height: EditorChrome.tabRowHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sections.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: EditorChrome.spaceSm),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return EditorSegmentTab(
                      label: switch (section) {
                        _WidgetSection.color =>
                          current.isMessage ? 'Boble' : 'Farge',
                        _WidgetSection.format => 'Format',
                        _WidgetSection.font => 'Font',
                      },
                      selected: _section == section,
                      onTap: () => setState(() => _section = section),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              tooltip: 'Rediger',
              onPressed: () => widget.onEdit(widget.selectedIndex!),
              icon: const Icon(Icons.edit_outlined, size: 20),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              tooltip: 'Legg til',
              onPressed: () => setState(() => _adding = true),
              icon: const Icon(Icons.add, size: 20),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              tooltip: 'Fjern',
              onPressed: widget.onRemove,
              icon: const Icon(Icons.close, size: 20),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: EditorChrome.spaceSm),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: switch (_section) {
              _WidgetSection.color => ColorScrubStrip(
                  colors: overlayBubbleColors,
                  labels: overlayBubbleColorLabels,
                  selected: current.effectiveBubbleColor,
                  onChanged: (color) =>
                      widget.onChanged(current.withBubbleColor(color)),
                ),
              _WidgetSection.format => ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _DateFormatChip(
                      label: overlayDateLabelNumeric(),
                      selected: overlayDateLooksNumeric(current.value),
                      onTap: () => widget.onChanged(
                        current.copyWith(
                          value: overlayDateReformat(
                            current.value,
                            numeric: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: EditorChrome.spaceSm),
                    _DateFormatChip(
                      label: overlayDateLabelLong(),
                      selected: !overlayDateLooksNumeric(current.value),
                      onTap: () => widget.onChanged(
                        current.copyWith(
                          value: overlayDateReformat(
                            current.value,
                            numeric: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              _WidgetSection.font => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: overlayFonts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: EditorChrome.spaceSm),
                  itemBuilder: (context, index) {
                    final font = overlayFonts[index];
                    final selected = current.fontId == font.id;
                    return _FontChoice(
                      font: font,
                      selected: selected,
                      onTap: () =>
                          widget.onChanged(current.copyWith(fontId: font.id)),
                    );
                  },
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _DateFormatChip extends StatelessWidget {
  const _DateFormatChip({
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
      color: selected
          ? AppTheme.matcha.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppTheme.ink : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _FontChoice extends StatelessWidget {
  const _FontChoice({
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
      color: selected
          ? AppTheme.matcha.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            font.label,
            style: font.style(
              fontSize: 13,
              color: selected ? AppTheme.ink : AppTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}
