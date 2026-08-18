// This is a basic Flutter widget test that verifies the app boots
// without throwing. Replace with real test cases as the app grows.

import 'package:flutter_test/flutter_test.dart';

import 'package:erp_mauritania/main.dart';

void main() {
  testWidgets('App boots and shows welcome screen', (tester) async {
    await tester.pumpWidget(const ErpMauritaniaApp());
    expect(find.text('أهلاً وسهلاً بك'), findsOneWidget);
    expect(find.text('في نظام الإدارة المتكامل لمؤسستك'), findsOneWidget);
  });
}
