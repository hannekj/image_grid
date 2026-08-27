import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editor_chrome.dart';
import 'overlay_text.dart';

/// Shared size slider + presets for text and sticker overlays.
class OverlaySizeControls extends StatelessWidget {
  const OverlaySizeControls({
    super.key,
    required this.fontSize,
    required this.onChanged,
  });

  final double fontSize;
  final ValueChanged<double> onChanged;

  static const presets = [16.0, 24.0, 36.0, 56.0, 88.0];

  @override
  Widget build(BuildContext context) {
    final value = fontSize.clamp(overlayTextMinSize, overlayTextMaxSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mindre',
              onPressed: () => onChanged(
                (value - 2).clamp(overlayTextMinSize, overlayTextMaxSize),
              ),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.text_decrease, size: 20),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppTheme.matcha,
                  inactiveTrackColor: AppTheme.line,
                  thumbColor: AppTheme.ink,
                  overlayColor: AppTheme.matcha.withValues(alpha: 0.16),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: overlayTextMinSize,
                  max: overlayTextMaxSize,
                  onChanged: onChanged,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Større',
              onPressed: () => onChanged(
                (value + 2).clamp(overlayTextMinSize, overlayTextMaxSize),
              ),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.text_increase, size: 20),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${value.round()}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: EditorChrome.spaceSm),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final selected = (value - preset).abs() < 0.6;
              return Material(
                color: selected
                    ? AppTheme.matcha.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => onChanged(preset),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: Text(
                        '${preset.round()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppTheme.ink : AppTheme.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
