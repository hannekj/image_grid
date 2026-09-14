import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'bead_text.dart';
import 'color_scrub_strip.dart';
import 'editor_chrome.dart';
import 'overlay_text.dart';
import 'overlay_size_controls.dart';
import 'plate_scrub_strip.dart';

enum _TextSection { color, plate, font, size, style }

class OverlayTextControls extends StatefulWidget {
  const OverlayTextControls({
    super.key,
    required this.overlays,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddText,
    required this.onChanged,
    required this.onRemove,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddText;
  final ValueChanged<OverlayText> onChanged;
  final VoidCallback onRemove;

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
    final overlay = widget.overlays[index];
    return overlay.isPlainText ? overlay : null;
  }

  List<_TextSection> get _sections {
    final current = _current;
    if (current != null && current.isPathText) {
      return const [
        _TextSection.color,
        _TextSection.font,
        _TextSection.size,
        _TextSection.style,
      ];
    }
    return _TextSection.values;
  }

  @override
  void didUpdateWidget(covariant OverlayTextControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _current;
    if (current == null && _section != _TextSection.color) {
      _section = _TextSection.color;
    } else if (current != null &&
        current.isPathText &&
        _section == _TextSection.plate) {
      _section = _TextSection.size;
    }
  }

  void _rotateSelected() {
    final current = _current;
    if (current == null) return;
    widget.onChanged(current.withNextQuarterTurn());
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    if (current == null) {
      // Text is auto-placed when opening the tool; this is only a brief
      // fallback while selection catches up, or when a non-text overlay
      // is selected.
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Juster tekst på bildet',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          ),
          IconButton(
            tooltip: 'Ny tekst',
            onPressed: widget.onAddText,
            icon: const Icon(Icons.add),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: EditorChrome.tabRowHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sections.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: EditorChrome.spaceSm),
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    return EditorSegmentTab(
                      label: switch (section) {
                        _TextSection.color => 'Farge',
                        _TextSection.plate => 'Plate',
                        _TextSection.font => 'Font',
                        _TextSection.size => 'Størrelse',
                        _TextSection.style => 'Stil',
                      },
                      selected: _section == section,
                      onTap: () => setState(() => _section = section),
                    );
                  },
                ),
              ),
            ),
            _ActionIcon(
              tooltip: 'Ny tekst',
              icon: Icons.add,
              onPressed: widget.onAddText,
            ),
            _ActionIcon(
              tooltip: 'Fjern',
              icon: Icons.close,
              onPressed: widget.onRemove,
            ),
          ],
        ),
        const SizedBox(height: EditorChrome.spaceSm),
        Align(
          alignment: Alignment.centerLeft,
          child: switch (_section) {
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
                fontId: current.fontId,
                onChanged: (style) =>
                    widget.onChanged(current.copyWith(plateStyle: style)),
              ),
            _TextSection.font => SizedBox(
                height: EditorChrome.stripHeight,
                width: double.infinity,
                child: ListView.separated(
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
              ),
            _TextSection.size => OverlaySizeControls(
                fontSize: current.fontSize,
                onChanged: (size) =>
                    widget.onChanged(current.copyWith(fontSize: size)),
              ),
            _TextSection.style => SizedBox(
                height: EditorActionChip.height,
                width: double.infinity,
                child: ListView(
                  scrollDirection: Axis.horizontal,
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
                    if (!current.usesBeadLetters) ...[
                      const SizedBox(width: EditorChrome.spaceMd),
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
                    if (!current.isPathText) ...[
                      const SizedBox(width: EditorChrome.spaceMd),
                      _IconToggle(
                        tooltip: 'Roter',
                        icon: Icons.rotate_right,
                        selected: false,
                        onTap: _rotateSelected,
                      ),
                    ],
                  ],
                ),
              ),
          },
        ),
      ],
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
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
        color: selected
            ? AppTheme.matcha.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 18,
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
          child: font.id == 'perler'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BeadText(
                      text: 'A',
                      color: selected ? AppTheme.ink : AppTheme.muted,
                      fontSize: 10,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      font.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? AppTheme.ink : AppTheme.muted,
                      ),
                    ),
                  ],
                )
              : Text(
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
