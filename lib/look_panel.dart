import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'film_look.dart';
import 'frame_controls.dart';
import 'frame_style.dart';

enum _LookSection { type, color, thickness, grain, date }

class LookPanel extends StatefulWidget {
  const LookPanel({
    super.key,
    required this.kind,
    required this.color,
    required this.thickness,
    required this.grain,
    required this.dateStamp,
    required this.onKindChanged,
    required this.onColorChanged,
    required this.onThicknessChanged,
    required this.onGrainChanged,
    required this.onDateStampChanged,
  });

  final FrameKind kind;
  final StrokeColor color;
  final StrokeThickness thickness;
  final bool grain;
  final bool dateStamp;
  final ValueChanged<FrameKind> onKindChanged;
  final ValueChanged<StrokeColor> onColorChanged;
  final ValueChanged<StrokeThickness> onThicknessChanged;
  final ValueChanged<bool> onGrainChanged;
  final ValueChanged<bool> onDateStampChanged;

  @override
  State<LookPanel> createState() => _LookPanelState();
}

class _LookPanelState extends State<LookPanel> {
  _LookSection _section = _LookSection.type;

  bool get _hasFrame => widget.kind == FrameKind.stroke;

  List<_LookSection> get _sections => [
        _LookSection.type,
        if (_hasFrame) _LookSection.color,
        if (_hasFrame) _LookSection.thickness,
        _LookSection.grain,
        _LookSection.date,
      ];

  @override
  void didUpdateWidget(covariant LookPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sections.contains(_section)) {
      _section = _LookSection.type;
    }
  }

  void _onKindChanged(FrameKind kind) {
    widget.onKindChanged(kind);
    if (kind == FrameKind.stroke) {
      setState(() => _section = _LookSection.color);
    } else if (_section == _LookSection.color ||
        _section == _LookSection.thickness) {
      setState(() => _section = _LookSection.type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
                  _LookSection.type => 'Type',
                  _LookSection.color => 'Farge',
                  _LookSection.thickness => 'Tykkelse',
                  _LookSection.grain => 'Korn',
                  _LookSection.date => 'Dato',
                },
                selected: _section == section,
                onTap: () => setState(() => _section = section),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        switch (_section) {
          _LookSection.type => FrameKindControls(
              kind: widget.kind,
              onKindChanged: _onKindChanged,
            ),
          _LookSection.color => FrameColorControls(
              color: widget.color,
              onColorChanged: widget.onColorChanged,
            ),
          _LookSection.thickness => FrameThicknessControls(
              thickness: widget.thickness,
              onThicknessChanged: widget.onThicknessChanged,
            ),
          _LookSection.grain => LookToggleChip(
              label: 'Korn',
              selected: widget.grain,
              onTap: () => widget.onGrainChanged(!widget.grain),
            ),
          _LookSection.date => LookToggleChip(
              label: 'Dato',
              selected: widget.dateStamp,
              onTap: () => widget.onDateStampChanged(!widget.dateStamp),
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
