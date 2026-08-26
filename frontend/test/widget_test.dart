import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App boots to role selection screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HcmsApp());
    await tester.pumpAndSettle();
    expect(find.byType(HcmsApp), findsOneWidget);
  });
}
