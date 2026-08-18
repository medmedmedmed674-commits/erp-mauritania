import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/retail_store.dart';
import '../widgets/adaptive_dashboard_scaffold.dart';
import 'retail/customers_tab.dart';
import 'retail/expenses_tab.dart';
import 'retail/inventory_tab.dart';
import 'retail/pos_tab.dart';
import 'retail/purchases_tab.dart';

/// Module 3 — Retail Store Dashboard (refactored).
///
/// Adaptive 5-tab shell:
/// 1. نقطة البيع (POS) — printable invoices
/// 2. الزبناء والديون — debt ledger + payment flow
/// 3. المخزن والمخزون — inventory + add product modal
/// 4. إدارة المشتريات — WhatsApp order launcher
/// 5. إدارة المصروفات — operational expense tracking
class RetailDashboard extends StatefulWidget {
  const RetailDashboard({super.key, this.businessName = 'مؤسسة النور للتجزئة'});

  final String businessName;

  @override
  State<RetailDashboard> createState() => _RetailDashboardState();
}

class _RetailDashboardState extends State<RetailDashboard> {
  int _index = 0;

  static const _tabs = [
    DashboardTab(
        label: 'نقطة البيع', icon: Icons.point_of_sale, subtitle: 'POS'),
    DashboardTab(
        label: 'الزبناء والديون',
        icon: Icons.people_alt_outlined,
        subtitle: 'العملاء والمستحقات'),
    DashboardTab(
        label: 'المخزن والمخزون',
        icon: Icons.inventory_2_outlined,
        subtitle: 'الكميات والتنبيهات'),
    DashboardTab(
        label: 'إدارة المشتريات',
        icon: Icons.shopping_cart_checkout_outlined,
        subtitle: 'طلب البضاعة'),
    DashboardTab(
        label: 'إدارة المصروفات',
        icon: Icons.account_balance_wallet_outlined,
        subtitle: 'المصاريف التشغيلية'),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RetailStore(),
      child: AdaptiveDashboardScaffold(
        title: widget.businessName,
        businessName: widget.businessName,
        tabs: _tabs,
        currentIndex: _index,
        onIndexChanged: (i) => setState(() => _index = i),
        child: IndexedStack(
          index: _index,
          children: const [
            PosTab(),
            CustomersTab(),
            InventoryTab(),
            PurchasesTab(),
            ExpensesTab(),
          ],
        ),
      ),
    );
  }
}
