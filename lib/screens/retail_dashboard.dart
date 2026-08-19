import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/locale_provider.dart';
import '../utils/retail_store.dart';
import '../widgets/adaptive_dashboard_scaffold.dart';
import 'retail/analytics_tab.dart';
import 'retail/customers_tab.dart';
import 'retail/expenses_tab.dart';
import 'retail/inventory_tab.dart';
import 'retail/pos_tab.dart';
import 'retail/purchases_tab.dart';

/// Module 3 — Retail Store Dashboard (refactored).
///
/// Adaptive 6-tab shell:
/// 1. نقطة البيع (POS) — printable invoices
/// 2. الزبناء والديون — debt ledger + payment flow
/// 3. المخزن والمخزون — inventory + add product modal
/// 4. إدارة المشتريات — WhatsApp order launcher
/// 5. إدارة المصروفات — operational expense tracking
/// 6. التحليلات اليومية — date-filtered sales + profit + invoices
///
/// Tab labels are localized — switching Arabic ⇄ French via the
/// [LanguageSwitcher] in the app bar updates all 6 tab labels live.
class RetailDashboard extends StatefulWidget {
  const RetailDashboard({super.key, this.businessName = 'مؤسسة النور للتجزئة'});

  final String businessName;

  @override
  State<RetailDashboard> createState() => _RetailDashboardState();
}

class _RetailDashboardState extends State<RetailDashboard> {
  int _index = 0;

  /// Returns the localized tab list. Rebuilt on every [LocaleProvider]
  /// notification so labels + subtitles switch language live.
  List<DashboardTab> _buildTabs(LocaleProvider locale) => [
        DashboardTab(
          label: locale.t('retail.tab.pos'),
          icon: Icons.point_of_sale,
          subtitle: 'POS',
        ),
        DashboardTab(
          label: locale.t('retail.tab.customers'),
          icon: Icons.people_alt_outlined,
          subtitle: locale.t('customers.subtitle'),
        ),
        DashboardTab(
          label: locale.t('retail.tab.inventory'),
          icon: Icons.inventory_2_outlined,
          subtitle: locale.t('inventory.subtitle'),
        ),
        DashboardTab(
          label: locale.t('retail.tab.purchases'),
          icon: Icons.shopping_cart_checkout_outlined,
          subtitle: locale.t('purchases.subtitle'),
        ),
        DashboardTab(
          label: locale.t('retail.tab.expenses'),
          icon: Icons.account_balance_wallet_outlined,
          subtitle: locale.t('expenses.subtitle'),
        ),
        DashboardTab(
          label: locale.t('retail.tab.analytics'),
          icon: Icons.analytics_outlined,
          subtitle: locale.t('analytics.subtitle'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final tabs = _buildTabs(locale);
    return ChangeNotifierProvider(
      create: (_) => RetailStore(),
      child: AdaptiveDashboardScaffold(
        title: widget.businessName,
        businessName: widget.businessName,
        tabs: tabs,
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
            AnalyticsTab(),
          ],
        ),
      ),
    );
  }
}
