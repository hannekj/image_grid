import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editor_chrome.dart';
import 'overlay_text.dart';

/// Slider for pill background opacity on translucent stickers.
class OverlayOpacityControls extends StatelessWidget {
  const OverlayOpacityControls({
    super.key,
    required this.opacity,
    required this.onChanged,
  });

  final double opacity;
  final ValueChanged<double> onChanged;

  static const minOpacity = 0.25;
  static const maxOpacity = 1.0;
  static const presets = [0.4, 0.55, 0.72, 0.85, 1.0];

  @override
  Widget build(BuildContext context) {
    final value = opacity.clamp(minOpacity, maxOpacity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mer gjennomsiktig',
              onPressed: () => onChanged(
                (value - 0.05).clamp(minOpacity, maxOpacity),
              ),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.opacity, size: 20),
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
                  value: value,
                  min: minOpacity,
                  max: maxOpacity,
                  onChanged: onChanged,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Mindre gjennomsiktig',
              onPressed: () => onChanged(
                (value + 0.05).clamp(minOpacity, maxOpacity),
              ),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.opacity_outlined, size: 20),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${(value * 100).round()} %',
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
              final selected = (value - preset).abs() < 0.03;
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
                        '${(preset * 100).round()} %',
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
