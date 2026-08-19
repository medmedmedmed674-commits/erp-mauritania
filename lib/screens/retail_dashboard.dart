import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
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
///
/// A small DB status banner appears at the top of the body when the
/// Neon database connection is unavailable (e.g. on Flutter Web) or
/// when a recent DB operation failed. This makes the fallback mode
/// visible to the user instead of failing silently.
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
        child: Column(
          children: [
            // DB status banner — shown only when there's an error
            // or when running on the web fallback.
            const _DbStatusBanner(),
            // Main tab content
            Expanded(
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
          ],
        ),
      ),
    );
  }
}

/// Compact status banner that shows DB connection state.
///
/// - Hidden when DB is connected and there's no recent error.
/// - Shows a yellow "fallback" banner when running on Web.
/// - Shows a red "error" banner when a DB operation failed.
class _DbStatusBanner extends StatelessWidget {
  const _DbStatusBanner();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final error = store.lastError;
    final isDb = store.isDbAvailable;

    // No banner when everything is fine.
    if (error == null && isDb) return const SizedBox.shrink();

    final message = error ?? 'وضع المخزن المحلي — قاعدة البيانات غير متاحة على الويب.';
    final color = error != null
        ? AppTheme.danger
        : AppTheme.warning;

    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              error != null
                  ? Icons.error_outline
                  : Icons.cloud_off_outlined,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (error != null)
              IconButton(
                icon: Icon(Icons.close, size: 14, color: color),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: store.clearLastError,
                tooltip: 'إغلاق',
              ),
          ],
        ),
      ),
    );
  }
}
