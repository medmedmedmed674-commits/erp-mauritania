import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import 'invoice_dialog.dart';

/// Full-screen customer statement view showing:
///   a) Header: Customer profile (Name, Phone, City, Address).
///   b) Debt Section: Total remaining debt prominently at the top.
///   c) Ledger Section: Scrollable list of all invoices (clickable to
///      show invoice details + printable receipt).
///   d) Payment Form: "تسديد الدين" button with input for amount.
///      Executes UPDATE customers SET debt = debt - @amount WHERE id = @id
///      and refreshes the view immediately.
///   e) Delete Customer action.
///
/// ## Why a full Dialog instead of a ModalBottomSheet
/// The previous implementation used `showModalBottomSheet` with a
/// `maxHeight: 600` constraint and `backgroundColor: Colors.transparent`.
/// On certain web/screen sizes the inner `Flexible(SingleChildScrollView)`
/// would collapse to 0 height because the parent `Column` with
/// `mainAxisSize: MainAxisSize.min` had no explicit size — rendering
/// a blank/grey screen. A full-screen `Dialog` with an explicit
/// `Scaffold` avoids this class of layout bugs entirely.
class CustomerDetailsDialog extends StatefulWidget {
  const CustomerDetailsDialog({super.key, required this.customer});
  final Customer customer;

  @override
  State<CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog> {
  bool _showAllInvoices = false;
  final _paymentController = TextEditingController();
  String? _paymentError;
  bool _paying = false;

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  // ─── Pay Debt ────────────────────────────────────────────────
  Future<void> _submitPayment(Customer customer) async {
    final amount = double.tryParse(_paymentController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _paymentError = 'أدخل مبلغاً صحيحاً');
      return;
    }
    if (amount > customer.outstandingDebt) {
      setState(() => _paymentError =
          'المبلغ أكبر من الدين الحالي (${customer.debtLabel})');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<RetailStore>();

    setState(() {
      _paymentError = null;
      _paying = true;
    });

    try {
      await Future<void>.delayed(Duration.zero);

      // recordPayment computes:
      //   - If amount == debt → new debt = 0 (full settlement)
      //   - If amount <  debt → new debt = old debt - amount
      // Then fires UPDATE customers SET outstanding_debt = @new WHERE id = @id
      store.recordPayment(customer.id, amount);

      _paymentController.clear();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'تم تسجيل دفعة بقيمة ${Money.formatWithCurrency(amount)}'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e, stack) {
      debugPrint('Payment failed: $e\n$stack');
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل تسجيل الدفعة: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  // ─── Delete Customer ─────────────────────────────────────────
  Future<void> _confirmDeleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف الزبون'),
          content: Text(
              'هل أنت متأكد من حذف "${customer.name}"؟ سيتم حذفه نهائياً من السجل.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final store = context.read<RetailStore>();
    store.deleteCustomer(customer.id);
    navigator.pop(); // Close the details dialog
    messenger.showSnackBar(
      SnackBar(
        content: Text('تم حذف "${customer.name}"'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  // ─── Show Receipt ────────────────────────────────────────────
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

  // ─── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final current = store.findCustomer(widget.customer.id);

    // Cascading safety: if customer was deleted, close this dialog.
    if (current == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    final allInvoices = store.invoicesFor(current.id);
    final shown =
        _showAllInvoices ? allInvoices : allInvoices.take(5).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppTheme.background,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        current.name.isNotEmpty
                            ? current.name.substring(0, 1)
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
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
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${current.phone} • ${current.city}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Debt Section ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: current.hasDebt
                            ? [AppTheme.danger, const Color(0xFFB33A3A)]
                            : [AppTheme.success, const Color(0xFF178050)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          current.hasDebt ? 'الدين المستحق' : 'لا يوجد دين',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LtrText(
                          current.debtLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats Row ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'إجمالي الشراء',
                          value: current.purchasesLabel,
                          icon: Icons.shopping_cart_outlined,
                          color: AppTheme.info,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'صافي الربح',
                          value: current.profitLabel,
                          icon: Icons.trending_up,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Payment Form ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: current.hasDebt
                            ? AppTheme.danger.withValues(alpha: 0.3)
                            : AppTheme.divider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 18, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text('تسديد الدين',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _paymentController,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                enabled: current.hasDebt && !_paying,
                                decoration: const InputDecoration(
                                  labelText: 'مبلغ الدفعة (أوقية)',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  prefixIcon:
                                      Icon(Icons.attach_money, size: 18),
                                ),
                                onChanged: (_) =>
                                    setState(() => _paymentError = null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(56, 48),
                              ),
                              onPressed: (current.hasDebt && !_paying)
                                  ? () => _submitPayment(current)
                                  : null,
                              child: _paying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text('تأكيد',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        if (_paymentError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _paymentError!,
                            style: const TextStyle(
                                color: AppTheme.danger, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Invoice Ledger ───────────────────────────
                  Row(
                    children: [
                      const Text('سجل الفواتير',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${allInvoices.length} فاتورة',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('اضغط على أي فاتورة لعرضها وطباعتها',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),

                  if (allInvoices.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: const [
                            Icon(Icons.receipt_long_outlined,
                                size: 36, color: AppTheme.textSecondary),
                            SizedBox(height: 8),
                            Text('لا توجد فواتير سابقة لهذا الزبون',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...shown.map((inv) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InvoiceTile(
                            invoice: inv,
                            onTap: () => _showReceipt(inv),
                          ),
                        )),

                  if (allInvoices.length > 5)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(
                            () => _showAllInvoices = !_showAllInvoices),
                        icon: Icon(
                          _showAllInvoices
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                        ),
                        label: Text(_showAllInvoices
                            ? 'عرض أقل'
                            : 'عرض كافة الفواتير (${allInvoices.length})'),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Delete Customer ──────────────────────────
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: BorderSide(
                          color: AppTheme.danger.withValues(alpha: 0.4),
                          width: 1),
                    ),
                    onPressed: () => _confirmDeleteCustomer(current),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف الزبون'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            LtrText(
              value,
              style: const TextStyle(
                fontSize: 14,
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

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.onTap});
  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_outlined,
                    color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LtrText(invoice.id,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        LtrText(
                          '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${invoice.items.length} صنف • ${invoice.paymentType.arabicLabel}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                  size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience helper used by the customers tab.
///
/// Uses a full-screen `Dialog` instead of `showModalBottomSheet` to
/// avoid the blank-screen layout bug that occurred when the bottom
/// sheet's `Flexible(SingleChildScrollView)` collapsed to 0 height
/// on certain screen sizes.
Future<void> showCustomerDetails(
    BuildContext context, Customer customer) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (_) => CustomerDetailsDialog(customer: customer),
  );
}
