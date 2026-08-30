import 'grid_layout.dart';

/// A starter deck for the carousel editor.
class CarouselTemplate {
  const CarouselTemplate({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.steps,
  });

  final String id;
  final String label;
  final String subtitle;

  /// `null` = single-image slide; `spread-*` = two-page spread; otherwise grid id.
  final List<String?> steps;
}

GridLayout carouselTemplateLayout(String layoutId) {
  return gridLayouts.firstWhere(
    (layout) => layout.id == layoutId,
    orElse: () => defaultGridLayout,
  );
}

const carouselTemplates = [
  CarouselTemplate(
    id: 'spread',
    label: 'Over to sider',
    subtitle: 'Forside · 2 små + stort bilde',
    steps: [null, 'spread-span'],
  ),
  CarouselTemplate(
    id: 'story',
    label: 'Historie',
    subtitle: 'Intro · 3 grids · avslutning',
    steps: [null, '2x2', 'mosaic-13', 'booth', null],
  ),
  CarouselTemplate(
    id: 'film',
    label: 'Film',
    subtitle: 'Dump · film · booth',
    steps: ['dump', 'film-h', 'booth', null, null],
  ),
  CarouselTemplate(
    id: 'grids',
    label: 'Grid-mix',
    subtitle: 'Fem ulike oppsett',
    steps: ['2x2', 'mosaic-5', 'reaction', '3-cols', 'dump'],
  ),
];
