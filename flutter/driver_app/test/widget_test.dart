import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DriverApp());
    expect(find.byType(DriverApp), findsOneWidget);
  });
}
