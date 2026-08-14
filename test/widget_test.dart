import 'package:flutter_test/flutter_test.dart';

import 'package:image_grid/main.dart';

void main() {
  testWidgets('home Grid button opens layout alternatives', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ImageGridApp());

    expect(find.text('Grid'), findsOneWidget);

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();

    expect(find.text('2 rader'), findsOneWidget);
    expect(find.text('3 rader'), findsOneWidget);
    expect(find.text('2 kolonner'), findsOneWidget);
    expect(find.text('Stort + to'), findsOneWidget);
    expect(find.text('2 × 2'), findsOneWidget);
  });

  testWidgets('editor shows frame style controls', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageGridApp());

    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 rader'));
    await tester.pumpAndSettle();

    expect(find.text('Ingen ramme'), findsOneWidget);
    expect(find.text('Strek'), findsOneWidget);
    expect(find.text('Tynn'), findsNothing);

    await tester.tap(find.text('Strek'));
    await tester.pump();

    expect(find.text('Tynn'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Tykk'), findsOneWidget);
  });
}
