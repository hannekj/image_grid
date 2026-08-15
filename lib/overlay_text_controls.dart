import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'color_scrub_strip.dart';
import 'overlay_text.dart';
import 'plate_scrub_strip.dart';

enum _TextSection { color, plate, font }

class OverlayTextControls extends StatefulWidget {
  const OverlayTextControls({
    super.key,
    required this.overlay,
    required this.onAdd,
    required this.onChanged,
    required this.onRemove,
  });

  final OverlayText? overlay;
  final VoidCallback onAdd;
  final ValueChanged<OverlayText> onChanged;
  final VoidCallback onRemove;

  @override
  State<OverlayTextControls> createState() => _OverlayTextControlsState();
}

class _OverlayTextControlsState extends State<OverlayTextControls> {
  _TextSection _section = _TextSection.color;

  @override
  Widget build(BuildContext context) {
    final current = widget.overlay;
    if (current == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.onAdd,
          icon: const Icon(Icons.title),
          label: const Text('Legg til tekst'),
        ),
      );
    }

    return Column(
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
            Container(width: 1, height: 22, color: const Color(0xFFD7DCD0)),
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
            const Spacer(),
            IconButton(
              tooltip: 'Fjern tekst',
              onPressed: widget.onRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final section in _TextSection.values) ...[
              if (section != _TextSection.values.first)
                const SizedBox(width: 8),
              _SectionTab(
                label: switch (section) {
                  _TextSection.color => 'Farge',
                  _TextSection.plate => 'Plate',
                  _TextSection.font => 'Font',
                },
                selected: _section == section,
                onTap: () => setState(() => _section = section),
              ),
            ],
          ],
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
              fontId: current.fontId,
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
        },
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
