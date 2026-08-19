import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import 'invoice_dialog.dart';

/// Bottom sheet that shows the full customer profile + their invoice
/// history + a "Record Payment" form that subtracts a payment from the
/// outstanding debt + a "Delete Customer" action.
///
/// ## Robust data fetching
/// The sheet uses `context.watch<RetailStore>()` and a `StatefulWidget`
/// lifecycle that re-queries the customer record on every rebuild —
/// so if the customer is deleted (cascading from another screen), the
/// sheet automatically closes itself rather than rendering an empty
/// / blank panel.
///
/// ## Layout
/// The sheet body is a single scrollable Column (no nested scroll
/// views that would cause layout overflow):
///   1. Header — avatar + name + phone + city + close button.
///   2. 3 Mini Stats — Total Purchases / Net Profit / Current Debt.
///   3. Payment Form — always visible inline.
///   4. Delete Customer button.
///   5. Invoice search filter + scrollable invoice list.
///
/// Each invoice row is tappable to open the printable [InvoiceDialog]
/// with PDF / PNG / Print actions.
class CustomerDetailsSheet extends StatefulWidget {
  const CustomerDetailsSheet({super.key, required this.customer});
  final Customer customer;

  @override
  State<CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<CustomerDetailsSheet> {
  bool _showAllInvoices = false;
  String _invoiceSearch = '';
  final _paymentController = TextEditingController();
  String? _paymentError;
  bool _paying = false;

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment(Customer customer) async {
    final amount = double.tryParse(_paymentController.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _paymentError = 'أدخل مبلغاً صحيحاً');
      return;
    }
    if (amount > customer.outstandingDebt) {
      setState(() =>
          _paymentError = 'المبلغ أكبر من الدين الحالي (${customer.debtLabel})');
      return;
    }
    // Capture messenger + store BEFORE any async gap.
    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<RetailStore>();

    // Show a brief loading state.
    setState(() {
      _paymentError = null;
      _paying = true;
    });

    try {
      // Yield one frame so the loading indicator paints.
      await Future<void>.delayed(Duration.zero);

      // recordPayment computes the new debt locally:
      //   - If amount == outstandingDebt → new debt = 0 (full settlement)
      //   - If amount <  outstandingDebt → new debt = old debt - amount
      // Then fires UPDATE customers SET outstanding_debt = @new WHERE id = @id
      // into Neon (see RetailStore._persistDebtUpdate).
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
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('تم حذف "${customer.name}"'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final current = store.findCustomer(widget.customer.id);

    // ── Cascading safety: if the customer was deleted from another
    // screen, close this sheet immediately so we don't render an
    // empty / blank panel.
    if (current == null) {
      // Use a post-frame callback to close during the next frame
      // — calling Navigator.pop during build throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      // Render a tiny placeholder while we wait for the close.
      return const SizedBox.shrink();
    }

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
              // Header (avatar + name + phone + close button)
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
                      // Customer info row
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
                      // Payment form (always visible — no button to open it)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: current.hasDebt
                                ? AppTheme.danger.withValues(alpha: 0.25)
                                : AppTheme.divider,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined,
                                    size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                const Text('تسديد الدين',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                                const Spacer(),
                                Text(
                                  'الدين: ${current.debtLabel}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: current.hasDebt
                                        ? AppTheme.danger
                                        : AppTheme.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                                    decoration: const InputDecoration(
                                      labelText: 'مبلغ الدفعة (أوقية)',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      prefixIcon: Icon(Icons.attach_money,
                                          size: 18),
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
                                    minimumSize: const Size(48, 44),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  onPressed: (current.hasDebt && !_paying)
                                      ? () => _submitPayment(current)
                                      : null,
                                  child: _paying
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
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
                              const SizedBox(height: 6),
                              Text(
                                _paymentError!,
                                style: const TextStyle(
                                    color: AppTheme.danger, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action row: Delete customer
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.danger,
                              side: BorderSide(
                                  color: AppTheme.danger
                                      .withValues(alpha: 0.4),
                                  width: 1),
                            ),
                            onPressed: () => _confirmDeleteCustomer(current),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('حذف الزبون'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ----- Invoice search filter -----
                      const Row(
                        children: [
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
                          prefixIcon: Icon(Icons.search, size: 18),
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
                size: 36, color: AppTheme.textSecondary),
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
