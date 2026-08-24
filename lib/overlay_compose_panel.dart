import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'editor_chrome.dart';
import 'overlay_text.dart';
import 'overlay_text_controls.dart';
import 'overlay_widget_controls.dart';

enum OverlayComposeTab { text, sticker, template }

/// Combined text / sticker / template panel for a cleaner editor chrome.
class OverlayComposePanel extends StatefulWidget {
  const OverlayComposePanel({
    super.key,
    required this.overlays,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddText,
    required this.onAddMessage,
    required this.onAddLocation,
    required this.onAddDate,
    required this.onAddTime,
    required this.onAddWeather,
    this.onAddPageNumber,
    required this.onAddTemplate,
    required this.onChanged,
    required this.onRemove,
    required this.onEdit,
    this.initialTab = OverlayComposeTab.text,
  });

  final List<OverlayText> overlays;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddText;
  final VoidCallback onAddMessage;
  final VoidCallback onAddLocation;
  final VoidCallback onAddDate;
  final VoidCallback onAddTime;
  final VoidCallback onAddWeather;
  final VoidCallback? onAddPageNumber;
  final VoidCallback onAddTemplate;
  final ValueChanged<OverlayText> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onEdit;
  final OverlayComposeTab initialTab;

  @override
  State<OverlayComposePanel> createState() => _OverlayComposePanelState();
}

class _OverlayComposePanelState extends State<OverlayComposePanel> {
  late OverlayComposeTab _tab = widget.initialTab;

  @override
  void didUpdateWidget(covariant OverlayComposePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.selectedIndex;
    if (index == null || index < 0 || index >= widget.overlays.length) {
      return;
    }
    final overlay = widget.overlays[index];
    if (overlay.isWidgetOverlay && _tab == OverlayComposeTab.text) {
      _tab = OverlayComposeTab.sticker;
    } else if (overlay.kind == OverlayKind.text &&
        _tab == OverlayComposeTab.sticker) {
      _tab = OverlayComposeTab.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: EditorChrome.panelHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: EditorChrome.tabRowHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                EditorSegmentTab(
                  label: 'Tekst',
                  selected: _tab == OverlayComposeTab.text,
                  onTap: () => setState(() => _tab = OverlayComposeTab.text),
                ),
                const SizedBox(width: EditorChrome.spaceSm),
                EditorSegmentTab(
                  label: 'Sticker',
                  selected: _tab == OverlayComposeTab.sticker,
                  onTap: () => setState(() => _tab = OverlayComposeTab.sticker),
                ),
                const SizedBox(width: EditorChrome.spaceSm),
                EditorSegmentTab(
                  label: 'Mal',
                  selected: _tab == OverlayComposeTab.template,
                  onTap: () =>
                      setState(() => _tab = OverlayComposeTab.template),
                ),
              ],
            ),
          ),
          const SizedBox(height: EditorChrome.spaceMd),
          Expanded(
            child: switch (_tab) {
              OverlayComposeTab.text => OverlayTextControls(
                  overlays: widget.overlays,
                  selectedIndex: widget.selectedIndex,
                  onSelect: widget.onSelect,
                  onAddText: widget.onAddText,
                  onChanged: widget.onChanged,
                  onRemove: widget.onRemove,
                  onEdit: widget.onEdit,
                ),
              OverlayComposeTab.sticker => OverlayWidgetControls(
                  overlays: widget.overlays,
                  selectedIndex: widget.selectedIndex,
                  onSelect: widget.onSelect,
                  onAddMessage: widget.onAddMessage,
                  onAddLocation: widget.onAddLocation,
                  onAddDate: widget.onAddDate,
                  onAddTime: widget.onAddTime,
                  onAddWeather: widget.onAddWeather,
                  onAddPageNumber: widget.onAddPageNumber,
                  onChanged: widget.onChanged,
                  onRemove: widget.onRemove,
                  onEdit: widget.onEdit,
                ),
              OverlayComposeTab.template => _TemplateTab(
                  onAddTemplate: widget.onAddTemplate,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _TemplateTab extends StatelessWidget {
  const _TemplateTab({required this.onAddTemplate});

  final VoidCallback onAddTemplate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Ferdige tekstmaler for tittel og undertittel.',
            style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.3),
          ),
        ),
        const SizedBox(width: EditorChrome.spaceMd),
        TextButton(
          onPressed: onAddTemplate,
          child: const Text('Velg mal'),
        ),
      ],
    );
  }
}
