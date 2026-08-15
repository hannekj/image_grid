import 'package:flutter/material.dart';

import 'overlay_text.dart';

class OverlayTextControls extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final current = overlay;
    if (current == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.title),
          label: const Text('Legg til tekst'),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Farge',
                style: TextStyle(fontSize: 12, color: Color(0xFF6F7668)),
              ),
            ),
            FilterChip(
              label: const Text('Plate'),
              selected: current.plate,
              onSelected: (selected) {
                onChanged(current.copyWith(plate: selected));
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Fjern tekst',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: Row(
            children: [
              for (var i = 0; i < overlayTextColors.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: _ColorSwatch(
                    color: overlayTextColors[i],
                    label: overlayTextColorLabels[i],
                    selected: current.color.toARGB32() ==
                        overlayTextColors[i].toARGB32(),
                    onTap: () {
                      onChanged(
                        current.copyWith(color: overlayTextColors[i]),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
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
                onTap: () => onChanged(current.copyWith(fontId: font.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = color.computeLuminance() > 0.82;

    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2C3028)
                  : isLight
                  ? const Color(0xFFCCCCCC)
                  : color,
              width: selected ? 2 : 1,
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
