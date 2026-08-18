import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';

/// Modal dialog that displays a completed POS sale as a digital
/// receipt with two action buttons: Save as PDF and Print.
///
/// The dialog renders an HTML-like preview on screen and uses the
/// `printing` + `pdf` packages to generate a real PDF document that
/// can be saved to disk or sent straight to the system print dialog.
/// Works on Web, Android, iOS, macOS, Windows, Linux.
class InvoiceDialog extends StatelessWidget {
  const InvoiceDialog({
    super.key,
    required this.invoice,
    required this.customerName,
    required this.customerPhone,
  });

  final Invoice invoice;
  final String customerName;
  final String? customerPhone;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppTheme.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(invoice: invoice),
                  const Divider(height: 24),
                  _MetaRow(
                      label: 'رقم الفاتورة',
                      value: invoice.id,
                      forceLtr: true),
                  _MetaRow(
                      label: 'التاريخ',
                      value:
                          '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}'),
                  _MetaRow(
                      label: 'الوقت',
                      value:
                          '${invoice.date.hour.toString().padLeft(2, '0')}:${invoice.date.minute.toString().padLeft(2, '0')}'),
                  _MetaRow(label: 'الزبون', value: customerName),
                  if (customerPhone != null)
                    _MetaRow(
                        label: 'الهاتف',
                        value: customerPhone!,
                        forceLtr: true),
                  _MetaRow(
                      label: 'طريقة الدفع',
                      value: invoice.paymentType.arabicLabel),
                  const Divider(height: 24),
                  const _ItemsHeader(),
                  ...invoice.items.map((l) => _ItemRow(line: l)),
                  const Divider(height: 16),
                  _TotalRow(
                      label: 'المجموع الفرعي',
                      value: invoice.subtotal),
                  _TotalRow(
                      label: 'المدفوع',
                      value: invoice.paid,
                      tone: StatTone.success),
                  if (invoice.balance > 0)
                    _TotalRow(
                        label: 'المتبقي (دين)',
                        value: invoice.balance,
                        tone: StatTone.danger),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('الإجمالي النهائي',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        LtrText(
                          Money.formatWithCurrency(invoice.total),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _savePdf(context),
                          icon: const Icon(Icons.save_alt_outlined, size: 18),
                          label: const Text('حفظ الفاتورة'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _print(context),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('طباعة'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----- PDF generation -----
  Future<pw.Document> _buildPdf() async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Center(
            child: pw.Text(
              invoice.storeName,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'فاتورة بيع',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('رقم الفاتورة:'),
              pw.Text(invoice.id),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('التاريخ:'),
              pw.Text(
                  '${invoice.date.day}/${invoice.date.month}/${invoice.date.year} ${invoice.date.hour}:${invoice.date.minute.toString().padLeft(2, '0')}'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الزبون:'),
              pw.Text(customerName),
            ],
          ),
          if (customerPhone != null)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('الهاتف:'),
                pw.Text(customerPhone!),
              ],
            ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('طريقة الدفع:'),
              pw.Text(invoice.paymentType.arabicLabel),
            ],
          ),
          pw.Divider(),
          pw.Table.fromTextArray(
            headers: ['الصنف', 'الكمية', 'السعر', 'الإجمالي'],
            data: invoice.items
                .map((l) => [
                      l.product.name,
                      l.quantity.toString(),
                      Money.format(l.product.unitPrice),
                      Money.format(l.lineTotal),
                    ])
                .toList(),
            cellAlignment: pw.Alignment.centerRight,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey100,
            ),
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المجموع الفرعي:'),
              pw.Text(Money.formatWithCurrency(invoice.subtotal)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('المدفوع:'),
              pw.Text(Money.formatWithCurrency(invoice.paid)),
            ],
          ),
          if (invoice.balance > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('المتبقي (دين):'),
                pw.Text(Money.formatWithCurrency(invoice.balance)),
              ],
            ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'الإجمالي النهائي:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  Money.formatWithCurrency(invoice.total),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Center(
            child: pw.Text(
              'شكراً لتعاملكم معنا',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  Future<void> _savePdf(BuildContext context) async {
    try {
      final doc = await _buildPdf();
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'invoice_${invoice.id}.pdf',
      );
    } catch (e) {
      _showError(context, e);
    }
  }

  Future<void> _print(BuildContext context) async {
    try {
      final doc = await _buildPdf();
      await Printing.layoutPdf(
        onLayout: (format) => doc.save(),
        name: 'invoice_${invoice.id}',
      );
    } catch (e) {
      _showError(context, e);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تعذّرت عملية الطباعة: $error'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets used by the dialog
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_outlined,
              color: AppTheme.success, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تمت عملية البيع بنجاح',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                invoice.storeName,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.forceLtr = false,
  });
  final String label;
  final String value;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
          const Spacer(),
          if (forceLtr)
            LtrText(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700))
          else
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(flex: 4, child: Text('الصنف')),
        Expanded(flex: 2, child: Text('الكمية')),
        Expanded(flex: 3, child: Text('السعر')),
        Expanded(flex: 3, child: Text('الإجمالي')),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              line.product.name,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: LtrText('${line.quantity}',
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: LtrText(
              Money.format(line.product.unitPrice),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: LtrText(
              Money.format(line.lineTotal),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.tone,
  });
  final String label;
  final double value;
  final StatTone? tone;

  Color get _color => switch (tone) {
        StatTone.success => AppTheme.success,
        StatTone.danger => AppTheme.danger,
        StatTone.warning => AppTheme.warning,
        _ => AppTheme.textPrimary,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          LtrText(
            Money.formatWithCurrency(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience helper used by the POS tab.
Future<void> showInvoiceDialog(
  BuildContext context, {
  required String customerName,
  String? customerPhone,
  required CustomerType customerType,
  required PaymentType paymentType,
  required List<CartLine> items,
  required double paid,
}) async {
  final store = context.read<RetailStore>();
  final total = items.fold(0.0, (s, l) => s + l.lineTotal);
  final now = DateTime.now();
  final invoice = Invoice(
    id:
        'INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}',
    customerId:
        customerType == CustomerType.registered ? 'C-NEW' : 'WALK-IN',
    customerName: customerName,
    customerPhone: customerPhone,
    date: now,
    total: total,
    paid: paid,
    items: List.of(items),
    paymentType: paymentType,
    storeName: 'مؤسسة النور للتجزئة',
  );
  store.addInvoice(invoice);
  await showDialog<void>(
    context: context,
    builder: (_) => InvoiceDialog(
      invoice: invoice,
      customerName: customerName,
      customerPhone: customerPhone,
    ),
  );
}
