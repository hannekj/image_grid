import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:image_grid/film_look.dart';
import 'package:image_grid/main.dart';

void main() {
  testWidgets('home Grid button opens editor with layout tools', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ImageGridApp());

    expect(find.text('Grid'), findsOneWidget);
    expect(find.text('Karusell'), findsOneWidget);
    expect(find.text('Beskjær'), findsOneWidget);

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();

    expect(find.text('2 × 2'), findsOneWidget);
    expect(find.text('Oppsett'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('Look'), findsOneWidget);
    expect(find.text('Tekst'), findsOneWidget);
    expect(find.text('Del'), findsOneWidget);
    expect(find.byTooltip('Dump'), findsOneWidget);
    expect(find.byTooltip('2 rader'), findsOneWidget);
    expect(find.byTooltip('2 kolonner'), findsOneWidget);
    expect(find.text('4:5'), findsNothing);
    expect(find.text('Velg bilder'), findsNothing);
  });

  testWidgets('editor shows frame style controls under Look', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Look'));
    await tester.pump();

    expect(find.text('Ingen ramme'), findsOneWidget);
    expect(find.text('Korn'), findsOneWidget);
    expect(find.text('Dato'), findsOneWidget);
    expect(find.text('Strek'), findsOneWidget);
    expect(find.text('Tynn'), findsNothing);

    await tester.tap(find.text('Strek'));
    await tester.pump();

    expect(find.text('Tynn'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Tykk'), findsOneWidget);

    await tester.tap(find.text('Tekst'));
    await tester.pump();

    expect(find.text('Legg til tekst'), findsOneWidget);
    await tester.tap(find.text('Legg til tekst'));
    await tester.pumpAndSettle();

    expect(find.text('Skriv teksten her'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lofoten');
    await tester.tap(find.text('Ferdig'));
    await tester.pumpAndSettle();

    expect(find.text('Lofoten'), findsOneWidget);
    expect(find.text('Plate'), findsOneWidget);
    expect(find.text('Liten'), findsOneWidget);
    expect(find.text('Serif'), findsOneWidget);
    expect(find.text('Hånd'), findsOneWidget);

    await tester.tap(find.text('Oppsett'));
    await tester.pump();
    await tester.tap(find.byTooltip('2 kolonner'));
    await tester.pumpAndSettle();

    expect(find.text('2 kolonner'), findsOneWidget);
  });

  testWidgets('empty editor pops without discard dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Forkast bildene?'), findsNothing);
    expect(find.text('Grid'), findsOneWidget);
  });

  testWidgets('home Karusell and Beskjær open their tools', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Karusell'));
    await tester.pumpAndSettle();
    expect(find.text('Last ned alle'), findsOneWidget);
    expect(find.text('Del alle'), findsOneWidget);
    expect(find.text('Slide 1 av 2'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beskjær'));
    await tester.pumpAndSettle();
    expect(find.text('Beskjær'), findsWidgets);
    expect(find.text('Del'), findsOneWidget);
    expect(find.text('Last ned'), findsOneWidget);
    expect(find.text('Velg bilde'), findsOneWidget);
  });

  testWidgets('dump layout opens polaroid editor', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dump'));
    await tester.pumpAndSettle();

    expect(find.text('Dump'), findsOneWidget);

    await tester.tap(find.text('Look'));
    await tester.pump();
    await tester.tap(find.text('Dato'));
    await tester.pump();
    expect(find.text(filmDateLabel()), findsOneWidget);
  });

  testWidgets('format tab shows size chips', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Format'));
    await tester.pump();

    expect(find.text('4:5'), findsOneWidget);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('9:16'), findsOneWidget);
    expect(find.text('Innlegg'), findsNothing);
  });
}
