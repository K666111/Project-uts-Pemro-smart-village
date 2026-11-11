
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_village_uts/main.dart';

void main() {
  testWidgets('Smart Village app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartVillageApp());

    await tester.pump();

    expect(find.byType(SmartVillageApp), findsOneWidget);
  });
}
