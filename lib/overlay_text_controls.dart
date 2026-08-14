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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final color in overlayTextColors) ...[
              if (color != overlayTextColors.first) const SizedBox(width: 12),
              _ColorDot(
                color: color,
                selected: current.color == color,
                onTap: () => onChanged(current.copyWith(color: color)),
              ),
            ],
            const SizedBox(width: 16),
            FilterChip(
              label: const Text('Plate'),
              selected: current.plate,
              onSelected: (selected) {
                onChanged(current.copyWith(plate: selected));
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Fjern tekst',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        Row(
          children: [
            for (final size in overlayTextSizes) ...[
              if (size != overlayTextSizes.first) const SizedBox(width: 8),
              Expanded(
                child: _SizeChip(
                  label: size.label,
                  selected: current.fontSize == size.fontSize,
                  onTap: () {
                    onChanged(current.copyWith(fontSize: size.fontSize));
                  },
                ),
              ),
            ],
          ],
        ),
      ],
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

class _SizeChip extends StatelessWidget {
  const _SizeChip({
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = color.computeLuminance() > 0.85;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.black
                : isLight
                ? const Color(0xFFCCCCCC)
                : color,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}
