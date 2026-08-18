import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';

/// Bottom sheet that shows the full customer profile + their invoice
/// history + a "Record Payment" flow that subtracts a payment from the
/// outstanding debt.
///
/// ## Implementation note
/// Previously this used a `DraggableScrollableSheet` nested inside a
/// `showModalBottomSheet` with a transparent background. The
/// combination produced a white screen because the inner sheet was
/// never given finite size constraints.
///
/// We now use a plain `showModalBottomSheet` with `isScrollControlled:
/// true` and a single `Container` body sized via `SingleChildScrollView`
/// — this gives us a proper full-height sheet that scrolls naturally
/// on all device sizes.
class CustomerDetailsSheet extends StatefulWidget {
  const CustomerDetailsSheet({super.key, required this.customer});
  final Customer customer;

  @override
  State<CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<CustomerDetailsSheet> {
  bool _showAllInvoices = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final current = store.findCustomer(widget.customer.id) ?? widget.customer;
    final invoices = store.invoicesFor(current.id);
    final shown =
        _showAllInvoices ? invoices : invoices.take(3).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Header (avatar + name + close button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        current.name.substring(0, 1),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            children: [
                              LtrText(current.phone,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                              Text('• ${current.city}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'إجمالي الشراء',
                              value: current.purchasesLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                              label: 'صافي الربح',
                              value: current.profitLabel,
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                              label: 'الدين الحالي',
                              value: current.debtLabel,
                              color: current.hasDebt
                                  ? AppTheme.danger
                                  : AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (current.hasDebt) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showPaymentDialog(current),
                            icon: const Icon(Icons.payments_outlined, size: 18),
                            label: const Text('تسجيل دفعة / تسديد الدين'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: AppTheme.success, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'لا توجد ديون مستحقة على هذا الزبون',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('الفواتير',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: invoices.isEmpty
                                ? null
                                : () => setState(
                                    () => _showAllInvoices = !_showAllInvoices),
                            icon: Icon(
                              _showAllInvoices
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                            ),
                            label: Text(_showAllInvoices
                                ? 'عرض أقل'
                                : 'عرض كافة الفواتير'),
                          ),
                        ],
                      ),
                      if (invoices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'لا توجد فواتير سابقة',
                            subtitle: 'لم يتم تسجيل أي عملية بيع لهذا الزبون بعد',
                          ),
                        )
                      else
                        ...shown.map((inv) => _InvoiceTile(invoice: inv)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(Customer c) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل دفعة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('الزبون: ${c.name}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('الدين الحالي: ${c.debtLabel}',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'مبلغ الدفعة (أوقية)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final amount =
                      double.tryParse(controller.text.trim()) ?? 0;
                  if (amount <= 0) return;
                  context.read<RetailStore>().recordPayment(c.id, amount);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'تم تسجيل دفعة بقيمة ${Money.formatWithCurrency(amount)}'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                child: const Text('تأكيد الدفعة'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.color,
  });
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          LtrText(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});
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
              '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        subtitle: Text(
          '${invoice.items.length} صنف • ${invoice.paymentType.arabicLabel}',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
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

/// Convenience helper used by the customers tab.
Future<void> showCustomerDetails(
    BuildContext context, Customer customer) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Use a fixed max height so the sheet never collapses to 0 and
    // produces a white screen.
    constraints: const BoxConstraints(maxHeight: 600),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CustomerDetailsSheet(customer: customer),
  );
}
