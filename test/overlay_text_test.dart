import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_grid/main.dart';
import 'package:image_grid/overlay_text.dart';
import 'package:image_grid/overlay_text_controls.dart';
import 'package:image_grid/overlay_text_layer.dart';

Future<void> _openCollageEditor(WidgetTester tester) async {
  await tester.pumpWidget(const ImageGridApp());
  await tester.tap(find.text('Lag innlegg'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Collage').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Tekst places overlay and opens style dock', (tester) async {
    await _openCollageEditor(tester);

    await tester.tap(find.text('Tekst'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Farge'), findsOneWidget);
    // Floating Rediger is visible while the new text is selected/editing.
    expect(find.byTooltip('Rediger'), findsWidgets);
    // Rotate-in-Stil was removed; canvas rotate handle remains.
    expect(find.byTooltip('Roter'), findsNothing);
  });

  testWidgets('empty inline edit falls back to Tekst', (tester) async {
    await _openCollageEditor(tester);

    await tester.tap(find.text('Tekst'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Still shows the default label, not a blank overlay.
    expect(find.text('Tekst'), findsWidgets);
  });

  testWidgets('Perler controls hide text effects', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverlayTextControls(
            overlays: [
              OverlayText(value: 'XO', fontId: 'perler'),
            ],
            selectedIndex: 0,
            onSelect: (_) {},
            onAddText: () {},
            onChanged: (_) {},
            onRemove: () {},
            onEdit: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stil'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Skygge'), findsNothing);
    expect(find.byTooltip('Kant'), findsNothing);
    expect(find.byTooltip('Venstre'), findsOneWidget);
  });

  testWidgets('shadow effect applies to plain text style', (tester) async {
    await _openCollageEditor(tester);

    await tester.tap(find.text('Tekst'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fjell');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Skygge'));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('Fjell'));
    expect(text.style?.shadows, isNotNull);
    expect(text.style!.shadows, isNotEmpty);
  });

  testWidgets('undo restores text before last edit', (tester) async {
    await _openCollageEditor(tester);

    await tester.tap(find.text('Tekst'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Først');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Først'), findsOneWidget);

    // Re-enter edit, change value, then undo back to Først.
    await tester.tap(find.text('Først'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Først'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Etter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Etter'), findsOneWidget);

    await tester.tap(find.byTooltip('Angre'));
    await tester.pumpAndSettle();
    expect(find.text('Først'), findsOneWidget);
  });

  test('overlayDefaultValue for text is Tekst', () {
    expect(overlayDefaultValue(OverlayKind.text), 'Tekst');
  });

  test('bead letters detect perler font', () {
    expect(
      OverlayText(value: 'XO', fontId: 'perler').usesBeadLetters,
      isTrue,
    );
    expect(
      OverlayText(value: 'XO', fontId: 'sans').usesBeadLetters,
      isFalse,
    );
  });

  testWidgets('on-canvas delete pill removes overlay', (tester) async {
    var removed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 700,
            child: OverlayTextsLayer(
              overlays: [
                OverlayText.create(value: 'Hei', index: 0),
              ],
              selectedIndex: 0,
              exporting: false,
              onSelect: (_) {},
              onEdit: (_) {},
              onDuplicate: (_) {},
              onRemove: (_) => removed = true,
              onAlignmentChanged: (_, __) {},
              onFontSizeChanged: (_, __) {},
              onRotationChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Slett'), findsOneWidget);
    await tester.tap(find.byTooltip('Slett'));
    await tester.pump();
    expect(removed, isTrue);
  });
}
