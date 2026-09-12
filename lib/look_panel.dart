import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editor_chrome.dart';
import 'film_look.dart';
import 'frame_controls.dart';
import 'frame_style.dart';

/// The panel covers two separate things: the frame drawn around the photos and
/// the look applied to the photos themselves. Keeping them as the only two tabs
/// makes it obvious which controls belong to which.
enum _LookSection { filter, frame }

class LookPanel extends StatefulWidget {
  const LookPanel({
    super.key,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.filter,
    required this.grain,
    required this.onKindChanged,
    required this.onColorChanged,
    required this.onThicknessChanged,
    required this.onFilterChanged,
    required this.onGrainChanged,
    this.onApplyToAll,
    this.applyToAllLabel,
  });

  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final PhotoFilter filter;
  final bool grain;
  final ValueChanged<FrameKind> onKindChanged;
  final ValueChanged<StrokeColor> onColorChanged;
  final ValueChanged<StrokeThickness> onThicknessChanged;
  final ValueChanged<PhotoFilter> onFilterChanged;
  final ValueChanged<bool> onGrainChanged;
  final VoidCallback? onApplyToAll;
  final String? applyToAllLabel;

  @override
  State<LookPanel> createState() => _LookPanelState();
}

class _LookPanelState extends State<LookPanel> {
  _LookSection _section = _LookSection.filter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: EditorChrome.tabRowHeight,
          child: Row(
            children: [
              for (final section in _LookSection.values) ...[
                if (section != _LookSection.filter)
                  const SizedBox(width: EditorChrome.spaceSm),
                EditorSegmentTab(
                  label: switch (section) {
                    _LookSection.filter => 'Filter',
                    _LookSection.frame => 'Ramme',
                  },
                  selected: _section == section,
                  onTap: () => setState(() => _section = section),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: EditorChrome.spaceSm),
        switch (_section) {
          _LookSection.filter => FilterLookControls(
            filter: widget.filter,
            grain: widget.grain,
            onFilterChanged: widget.onFilterChanged,
            onGrainChanged: widget.onGrainChanged,
          ),
          _LookSection.frame => _FrameSection(
            kind: widget.kind,
            color: widget.color,
            thickness: widget.thickness,
            onKindChanged: widget.onKindChanged,
            onColorChanged: widget.onColorChanged,
            onThicknessChanged: widget.onThicknessChanged,
          ),
        },
        if (widget.onApplyToAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onApplyToAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppTheme.matcha,
              ),
              child: Text(widget.applyToAllLabel ?? 'Bruk stil på alle sider'),
            ),
          ),
      ],
    );
  }
}

/// Width first, then colour — the colour row only appears once there is a
/// frame to colour.
class _FrameSection extends StatelessWidget {
  const _FrameSection({
    required this.kind,
    required this.color,
    required this.thickness,
    required this.onKindChanged,
    required this.onColorChanged,
    required this.onThicknessChanged,
  });

  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final ValueChanged<FrameKind> onKindChanged;
  final ValueChanged<StrokeColor> onColorChanged;
  final ValueChanged<StrokeThickness> onThicknessChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrameWeightControls(
          kind: kind,
          thickness: thickness,
          onKindChanged: onKindChanged,
          onThicknessChanged: onThicknessChanged,
        ),
        if (kind == FrameKind.stroke) ...[
          const SizedBox(height: EditorChrome.spaceSm),
          FrameColorControls(color: color, onColorChanged: onColorChanged),
        ],
      ],
    );
  }
}
