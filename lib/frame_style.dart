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

const strokeColors = [
  StrokeColor(label: 'Svart', color: Colors.black),
  StrokeColor(label: 'Hvit', color: Colors.white),
  StrokeColor(label: 'Beige', color: Color(0xFFE8E0D4)),
  StrokeColor(label: 'Terracotta', color: Color(0xFFB85C38)),
  StrokeColor(label: 'Sage', color: Color(0xFF7D8B74)),
];

const strokeThicknesses = [
  StrokeThickness(label: 'Tynn', width: 4),
  StrokeThickness(label: 'Medium', width: 10),
  StrokeThickness(label: 'Tykk', width: 18),
];
