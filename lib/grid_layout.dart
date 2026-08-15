class LayoutRow {
  const LayoutRow({required this.flex, required this.cells});

  final int flex;
  final List<int> cells;
}

class GridLayout {
  const GridLayout({required this.id, required this.label, required this.rows});

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

  bool get isDump => id == 'dump';

  bool get isReaction => id == 'reaction';

  bool get isBooth => id == 'booth';

  bool get usesCreamCanvas => isDump || isBooth;
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
    id: '4-rows',
    label: '4 rader',
    rows: [
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
    ],
  ),
  GridLayout(
    id: '5-rows',
    label: '5 rader',
    rows: [
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
    ],
  ),
  GridLayout(
    id: '2-cols',
    label: '2 kolonner',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
    ],
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
  GridLayout(
    id: '3-cols',
    label: '3 kolonner',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'two-hero',
    label: 'To + stort',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
      LayoutRow(flex: 2, cells: [1]),
    ],
  ),
  GridLayout(
    id: '3x2',
    label: '3 × 2',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
    ],
  ),
  GridLayout(
    id: '3x3',
    label: '3 × 3',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'mosaic-13',
    label: '1 + 3',
    rows: [
      LayoutRow(flex: 2, cells: [1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'mosaic-31',
    label: '3 + 1',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 2, cells: [1]),
    ],
  ),
  GridLayout(
    id: 'l-left',
    label: 'L-stor',
    rows: [
      LayoutRow(flex: 1, cells: [2, 1]),
      LayoutRow(flex: 1, cells: [2, 1]),
    ],
  ),
  GridLayout(
    id: 'l-right',
    label: 'L-speil',
    rows: [
      LayoutRow(flex: 1, cells: [1, 2]),
      LayoutRow(flex: 1, cells: [1, 2]),
    ],
  ),
  GridLayout(
    id: 'hero-uneven',
    label: '1 + 2',
    rows: [
      LayoutRow(flex: 2, cells: [1]),
      LayoutRow(flex: 1, cells: [2, 1]),
    ],
  ),
  GridLayout(
    id: 'mosaic-122',
    label: '1 + 2 + 2',
    rows: [
      LayoutRow(flex: 2, cells: [1]),
      LayoutRow(flex: 1, cells: [2, 1]),
      LayoutRow(flex: 1, cells: [1, 2]),
    ],
  ),
  GridLayout(
    id: 'dump',
    label: 'Dump',
    rows: [
      LayoutRow(flex: 1, cells: [1]),
    ],
  ),
  GridLayout(
    id: 'booth',
    label: 'Booth',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'reaction',
    label: 'Reaksjon',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
    ],
  ),
];

GridLayout get defaultGridLayout =>
    gridLayouts.firstWhere((layout) => layout.id == '2x2');
