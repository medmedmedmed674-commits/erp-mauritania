import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import 'invoice_dialog.dart';

/// Bottom sheet that shows the full customer profile + their invoice
/// history + a "Record Payment" flow that subtracts a payment from the
/// outstanding debt.
///
/// ## White-screen fix
/// Previously this sheet used `showModalBottomSheet` with the default
/// `useRootNavigator: true`, which mounted the sheet on the root
/// navigator — **outside** the `ChangeNotifierProvider<RetailStore>`
/// that lives inside `RetailDashboard.build()`. The subsequent
/// `context.watch<RetailStore>()` call would silently throw and the
/// sheet would render as a blank white panel.
///
/// We now pass `useRootNavigator: false` (see [showCustomerDetails])
/// so the sheet mounts inside the provider tree.
///
/// ## Receipt preview
/// Tapping any invoice in the history list opens the same
/// [InvoiceDialog] used by the POS checkout, with working PDF/PNG/Print
/// actions.
class CustomerDetailsSheet extends StatefulWidget {
  const CustomerDetailsSheet({super.key, required this.customer});
  final Customer customer;

  @override
  State<CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<CustomerDetailsSheet> {
  bool _showAllInvoices = false;
  String _invoiceSearch = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final current = store.findCustomer(widget.customer.id) ?? widget.customer;
    final allInvoices = store.invoicesFor(current.id);

    // Filter invoices by search query (id or amount contains query).
    final invoices = _invoiceSearch.trim().isEmpty
        ? allInvoices
        : allInvoices
            .where((inv) =>
                inv.id.toLowerCase().contains(_invoiceSearch.toLowerCase()) ||
                Money.format(inv.total).contains(_invoiceSearch))
            .toList();

    final shown = _showAllInvoices ? invoices : invoices.take(3).toList();

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
                        current.name.isNotEmpty
                            ? current.name.substring(0, 1)
                            : '?',
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
                            label: const Text('تسديد الدين'),
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
                      // ----- Invoice search filter -----
                      Row(
                        children: const [
                          Text('الفواتير',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (v) =>
                            setState(() => _invoiceSearch = v),
                        decoration: const InputDecoration(
                          hintText: 'ابحث برقم الفاتورة أو المبلغ…',
                          prefixIcon:
                              Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${invoices.length} فاتورة',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (allInvoices.length > 3)
                            TextButton.icon(
                              onPressed: () => setState(() =>
                                  _showAllInvoices = !_showAllInvoices),
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
                      const SizedBox(height: 8),
                      if (invoices.isEmpty)
                        const _EmptyInvoicesCard()
                      else
                        ...shown.map((inv) => _InvoiceTile(
                              invoice: inv,
                              onTap: () => _showReceipt(inv),
                            )),
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

  /// Re-opens the printable [InvoiceDialog] for a past invoice.
  void _showReceipt(Invoice invoice) {
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => InvoiceDialog(
        invoice: invoice,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
      ),
    );
  }

  void _showPaymentDialog(Customer c) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      useRootNavigator: false,
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
                  autofocus: true,
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
                  // Capture messenger BEFORE pop.
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  final store = context.read<RetailStore>();
                  store.recordPayment(c.id, amount);
                  Navigator.of(dialogContext).pop();
                  messenger.showSnackBar(
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

class _EmptyInvoicesCard extends StatelessWidget {
  const _EmptyInvoicesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Icon(Icons.receipt_long_outlined,
                size: 36,
                color: AppTheme.textSecondary),
            SizedBox(height: 8),
            Text('لا توجد فواتير مطابقة',
                style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.onTap});
  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
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
              const SizedBox(width: 4),
              const Icon(Icons.chevron_left,
                  size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience helper used by the customers tab.
///
/// **IMPORTANT**: `useRootNavigator: false` is critical — without it,
/// the sheet mounts on the root navigator and `context.watch<RetailStore>()`
/// inside the sheet throws a `ProviderNotFoundException` (which
/// manifests as a blank white sheet).
Future<void> showCustomerDetails(
    BuildContext context, Customer customer) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxHeight: 600),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CustomerDetailsSheet(customer: customer),
  );
}
