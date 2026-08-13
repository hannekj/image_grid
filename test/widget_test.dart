import 'package:flutter_test/flutter_test.dart';

import 'package:image_grid/main.dart';

void main() {
  testWidgets('shows Hello, World!', (WidgetTester tester) async {
    await tester.pumpWidget(const ImageGridApp());
    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
