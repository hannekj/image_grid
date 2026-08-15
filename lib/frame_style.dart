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

/// Same palette as overlay text colors.
const strokeColors = [
  StrokeColor(label: 'Hvit', color: Color(0xFFFFFFFF)),
  StrokeColor(label: 'Krem', color: Color(0xFFF3F4EC)),
  StrokeColor(label: 'Beige', color: Color(0xFFE8E0D4)),
  StrokeColor(label: 'Peach', color: Color(0xFFF5D0C5)),
  StrokeColor(label: 'Rosa', color: Color(0xFFFFC1CC)),
  StrokeColor(label: 'Pink', color: Color(0xFFE8A0BF)),
  StrokeColor(label: 'Dusty rose', color: Color(0xFFD4A5A5)),
  StrokeColor(label: 'Gul', color: Color(0xFFF4C430)),
  StrokeColor(label: 'Gull', color: Color(0xFFE8B86D)),
  StrokeColor(label: 'Clay', color: Color(0xFFC4A484)),
  StrokeColor(label: 'Terracotta', color: Color(0xFFB85C38)),
  StrokeColor(label: 'Coral', color: Color(0xFFD97B4A)),
  StrokeColor(label: 'Matcha', color: Color(0xFF7E8F72)),
  StrokeColor(label: 'Lime', color: Color(0xFFA8C686)),
  StrokeColor(label: 'Sky', color: Color(0xFF8FA4B0)),
  StrokeColor(label: 'Baby blue', color: Color(0xFF7EB6D9)),
  StrokeColor(label: 'Denim', color: Color(0xFF6B8CAE)),
  StrokeColor(label: 'Lavendel', color: Color(0xFF9B8EC4)),
  StrokeColor(label: 'Orchid', color: Color(0xFFB07AC7)),
  StrokeColor(label: 'Burgunder', color: Color(0xFF6B3A3A)),
  StrokeColor(label: 'Navy', color: Color(0xFF2C3A4A)),
  StrokeColor(label: 'Svart', color: Color(0xFF111111)),
];

const strokeThicknesses = [
  StrokeThickness(label: 'Tynn', width: 4),
  StrokeThickness(label: 'Medium', width: 10),
  StrokeThickness(label: 'Tykk', width: 18),
];
