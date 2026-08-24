import 'package:flutter/material.dart';

import 'editor_chrome.dart';
import 'film_look.dart';
import 'frame_controls.dart';
import 'frame_style.dart';

enum _LookSection { type, color, thickness, filter }

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

  @override
  State<LookPanel> createState() => _LookPanelState();
}

class _LookPanelState extends State<LookPanel> {
  final _tabsController = ScrollController();
  _LookSection _section = _LookSection.type;

  bool get _hasFrame => widget.kind == FrameKind.stroke;

  List<_LookSection> get _sections => [
        _LookSection.type,
        if (_hasFrame) _LookSection.color,
        if (_hasFrame) _LookSection.thickness,
        _LookSection.filter,
      ];

  @override
  void dispose() {
    _tabsController.dispose();
    super.dispose();
  }

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

    return SizedBox(
      height: EditorChrome.panelHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: EditorChrome.tabRowHeight,
            width: double.infinity,
            child: ListView.separated(
              key: const PageStorageKey<String>('look-panel-tabs'),
              controller: _tabsController,
              scrollDirection: Axis.horizontal,
              itemCount: sections.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: EditorChrome.spaceSm),
              itemBuilder: (context, index) {
                final section = sections[index];
                return EditorSegmentTab(
                  label: switch (section) {
                    _LookSection.type => 'Type',
                    _LookSection.color => 'Farge',
                    _LookSection.thickness => 'Tykkelse',
                    _LookSection.filter => 'Filter',
                  },
                  selected: _section == section,
                  onTap: () => setState(() => _section = section),
                );
              },
            ),
          ),
          const SizedBox(height: EditorChrome.spaceMd),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: switch (_section) {
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
                _LookSection.filter => FilterLookControls(
                    filter: widget.filter,
                    grain: widget.grain,
                    onFilterChanged: widget.onFilterChanged,
                    onGrainChanged: widget.onGrainChanged,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
