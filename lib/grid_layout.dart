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

  bool get isOverlayFrame => id == 'overlay-frame';

  bool get isAlbumGrid => id == 'album-grid';

  bool get isStripGrid => id == 'strip-grid';

  bool get isCheckerGrid => id == 'checker-grid';

  bool get isFilmHorizontal => id == 'film-h';

  bool get isFilmVertical => id == 'film-v';

  bool get isFilmStrip => isFilmHorizontal || isFilmVertical;

  bool get isEdgeToEdgeCanvas => isCheckerGrid || isStripGrid;

  bool get usesCreamCanvas => isDump || isBooth || isFilmStrip || isAlbumGrid;

  LayoutGroup get group {
    if (isDump || isBooth || isFilmStrip) return LayoutGroup.film;
    if (isReaction || isOverlayFrame || isCheckerGrid) return LayoutGroup.special;
    return LayoutGroup.classic;
  }
}

enum LayoutGroup { classic, film, special }

extension LayoutGroupX on LayoutGroup {
  String get label => switch (this) {
        LayoutGroup.classic => 'Klassisk',
        LayoutGroup.film => 'Film',
        LayoutGroup.special => 'Spesial',
      };
}

List<GridLayout> layoutsInGroup(LayoutGroup group) {
  return [
    for (final layout in gridLayouts)
      if (layout.group == group) layout,
  ];
}

const gridLayouts = [
  GridLayout(
    id: '1-col',
    label: '1 kolonne',
    rows: [
      LayoutRow(flex: 1, cells: [1]),
    ],
  ),
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
    id: '6-rows',
    label: '6 rader',
    rows: [
      LayoutRow(flex: 1, cells: [1]),
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
    id: '4-cols',
    label: '4 kolonner',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
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
    id: '2x3',
    label: '2 × 3',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
      LayoutRow(flex: 1, cells: [1, 1]),
      LayoutRow(flex: 1, cells: [1, 1]),
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
    id: 'album-grid',
    label: 'Album',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'strip-grid',
    label: 'Tre striper',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
    ],
  ),
  GridLayout(
    id: '4x6',
    label: '4 × 6',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'mosaic-top-full',
    label: 'Stort + hel bunn',
    rows: [
      LayoutRow(flex: 2, cells: [1]),
      LayoutRow(flex: 1, cells: [1]),
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
    id: 'mosaic-14',
    label: 'Stort + 4',
    rows: [
      LayoutRow(flex: 2, cells: [1]),
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
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
    id: 'mosaic-212',
    label: '2 + 1 + 2',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1, 1]),
    ],
  ),
  GridLayout(
    id: 'mosaic-5',
    label: 'Mosaikk 5',
    rows: [
      LayoutRow(flex: 1, cells: [1, 2]),
      LayoutRow(flex: 1, cells: [1, 2]),
      LayoutRow(flex: 1, cells: [1]),
      LayoutRow(flex: 1, cells: [1, 1]),
    ],
  ),
  GridLayout(
    id: 'mosaic-21',
    label: 'Mosaikk 7',
    rows: [
      LayoutRow(flex: 1, cells: [2, 1]),
      LayoutRow(flex: 1, cells: [1, 2]),
    ],
  ),
  GridLayout(
    id: 'mosaic-8',
    label: 'Mosaikk 8',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
      LayoutRow(flex: 1, cells: [1, 1, 1]),
      LayoutRow(flex: 1, cells: [1, 2]),
      LayoutRow(flex: 1, cells: [2, 1]),
      LayoutRow(flex: 1, cells: [1]),
    ],
  ),
  GridLayout(
    id: 'overlay-frame',
    label: 'Ramme over',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
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
    id: 'film-h',
    label: 'Film',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'film-v',
    label: 'Film stående',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1, 1]),
    ],
  ),
  GridLayout(
    id: 'reaction',
    label: 'Reaksjon',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1]),
    ],
  ),
  GridLayout(
    id: 'checker-grid',
    label: 'Summer recap',
    rows: [
      LayoutRow(flex: 1, cells: [1, 1, 1, 1, 1]),
    ],
  ),
];

GridLayout get defaultGridLayout =>
    gridLayouts.firstWhere((layout) => layout.id == '2x2');
