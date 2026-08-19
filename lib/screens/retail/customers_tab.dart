import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';
import 'add_customer_dialog.dart';
import 'customer_details_sheet.dart';

/// Tab 2 — Customers & Debt Ledger.
/// Lists registered customers with their debt balances and a quick
/// "record payment" action. Tapping a customer opens the full profile.
/// Includes a search filter (name or phone), an "Add New Customer"
/// button, and a long-press to delete.
class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  String _search = '';

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await confirmDeleteCustomer(context, customer);
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<RetailStore>();
    store.deleteCustomer(customer.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text('تم حذف "${customer.name}"'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final allCustomers = store.customers;
    final totalDebt = store.totalDebt;
    final totalProfit = store.totalProfit;

    // Filter customers by name OR phone.
    final customers = _search.trim().isEmpty
        ? allCustomers
        : allCustomers
            .where((c) =>
                c.name.contains(_search.trim()) ||
                c.phone.contains(_search.trim()))
            .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(
                title: 'إدارة الزبناء والديون',
                subtitle:
                    'سجل العملاء، الأرصدة المستحقة، وهامش الربح لكل زبون — اضغط مطولاً للحذف',
                icon: Icons.people_alt_outlined,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  StatPill(
                    label: 'إجمالي العملاء',
                    value: '${allCustomers.length} زبون',
                    tone: StatTone.info,
                    icon: Icons.people_outline,
                  ),
                  StatPill(
                    label: 'إجمالي الديون',
                    value: Money.formatWithCurrency(totalDebt),
                    tone: StatTone.danger,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  StatPill(
                    label: 'صافي الأرباح',
                    value: Money.formatWithCurrency(totalProfit),
                    tone: StatTone.success,
                    icon: Icons.trending_up,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BrandedSearchField(
                hint: 'ابحث بالاسم أو رقم الهاتف…',
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: customers.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_off_outlined,
                        title: 'لا يوجد زبناء مطابقون',
                        subtitle: 'جرّب تعديل البحث أو أضف زبوناً جديداً',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _CustomerCard(
                          customer: customers[i],
                          onLongPress: () => _confirmDelete(customers[i]),
                        ),
                      ),
              ),
            ],
          ),
          // Floating "Add New Customer" button
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => showAddCustomerDialog(context),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('إضافة زبون جديد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onLongPress});
  final Customer customer;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showCustomerDetails(context, customer),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        LtrText(customer.phone,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                        Text('• ${customer.city}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (customer.hasDebt)
                    LtrText(
                      customer.debtLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.danger,
                      ),
                    )
                  else
                    const Text('خالص',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      backgroundColor: customer.hasDebt
                          ? AppTheme.success
                          : AppTheme.surfaceAlt,
                      foregroundColor: customer.hasDebt
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    onPressed: () => showCustomerDetails(context, customer),
                    icon: const Icon(Icons.payments_outlined, size: 14),
                    label: const Text('تسديد'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
