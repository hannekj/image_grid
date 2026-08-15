import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_grid/film_look.dart';
import 'package:image_grid/main.dart';

Future<void> _openEditor(WidgetTester tester) async {
  await tester.pumpWidget(const ImageGridApp());
  await tester.tap(find.text('Lag innlegg'));
  await tester.pumpAndSettle();
}

Future<void> _tapLayout(WidgetTester tester, String tooltip) async {
  final finder = find.byTooltip(tooltip);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('home opens editor with layout tools', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    expect(find.text('2 × 2'), findsOneWidget);
    expect(find.text('Oppsett'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('Look'), findsOneWidget);
    expect(find.text('Tekst'), findsOneWidget);
    expect(find.text('Del'), findsOneWidget);
    expect(find.byTooltip('Dump'), findsOneWidget);
    expect(find.byTooltip('Booth'), findsOneWidget);
    expect(find.byTooltip('1 + 3'), findsOneWidget);
    expect(find.byTooltip('1 + 2 + 2'), findsOneWidget);
    expect(find.byTooltip('L-stor'), findsOneWidget);
    expect(find.byTooltip('2 rader'), findsOneWidget);
    expect(find.byTooltip('2 kolonner'), findsOneWidget);
    expect(find.text('4:5'), findsNothing);
    expect(find.text('Trykk for å legge inn bilder'), findsOneWidget);
    expect(find.text('Velg bilder'), findsNothing);
  });

  testWidgets('editor shows frame style controls under Look', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    await tester.tap(find.text('Look'));
    await tester.pump();

    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Farge'), findsNothing);
    expect(find.text('Tykkelse'), findsNothing);
    expect(find.text('Korn'), findsOneWidget);
    expect(find.text('Dato'), findsOneWidget);
    expect(find.text('Ingen ramme'), findsOneWidget);
    expect(find.text('Ramme'), findsOneWidget);
    expect(find.text('Tynn'), findsNothing);

    await tester.tap(find.text('Ramme'));
    await tester.pump();
    expect(find.text('Farge'), findsOneWidget);
    expect(find.text('Tykkelse'), findsOneWidget);
    expect(find.text('Tynn'), findsNothing);

    await tester.tap(find.text('Tykkelse'));
    await tester.pump();
    expect(find.text('Tynn'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Tykk'), findsOneWidget);

    await tester.tap(find.text('Korn'));
    await tester.pump();
    expect(find.text('Ingen ramme'), findsNothing);
    expect(find.text('Korn'), findsWidgets);

    await tester.tap(find.text('Tekst'));
    await tester.pump();

    expect(find.text('Legg til tekst'), findsNothing);
    expect(find.text('Tekst'), findsWidgets);
    expect(find.text('Sted'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tekst'));
    await tester.pumpAndSettle();

    expect(find.text('Skriv teksten her'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lofoten');
    await tester.tap(find.text('Ferdig'));
    await tester.pumpAndSettle();

    expect(find.text('Lofoten'), findsOneWidget);
    expect(find.text('Farge'), findsOneWidget);
    expect(find.text('Plate'), findsOneWidget);
    expect(find.text('Font'), findsOneWidget);
    expect(find.text('Annet'), findsOneWidget);
    expect(find.byTooltip('Legg til tekst'), findsOneWidget);
    expect(find.byTooltip('Legg til sted'), findsOneWidget);
    expect(find.byTooltip('Rediger tekst'), findsOneWidget);
    expect(find.byIcon(Icons.format_align_center), findsNothing);
    expect(find.byIcon(Icons.blur_on), findsNothing);
    expect(find.text('Aa'), findsNothing);
    expect(find.text('Serif'), findsNothing);

    await tester.tap(find.text('Plate'));
    await tester.pump();
    expect(find.text('Aa'), findsWidgets);

    await tester.tap(find.text('Font'));
    await tester.pump();
    expect(find.text('Liten'), findsNothing);
    expect(find.text('Serif'), findsOneWidget);
    expect(find.text('Hånd'), findsOneWidget);
    expect(find.text('Nunito'), findsOneWidget);
    expect(find.text('Beanie'), findsOneWidget);

    await tester.tap(find.text('Annet'));
    await tester.pump();
    expect(find.byIcon(Icons.format_align_center), findsOneWidget);
    expect(find.byIcon(Icons.blur_on), findsOneWidget);

    await tester.tap(find.byTooltip('Legg til sted'));
    await tester.pumpAndSettle();
    expect(find.text('F.eks. Lofoten'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Svolvær');
    await tester.tap(find.text('Ferdig'));
    await tester.pumpAndSettle();
    expect(find.text('Svolvær'), findsWidgets);
    expect(find.byIcon(Icons.location_on), findsWidgets);

    await tester.tap(find.text('Oppsett'));
    await tester.pump();
    await _tapLayout(tester, '2 kolonner');

    expect(find.text('2 kolonner'), findsOneWidget);
  });

  testWidgets('empty editor pops without discard dialog', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Forkast bildene?'), findsNothing);
    expect(find.text('Bildekarusell'), findsOneWidget);
  });

  testWidgets('home Karusell and Beskjær open their tools', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Karusell'));
    await tester.pumpAndSettle();
    expect(find.text('Lagre alle'), findsOneWidget);
    expect(find.text('Del alle'), findsOneWidget);
    expect(find.text('Slide 1 av 2'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beskjær'));
    await tester.pumpAndSettle();
    expect(find.text('Beskjær'), findsWidgets);
    expect(find.text('Del'), findsOneWidget);
    expect(find.text('Lagre'), findsOneWidget);
    expect(find.text('Trykk for å legge inn et bilde'), findsOneWidget);
  });

  testWidgets('dump layout opens polaroid editor', (WidgetTester tester) async {
    await _openEditor(tester);
    await _tapLayout(tester, 'Dump');

    expect(find.text('Dump'), findsOneWidget);
    expect(find.text('Trykk for å legge inn bilder'), findsOneWidget);

    await tester.tap(find.text('Look'));
    await tester.pump();
    await tester.tap(find.text('Dato'));
    await tester.pump();
    await tester.tap(find.text('Dato').last);
    await tester.pump();
    expect(find.text(filmDateLabel()), findsOneWidget);
  });

  testWidgets('booth layout opens photobooth strip', (WidgetTester tester) async {
    await _openEditor(tester);
    await _tapLayout(tester, 'Booth');

    expect(find.text('Booth'), findsOneWidget);
    expect(find.text('Trykk for å legge inn bilder'), findsOneWidget);
  });

  testWidgets('reaction layout opens overlay editor', (WidgetTester tester) async {
    await _openEditor(tester);
    await _tapLayout(tester, 'Reaksjon');

    expect(find.text('Reaksjon'), findsOneWidget);
    expect(find.text('Trykk for å legge inn bilder'), findsOneWidget);
  });

  testWidgets('asymmetric mosaics are selectable', (WidgetTester tester) async {
    await _openEditor(tester);

    await _tapLayout(tester, '1 + 3');
    expect(find.text('1 + 3'), findsOneWidget);

    await _tapLayout(tester, '1 + 2 + 2');
    expect(find.text('1 + 2 + 2'), findsOneWidget);

    await _tapLayout(tester, 'L-stor');
    expect(find.text('L-stor'), findsOneWidget);
  });

  testWidgets('format tab shows size chips', (WidgetTester tester) async {
    await _openEditor(tester);
    await tester.tap(find.text('Format'));
    await tester.pump();

    expect(find.text('4:5'), findsOneWidget);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('9:16'), findsOneWidget);
    expect(find.text('Innlegg'), findsOneWidget);
    expect(find.text('Kvadrat'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
  });
}
