import 'package:flutter/material.dart';

import 'editor_colors.dart';

enum FrameKind { none, stroke }

class StrokeColor {
  const StrokeColor({required this.label, required this.color});

  final String label;
  final Color color;
}

class StrokeThickness {
  const StrokeThickness({required this.label, required this.width});

  final String label;
  final double width;
}

final strokeColors = [
  for (final swatch in editorSwatches)
    StrokeColor(label: swatch.label, color: swatch.color),
];

const strokeThicknesses = [
  StrokeThickness(label: 'Tynn', width: 4),
  StrokeThickness(label: 'Medium', width: 10),
  StrokeThickness(label: 'Tykk', width: 18),
];
