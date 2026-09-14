import 'package:flutter/material.dart';

import 'overlay_text.dart';
import 'overlay_text_controls.dart';

/// Style controls for the Tekst dock tool.
///
/// Text is placed on the canvas when the tool opens — this panel is only for
/// styling the selected overlay.
class OverlayComposePanel extends StatelessWidget {
  const OverlayComposePanel({
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
  Widget build(BuildContext context) {
    return OverlayTextControls(
      overlays: overlays,
      selectedIndex: selectedIndex,
      onSelect: onSelect,
      onAddText: onAddText,
      onChanged: onChanged,
      onRemove: onRemove,
    );
  }
}
