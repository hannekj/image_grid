import 'package:flutter/material.dart';

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

/// Dark → light, with a mix of neutrals and soft accents.
const strokeColors = [
  StrokeColor(label: 'Svart', color: Color(0xFF111111)),
  StrokeColor(label: 'Navy', color: Color(0xFF2C3A4A)),
  StrokeColor(label: 'Burgunder', color: Color(0xFF6B3A3A)),
  StrokeColor(label: 'Terracotta', color: Color(0xFFB85C38)),
  StrokeColor(label: 'Matcha', color: Color(0xFF7E8F72)),
  StrokeColor(label: 'Sky', color: Color(0xFF8FA4B0)),
  StrokeColor(label: 'Rose', color: Color(0xFFD4A5A5)),
  StrokeColor(label: 'Clay', color: Color(0xFFC4A484)),
  StrokeColor(label: 'Beige', color: Color(0xFFE8E0D4)),
  StrokeColor(label: 'Krem', color: Color(0xFFF3F4EC)),
  StrokeColor(label: 'Hvit', color: Color(0xFFFFFFFF)),
];

const strokeThicknesses = [
  StrokeThickness(label: 'Tynn', width: 4),
  StrokeThickness(label: 'Medium', width: 10),
  StrokeThickness(label: 'Tykk', width: 18),
];
