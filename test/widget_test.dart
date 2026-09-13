import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_grid/color_scrub_strip.dart';
import 'package:image_grid/frame_style.dart';
import 'package:image_grid/main.dart';

Future<void> _openEditor(WidgetTester tester) async {
  await tester.pumpWidget(const ImageGridApp());
  await tester.tap(find.text('Lag innlegg'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Collage').last);
  await tester.pumpAndSettle();
}

Future<void> _openLayoutPanel(WidgetTester tester) async {
  await tester.tap(find.text('Oppsett'));
  await tester.pumpAndSettle();
}

Future<void> _tapLayout(
  WidgetTester tester, {
  String? group,
  required String layout,
}) async {
  await _openLayoutPanel(tester);
  if (group != null) {
    await tester.tap(find.text(group));
    await tester.pumpAndSettle();
  }
  final finder = find.bySemanticsLabel(layout);
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

    expect(find.text('Oppsett'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
    expect(find.text('Stil'), findsOneWidget);
    expect(find.text('Tekst'), findsOneWidget);
    expect(find.text('Mer'), findsOneWidget);
    expect(find.byTooltip('Del'), findsOneWidget);
    expect(find.byTooltip('Angre'), findsOneWidget);
    expect(find.byTooltip('Gjør om'), findsOneWidget);
    expect(find.byTooltip('Mer'), findsOneWidget);
    expect(find.text('Velg bilder til rammen'), findsOneWidget);
    expect(find.text('Velg bilder'), findsOneWidget);

    await _openLayoutPanel(tester);
    expect(find.text('Klassisk'), findsOneWidget);
    expect(find.text('Film'), findsOneWidget);
    expect(find.text('Spesial'), findsOneWidget);
    expect(find.bySemanticsLabel('2 kolonner'), findsOneWidget);

    await tester.tap(find.text('Film'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Dump'), findsOneWidget);
  });

  testWidgets('editor shows frame style controls under Stil', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    await tester.tap(find.text('Stil'));
    await tester.pumpAndSettle();

    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Ramme'), findsOneWidget);
    expect(find.text('Korn'), findsOneWidget);
    expect(find.text('Golden'), findsOneWidget);
    expect(find.text('Flash'), findsOneWidget);
    expect(find.text('G7X'), findsOneWidget);

    await tester.tap(find.text('Ramme'));
    await tester.pumpAndSettle();
    expect(find.text('Ingen'), findsOneWidget);
    for (final option in strokeThicknesses) {
      expect(find.text(option.label), findsOneWidget);
    }

    // Picking a width turns the frame on and reveals the colour row.
    expect(find.byType(ColorScrubStrip), findsNothing);
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    expect(find.byType(ColorScrubStrip), findsOneWidget);
  });

  testWidgets('editor adds and edits text overlays', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    await tester.tap(find.text('Tekst'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Legg til tekst'));
    await tester.pumpAndSettle();

    // Plain text is placed on the canvas immediately (no dialog).
    expect(find.text('Tekst'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lofoten');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Lofoten'), findsOneWidget);
    expect(find.text('Farge'), findsOneWidget);
    expect(find.text('Plate'), findsOneWidget);
    expect(find.text('Font'), findsOneWidget);
    expect(find.text('Stil'), findsWidgets);
    expect(find.byTooltip('Legg til tekst'), findsOneWidget);
    expect(find.byTooltip('Rediger'), findsWidgets);

    await tester.tap(find.text('Sticker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sted'));
    await tester.pumpAndSettle();

    expect(find.text('F.eks. Lofoten'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Svolvær');
    await tester.tap(find.text('Ferdig'));
    await tester.pumpAndSettle();
    expect(find.text('Svolvær'), findsWidgets);
  });

  testWidgets('empty editor pops without discard dialog', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    await tester.tap(find.byTooltip('Tilbake'));
    await tester.pumpAndSettle();

    expect(find.text('Forkast bildene?'), findsNothing);
    expect(find.text('LØV'), findsOneWidget);
  });

  testWidgets('home Karusell opens its tools', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Lag innlegg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karusell').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Del'), findsOneWidget);
    expect(find.byTooltip('Angre'), findsOneWidget);
    expect(find.byTooltip('Gjør om'), findsOneWidget);
    expect(find.byTooltip('Mer'), findsOneWidget);

    await tester.tap(find.text('Sider'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Tilbake'));
    await tester.pumpAndSettle();
    expect(find.text('LØV'), findsOneWidget);
    expect(find.text('Beskjær'), findsNothing);
  });

  testWidgets('dump layout opens polaroid editor', (WidgetTester tester) async {
    await _openEditor(tester);
    await _tapLayout(tester, group: 'Film', layout: 'Dump');

    expect(find.bySemanticsLabel('Dump'), findsOneWidget);
    expect(find.text('Velg bilder til rammen'), findsOneWidget);
  });

  testWidgets('booth layout opens photobooth strip', (WidgetTester tester) async {
    await _openEditor(tester);
    await _tapLayout(tester, group: 'Film', layout: 'Booth');

    expect(find.bySemanticsLabel('Booth'), findsOneWidget);
    expect(find.text('Velg bilder til rammen'), findsOneWidget);
  });

  testWidgets('reaction layout opens overlay editor', (WidgetTester tester) async {
    await _openEditor(tester);
    await _tapLayout(tester, group: 'Spesial', layout: 'Reaksjon');

    expect(find.bySemanticsLabel('Reaksjon'), findsOneWidget);
    expect(find.text('Velg bilder til rammen'), findsOneWidget);
  });

  testWidgets('asymmetric mosaics are selectable', (WidgetTester tester) async {
    await _openEditor(tester);

    await _tapLayout(tester, layout: '1 + 3');
    expect(find.bySemanticsLabel('1 + 3'), findsOneWidget);

    await _tapLayout(tester, layout: '1 + 2 + 2');
    expect(find.bySemanticsLabel('1 + 2 + 2'), findsOneWidget);

    await _tapLayout(tester, layout: 'L-stor');
    expect(find.bySemanticsLabel('L-stor'), findsOneWidget);
  });

  testWidgets('format tab shows size chips', (WidgetTester tester) async {
    await _openEditor(tester);
    await tester.tap(find.text('Format'));
    await tester.pumpAndSettle();

    expect(find.text('4:5'), findsOneWidget);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('9:16'), findsOneWidget);
    expect(find.text('Innlegg'), findsOneWidget);
    expect(find.text('Kvadrat'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
  });
}
