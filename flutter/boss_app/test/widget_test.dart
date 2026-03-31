import 'package:flutter_test/flutter_test.dart';
import 'package:boss_app/app.dart';

void main() {
  testWidgets('BossApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BossApp());
    expect(find.byType(BossApp), findsOneWidget);
  });
}
