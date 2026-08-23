import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'color_scrub_strip.dart';
import 'overlay_text.dart';
import 'plate_scrub_strip.dart';

enum _TextSection { color, plate, font, other }

class OverlayTextControls extends StatefulWidget {
  const OverlayTextControls({
    super.key,
    required this.overlays,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddText,
    required this.onAddLocation,
    required this.onAddEditorial,
    required this.onChanged,
    required this.onRemove,
    required this.onEdit,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddText;
  final VoidCallback onAddLocation;
  final VoidCallback onAddEditorial;
  final ValueChanged<OverlayText> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onEdit;

  @override
  State<OverlayTextControls> createState() => _OverlayTextControlsState();
}

class _OverlayTextControlsState extends State<OverlayTextControls> {
  _TextSection _section = _TextSection.color;

  OverlayText? get _current {
    final index = widget.selectedIndex;
    if (index == null || index < 0 || index >= widget.overlays.length) {
      return null;
    }
    return widget.overlays[index];
  }

  List<_TextSection> _sectionsFor(OverlayText current) {
    if (current.isLocation) {
      return const [_TextSection.color, _TextSection.plate];
    }
    return _TextSection.values;
  }

  @override
  void didUpdateWidget(covariant OverlayTextControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _current;
    if (current != null && !_sectionsFor(current).contains(_section)) {
      _section = _TextSection.color;
    }
  }

  void _rotateSelected() {
    final current = _current;
    if (current == null || current.isLocation) return;
    widget.onChanged(current.withNextQuarterTurn());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overlays.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onAddText,
                  icon: const Icon(Icons.title),
                  label: const Text('Tekst'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onAddLocation,
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Sted'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onAddEditorial,
            icon: const Icon(Icons.auto_stories_outlined),
            label: const Text('Editorial'),
          ),
        ],
      );
    }

    final current = _current;
    if (current == null) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Velg tekst eller sted på bildet',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          ),
          IconButton(
            tooltip: 'Legg til tekst',
            onPressed: widget.onAddText,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Legg til sted',
            onPressed: widget.onAddLocation,
            icon: const Icon(Icons.location_on_outlined),
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
            if (widget.overlays.length > 1)
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.overlays.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final overlay = widget.overlays[index];
                      final selected = widget.selectedIndex == index;
                      final label = overlay.value.trim().isEmpty
                          ? (overlay.isLocation
                              ? 'Sted ${index + 1}'
                              : 'Tekst ${index + 1}')
                          : overlay.value;
                      return _TextChip(
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
            _ActionIcon(
              tooltip: current.isLocation ? 'Rediger sted' : 'Rediger tekst',
              icon: Icons.edit_outlined,
              onPressed: widget.selectedIndex == null
                  ? null
                  : () => widget.onEdit(widget.selectedIndex!),
            ),
            _ActionIcon(
              tooltip: 'Legg til tekst',
              icon: Icons.add,
              onPressed: widget.onAddText,
            ),
            _ActionIcon(
              tooltip: 'Legg til sted',
              icon: Icons.location_on_outlined,
              onPressed: widget.onAddLocation,
            ),
            _ActionIcon(
              tooltip: 'Editorial',
              icon: Icons.auto_stories_outlined,
              onPressed: widget.onAddEditorial,
            ),
            _ActionIcon(
              tooltip: 'Roter tekst',
              icon: Icons.rotate_right,
              onPressed: current.isLocation ? null : _rotateSelected,
            ),
            _ActionIcon(
              tooltip: 'Fjern',
              icon: Icons.close,
              onPressed: widget.onRemove,
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
                  _TextSection.color => 'Farge',
                  _TextSection.plate =>
                    current.isLocation ? 'Bakgrunn' : 'Plate',
                  _TextSection.font => 'Font',
                  _TextSection.other => 'Annet',
                },
                selected: _section == section,
                onTap: () => setState(() => _section = section),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        switch (_section) {
          _TextSection.color => ColorScrubStrip(
              colors: overlayTextColors,
              labels: overlayTextColorLabels,
              selected: current.color,
              onChanged: (color) =>
                  widget.onChanged(current.copyWith(color: color)),
            ),
          _TextSection.plate => PlateScrubStrip(
              selected: current.plateStyle,
              textColor: current.color,
              fontId: current.isLocation ? 'sans' : current.fontId,
              onChanged: (style) =>
                  widget.onChanged(current.copyWith(plateStyle: style)),
            ),
          _TextSection.font => SizedBox(
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
          _TextSection.other => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconToggle(
                      tooltip: 'Venstre',
                      icon: Icons.format_align_left,
                      selected: current.textAlign == TextAlign.left,
                      onTap: () => widget.onChanged(
                        current.withTextAlign(TextAlign.left),
                      ),
                    ),
                    _IconToggle(
                      tooltip: 'Midt',
                      icon: Icons.format_align_center,
                      selected: current.textAlign == TextAlign.center,
                      onTap: () => widget.onChanged(
                        current.withTextAlign(TextAlign.center),
                      ),
                    ),
                    _IconToggle(
                      tooltip: 'Høyre',
                      icon: Icons.format_align_right,
                      selected: current.textAlign == TextAlign.right,
                      onTap: () => widget.onChanged(
                        current.withTextAlign(TextAlign.right),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 22,
                      color: const Color(0xFFD7DCD0),
                    ),
                    const SizedBox(width: 10),
                    _IconToggle(
                      tooltip: 'Ingen effekt',
                      icon: Icons.title,
                      selected: current.effect == OverlayTextEffect.none,
                      onTap: () => widget.onChanged(
                        current.copyWith(effect: OverlayTextEffect.none),
                      ),
                    ),
                    _IconToggle(
                      tooltip: 'Skygge',
                      icon: Icons.blur_on,
                      selected: current.effect == OverlayTextEffect.shadow,
                      onTap: () => widget.onChanged(
                        current.copyWith(effect: OverlayTextEffect.shadow),
                      ),
                    ),
                    _IconToggle(
                      tooltip: 'Kant',
                      icon: Icons.border_style,
                      selected: current.effect == OverlayTextEffect.outline,
                      onTap: () => widget.onChanged(
                        current.copyWith(effect: OverlayTextEffect.outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Rotasjon: ${current.rotationDegrees.round()}°',
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                Row(
                  children: [
                    _RotationChip(
                      label: '0°',
                      selected: current.rotationDegrees.abs() < 3,
                      onTap: () =>
                          widget.onChanged(current.withRotationDegrees(0)),
                    ),
                    const SizedBox(width: 6),
                    _RotationChip(
                      label: '-90°',
                      selected: (current.rotationDegrees + 90).abs() < 3,
                      onTap: () =>
                          widget.onChanged(current.withRotationDegrees(-90)),
                    ),
                    const SizedBox(width: 6),
                    _RotationChip(
                      label: '90°',
                      selected: (current.rotationDegrees - 90).abs() < 3,
                      onTap: () =>
                          widget.onChanged(current.withRotationDegrees(90)),
                    ),
                  ],
                ),
                Slider(
                  value: current.rotationDegrees.clamp(-180, 180),
                  min: -180,
                  max: 180,
                  divisions: 72,
                  label: '${current.rotationDegrees.round()}°',
                  onChanged: (value) =>
                      widget.onChanged(current.withRotationDegrees(value)),
                ),
                Text(
                  'Bokstavavstand: ${current.letterSpacing.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                Slider(
                  value: current.letterSpacing.clamp(0, 8),
                  min: 0,
                  max: 8,
                  divisions: 16,
                  onChanged: (value) =>
                      widget.onChanged(current.copyWith(letterSpacing: value)),
                ),
              ],
            ),
        },
      ],
    );
  }
}

class _TextChip extends StatelessWidget {
  const _TextChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isLocation = false,
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
              if (isLocation) ...[
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: selected ? Colors.white : AppTheme.muted,
                ),
                const SizedBox(width: 4),
              ],
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

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(icon, size: 20),
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? const Color(0xFF2C3028) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF5C6358),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotationChip extends StatelessWidget {
  const _RotationChip({
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
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
