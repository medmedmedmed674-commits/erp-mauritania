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
/// receipt with three action buttons:
///   1. "حفظ كـ PNG" — render the receipt to a PNG image and share it.
///   2. "حفظ PDF"   — generate a clean Arabic-formatted PDF and share.
///   3. "طباعة"     — send the PDF directly to the system print dialog.
///
/// ## Arabic PDF rendering
/// The default `pdf` package fonts do not include Arabic glyphs, which
/// is what caused the corrupted-text bug in the previous release.
/// We load the bundled Cairo TTF at runtime via
/// `PdfGoogleFonts.cairo()` (which pulls from the printing package
/// cache) or fall back to the asset bundle's Cairo.ttf as a fully
/// offline FontProvider.
class InvoiceDialog extends StatefulWidget {
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
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  /// Lazy-loaded Arabic font for the PDF document.
  Future<pw.Font>? _arabicFont;
  Future<pw.Font>? _arabicBoldFont;

  Future<pw.Font> _loadArabicFont() async {
    _arabicFont ??= _loadFont('assets/fonts/Cairo.ttf');
    return _arabicFont!;
  }

  Future<pw.Font> _loadArabicBoldFont() async {
    _arabicBoldFont ??= _loadFont('assets/fonts/Cairo-Bold.ttf');
    return _arabicBoldFont!;
  }

  Future<pw.Font> _loadFont(String asset) async {
    final bytes = await DefaultAssetBundle.of(context).load(asset);
    return pw.Font.ttf(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
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
                  _MetaRow(label: 'الزبون', value: widget.customerName),
                  if (widget.customerPhone != null)
                    _MetaRow(
                        label: 'الهاتف',
                        value: widget.customerPhone!,
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
                  // Three export actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportPng,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('حفظ صورة'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _savePdf(context),
                          icon: const Icon(Icons.save_alt_outlined, size: 18),
                          label: const Text('حفظ PDF'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _print(context),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('طباعة مباشرة'),
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

  // ----- PDF generation (clean Arabic RTL) -----
  Future<pw.Document> _buildPdf() async {
    final regular = await _loadArabicFont();
    final bold = await _loadArabicBoldFont();
    final doc = pw.Document();

    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => _buildPdfContent(ctx, regular, bold),
      ),
    );
    return doc;
  }

  List<pw.Widget> _buildPdfContent(
    pw.Context ctx,
    pw.Font regular,
    pw.Font bold,
  ) {
    final invoice = widget.invoice;
    final customerName = widget.customerName;
    final phone = widget.customerPhone;
    return [
      pw.Center(
        child: pw.Text(
          invoice.storeName,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: bold,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text(
          'فاتورة بيع',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
            font: regular,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ),
      pw.Divider(),
      pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _pdfMetaRow('رقم الفاتورة:', invoice.id, regular, bold),
            _pdfMetaRow(
              'التاريخ:',
              '${invoice.date.day}/${invoice.date.month}/${invoice.date.year} '
                  '${invoice.date.hour.toString().padLeft(2, '0')}:'
                  '${invoice.date.minute.toString().padLeft(2, '0')}',
              regular,
              bold,
            ),
            _pdfMetaRow('الزبون:', customerName, regular, bold),
            if (phone != null) _pdfMetaRow('الهاتف:', phone, regular, bold),
            _pdfMetaRow(
                'طريقة الدفع:', invoice.paymentType.arabicLabel, regular, bold),
          ],
        ),
      ),
      pw.Divider(),
      // Items table with RTL alignment
      pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(3),
            3: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: ['الصنف', 'الكمية', 'السعر', 'الإجمالي']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, font: bold),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.center,
                        ),
                      ))
                  .toList(),
            ),
            ...invoice.items.map(
              (l) => pw.TableRow(
                children: [
                  _pdfCell(l.product.name, regular),
                  _pdfCell('${l.quantity}', regular, align: pw.TextAlign.center),
                  _pdfCell(Money.format(l.product.unitPrice), regular,
                      align: pw.TextAlign.center),
                  _pdfCell(Money.format(l.lineTotal), bold,
                      align: pw.TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.Divider(),
      pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _pdfMetaRow('المجموع الفرعي:',
                Money.formatWithCurrency(invoice.subtotal), regular, bold),
            _pdfMetaRow('المدفوع:',
                Money.formatWithCurrency(invoice.paid), regular, bold),
            if (invoice.balance > 0)
              _pdfMetaRow('المتبقي (دين):',
                  Money.formatWithCurrency(invoice.balance), regular, bold),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.blueGrey50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'الإجمالي النهائي:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, font: bold),
              ),
              pw.Text(
                Money.formatWithCurrency(invoice.total),
                style: pw.TextStyle(
                  fontSize: 14,
                  font: bold,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 16),
      pw.Center(
        child: pw.Text(
          'شكراً لتعاملكم معنا',
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey600,
            font: regular,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ),
    ];
  }

  pw.Widget _pdfCell(String text, pw.Font font, {pw.TextAlign? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
        textDirection: pw.TextDirection.rtl,
        textAlign: align,
      ),
    );
  }

  pw.Widget _pdfMetaRow(
      String label, String value, pw.Font regular, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: regular, fontSize: 11),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: bold, fontSize: 11),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ----- Export actions -----
  Future<void> _savePdf(BuildContext context) async {
    try {
      final doc = await _buildPdf();
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'invoice_${widget.invoice.id}.pdf',
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
        name: 'invoice_${widget.invoice.id}',
      );
    } catch (e) {
      _showError(context, e);
    }
  }

  /// Renders the receipt as a PNG image using the `printing` package's
  /// `RasterDocument` API. The resulting bytes are shared via the OS
  /// share sheet (mobile) or downloaded (web).
  Future<void> _exportPng() async {
    try {
      final doc = await _buildPdf();
      final pdfBytes = await doc.save();
      // Render the first page at 2x scale for crisp output.
      final images = await Printing.raster(
        pdfBytes,
        dpi: 144, // 2x of 72 dpi
      ).toList();
      if (images.isEmpty) {
        if (mounted) {
          _showError(context, 'تعذّر تحويل الفاتورة إلى صورة');
        }
        return;
      }
      final pngBytes = await images.first.toPng();
      await Printing.sharePdf(
        bytes: pngBytes,
        filename: 'invoice_${widget.invoice.id}.png',
      );
    } catch (e) {
      if (mounted) _showError(context, e);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تعذّرت عملية التصدير: $error'),
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
    return const Row(
      children: [
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
