import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';

/// Tab 6 — Analytics & Daily Summary.
///
/// Provides a date picker at the top of the screen. Selecting a date
/// dynamically recomputes:
///   - Total Sales for that day
///   - Net Profit for that day
///   - Number of invoices issued that day
///   - Itemized list of all invoices generated on that date
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'اختر التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      locale: const Locale('ar', 'MR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final invoices = store.invoicesForDay(_selectedDate);
    final sales = store.salesForDay(_selectedDate);
    final profit = store.profitForDay(_selectedDate);
    final invoiceCount = invoices.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle(
            title: 'التحليلات اليومية',
            subtitle: 'اختر يوماً لعرض مبيعاته وأرباحه وفواتيره',
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: 16),
          // ----- Date picker card -----
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'التاريخ المحدد',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LtrText(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_calendar_outlined,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'تغيير',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ----- Daily metrics -----
          Row(
            children: [
              Expanded(
                child: _DailyKpiCard(
                  title: 'إجمالي المبيعات',
                  value: Money.formatWithCurrency(sales),
                  tone: StatTone.success,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DailyKpiCard(
                  title: 'صافي الربح',
                  value: Money.formatWithCurrency(profit),
                  tone: StatTone.info,
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DailyKpiCard(
                  title: 'عدد الفواتير',
                  value: '$invoiceCount',
                  tone: StatTone.neutral,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DailyKpiCard(
                  title: 'متوسط الفاتورة',
                  value: invoiceCount > 0
                      ? Money.formatWithCurrency(sales / invoiceCount)
                      : '0 أوقية',
                  tone: StatTone.warning,
                  icon: Icons.point_of_sale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ----- Invoices list for the selected day -----
          Row(
            children: [
              const Text('فواتير هذا اليوم',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LtrText(
                  '$invoiceCount فاتورة',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            const _EmptyDayCard()
          else
            ...invoices.map((inv) => _DayInvoiceTile(
                  invoice: inv,
                )),
        ],
      ),
    );
  }
}

class _DailyKpiCard extends StatelessWidget {
  const _DailyKpiCard({
    required this.title,
    required this.value,
    required this.tone,
    required this.icon,
  });
  final String title;
  final String value;
  final StatTone tone;
  final IconData icon;

  Color _bg() => switch (tone) {
        StatTone.success => AppTheme.success,
        StatTone.warning => AppTheme.warning,
        StatTone.danger => AppTheme.danger,
        StatTone.info => AppTheme.info,
        StatTone.neutral => AppTheme.textPrimary,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _bg().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _bg(), size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            LtrText(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined,
                size: 36,
                color: AppTheme.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text('لا توجد فواتير في هذا اليوم',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('اختر يوماً آخر أو سجّل مبيعات جديدة من نقطة البيع',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DayInvoiceTile extends StatelessWidget {
  const _DayInvoiceTile({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.receipt_outlined,
              color: AppTheme.primary, size: 18),
        ),
        title: Row(
          children: [
            LtrText(invoice.id,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            LtrText(
              '${invoice.date.hour.toString().padLeft(2, '0')}:${invoice.date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        subtitle: Text(
          '${invoice.customerName} • ${invoice.items.length} صنف • ${invoice.paymentType.arabicLabel}',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LtrText(
              Money.formatWithCurrency(invoice.total),
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary),
            ),
            const SizedBox(height: 2),
            invoice.isSettled
                ? const Text('خالص',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.success))
                : LtrText(
                    'متبقي: ${Money.format(invoice.balance)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.danger),
                  ),
          ],
        ),
      ),
    );
  }
}
