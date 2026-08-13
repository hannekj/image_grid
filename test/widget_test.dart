import 'package:flutter_test/flutter_test.dart';

import 'package:image_grid/main.dart';

void main() {
  testWidgets('shows stacked three-image frame', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageGridApp());

    expect(find.text('Bildekarusell'), findsOneWidget);
    expect(find.text('Velg bilde'), findsNWidgets(3));
    expect(find.text('Last ned'), findsOneWidget);
  });
}
