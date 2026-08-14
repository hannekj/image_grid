import 'package:flutter/material.dart';

class LayoutRow {
  const LayoutRow({required this.flex, required this.cells});

  final int flex;
  final List<int> cells;
}

class GridLayout {
  const GridLayout({
    required this.id,
    required this.label,
    required this.rows,
  });

  final String id;
  final String label;
  final List<LayoutRow> rows;

  int get slotCount {
    var count = 0;
    for (final row in rows) {
      count += row.cells.length;
    }
    return count;
  }

  int get rowFlexTotal {
    var total = 0;
    for (final row in rows) {
      total += row.flex;
    }
    return total;
  }
}

const gridLayouts = [
  GridLayout(
    id: '2-rows',
    label: '2 rader',
    rows: [
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
    ],
  ),
  GridLayout(
    id: '3-rows',
    label: '3 rader',
    rows: [
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
    ],
  ),
  GridLayout(
    id: '2-cols',
    label: '2 kolonner',
    rows: [LayoutRow(flex: 1, cells: [1, 1])],
  ),
  GridLayout(
    id: 'hero-two',
    label: 'Stort + to',
    rows: [
      LayoutRow(flex: 2, cells: [1]),
      LayoutRow(flex: 1, cells: [1, 1]),
    ],
  ),
  GridLayout(
    id: '2x2',
    label: '2 × 2',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
      LayoutRow(flex: 1, cells: [1, 1]),
    ],
  ),
];
