// Smoke tests that verify the refactored retail dashboard boots
// without throwing. Replace with deeper scenario tests as the
// feature set grows.

import 'package:erp_mauritania/main.dart';
import 'package:erp_mauritania/screens/retail/analytics_tab.dart';
import 'package:erp_mauritania/screens/retail/pos_tab.dart';
import 'package:erp_mauritania/screens/retail/customers_tab.dart';
import 'package:erp_mauritania/screens/retail/inventory_tab.dart';
import 'package:erp_mauritania/screens/retail/purchases_tab.dart';
import 'package:erp_mauritania/screens/retail/expenses_tab.dart';
import 'package:erp_mauritania/utils/retail_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Lightweight test harness that wraps a single retail tab inside
/// the [RetailStore] provider + RTL Directionality, so each test
/// can mount a single tab without booting the full dashboard.
class _RetailTabHarness extends StatelessWidget {
  const _RetailTabHarness({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ChangeNotifierProvider<RetailStore>(
        create: (_) => RetailStore(),
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }
}

void main() {
  // The retail tabs use Responsive + Expanded layouts that need a
  // defined viewport. Default test surface is 800x600, which is fine
  // for tablet/desktop breakpoints but we set it explicitly inside
  // each test via tester.view.
  const surfaceSize = Size(1280, 900);

  testWidgets('App boots and shows welcome screen', (tester) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ErpMauritaniaApp());
    expect(find.text('أهلاً وسهلاً بك'), findsOneWidget);
    expect(find.text('في نظام الإدارة المتكامل لمؤسستك'), findsOneWidget);
  });

  testWidgets('POS tab renders the product grid', (tester) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const _RetailTabHarness(child: PosTab()));
    await tester.pumpAndSettle();
    expect(find.text('المنتجات'), findsOneWidget);
  });

  testWidgets('Customers tab renders the ledger header', (tester) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const _RetailTabHarness(child: CustomersTab()));
    await tester.pumpAndSettle();
    expect(find.text('إدارة الزبناء والديون'), findsOneWidget);
  });

  testWidgets('Inventory tab renders the inventory header', (tester) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const _RetailTabHarness(child: InventoryTab()));
    await tester.pumpAndSettle();
    expect(find.text('المخزن والمخزون'), findsOneWidget);
  });

  testWidgets('Purchases tab renders the wholesale catalog', (tester) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const _RetailTabHarness(child: PurchasesTab()));
    await tester.pumpAndSettle();
    expect(find.text('إدارة المشتريات'), findsOneWidget);
  });

  testWidgets('Expenses tab renders the expense header', (tester) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const _RetailTabHarness(child: ExpensesTab()));
    await tester.pumpAndSettle();
    expect(find.text('إدارة المصروفات'), findsOneWidget);
  });

  testWidgets('Analytics tab renders the daily summary header', (tester) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const _RetailTabHarness(child: AnalyticsTab()));
    await tester.pumpAndSettle();
    expect(find.text('التحليلات اليومية'), findsOneWidget);
  });
}
