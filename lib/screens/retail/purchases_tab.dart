import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../utils/validators.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/responsive.dart';
import '../../widgets/shared_widgets.dart';

/// Tab 4 — Purchases & WhatsApp Ordering.
///
/// The wholesale catalog is **automatically synced** from the retail
/// inventory: each item in the store's `RetailStore.products` becomes
/// an orderable line in this tab, and the wholesale price (per carton)
/// is derived from the product's `wholesaleCost` field via the
/// `_Product.orderCartonPrice` extension below.
///
/// The "Send Order" action launches a WhatsApp chat with the supplier
/// pre-filled with the itemized order invoice.
class PurchasesTab extends StatefulWidget {
  const PurchasesTab({super.key});

  @override
  State<PurchasesTab> createState() => _PurchasesTabState();
}

class _PurchasesTabState extends State<PurchasesTab> {
  final _supplierName = TextEditingController();
  final _supplierPhone = TextEditingController();
  final Map<String, int> _quantities = {};

  /// Returns the wholesale catalog: live inventory items projected to
  /// "carton" wholesale entries. The wholesale price is derived from
  /// `wholesaleCost × cartonSize` (or `unitPrice × 0.85` as a fallback
  /// when no cost is set, to give an indicative 15% margin).
  List<Product> get _catalog {
    final products = context.read<RetailStore>().products;
    return products
        .map((p) {
          final cartonSize = 12; // default carton size
          final cartonPrice = p.wholesaleCost > 0
              ? p.wholesaleCost * cartonSize
              : p.unitPrice * cartonSize * 0.85;
          return p.copyWith(
            cartonPrice: cartonPrice,
            cartonSize: cartonSize,
          );
        })
        .toList();
  }

  double get _total => _quantities.entries.fold(
        0.0,
        (s, e) =>
            s +
            _catalog.firstWhere((p) => p.id == e.key).cartonPrice * e.value,
      );

  void _setQty(Product p, int q) {
    setState(() {
      if (q <= 0) {
        _quantities.remove(p.id);
      } else {
        _quantities[p.id] = q;
      }
    });
  }

  void _increment(Product p) => _setQty(p, (_quantities[p.id] ?? 0) + 1);

  void _decrement(Product p) => _setQty(p, (_quantities[p.id] ?? 0) - 1);

  Future<void> _sendWhatsApp() async {
    final nameError =
        AppValidators.requiredField('اسم المورد', _supplierName.text);
    if (nameError != null) {
      _toast(nameError);
      return;
    }
    final phoneError = _validateWhatsAppNumber(_supplierPhone.text);
    if (phoneError != null) {
      _toast(phoneError);
      return;
    }
    if (_quantities.isEmpty) {
      _toast('أضف منتجاً واحداً على الأقل');
      return;
    }

    final message = _buildMessage();
    final digits = _supplierPhone.text.replaceAll(RegExp(r'\D'), '');
    final normalized = digits.length == 8 ? '222$digits' : digits;
    final uri = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('تعذّر فتح واتساب — تأكد من تثبيت التطبيق');
    }
  }

  String _buildMessage() {
    final buffer = StringBuffer()
      ..writeln('مرحباً، ${_supplierName.text.trim()}')
      ..writeln()
      ..writeln('نرجو تزويدنا بالطلب التالي:')
      ..writeln();
    _quantities.forEach((pid, qty) {
      final p = _catalog.firstWhere((x) => x.id == pid);
      buffer
        ..writeln('• ${p.name}')
        ..writeln('  الكمية: $qty كرتون')
        ..writeln('  السعر: ${Money.format(p.cartonPrice)} أوقية')
        ..writeln();
    });
    buffer
      ..writeln('الإجمالي: ${Money.format(_total)} أوقية')
      ..writeln()
      ..writeln('مع خالص الشكر — مؤسسة النور للتجزئة');
    return buffer.toString();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  String? _validateWhatsAppNumber(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'يرجى إدخال رقم المورد';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8 && digits.length != 11) {
      return 'الرقم يجب أن يكون 8 أرقام محلية أو 11 رقماً دولياً';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isDesktop || context.isTablet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'إدارة المشتريات',
          subtitle: 'كتالوج السوق مشتق تلقائياً من مخزونك — اطلب عبر واتساب',
          icon: Icons.shopping_cart_checkout_outlined,
        ),
        const SizedBox(height: 16),
        if (isWide)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: SingleChildScrollView(child: _buildCatalog())),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: SingleChildScrollView(child: _buildSummary())),
              ],
            ),
          )
        else
          Expanded(
            child: ListView(
              children: [
                _buildCatalog(),
                const SizedBox(height: 16),
                _buildSummary(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCatalog() {
    final catalog = _catalog;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'كتالوج سوق الجملة',
          subtitle: 'مزامنة تلقائية مع مخزونك الحالي',
          icon: Icons.sync_outlined,
        ),
        const SizedBox(height: 12),
        if (catalog.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد منتجات في المخزون',
            subtitle: 'أضف منتجات أولاً من تبويب المخزون لتظهر هنا',
          )
        else
          ...catalog.map((p) => _ProductRow(
                product: p,
                quantity: _quantities[p.id] ?? 0,
                onIncrement: () => _increment(p),
                onDecrement: () => _decrement(p),
              )),
      ],
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('تفاصيل الطلب',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            TextField(
              controller: _supplierName,
              decoration: const InputDecoration(
                labelText: 'اسم المورد',
                prefixIcon: Icon(Icons.storefront_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supplierPhone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'رقم واتساب للمورد (8 أرقام)',
                hintText: '2XXX XXXX',
                prefixIcon: Icon(Icons.chat_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            if (_quantities.isEmpty)
              const EmptyState(
                icon: Icons.shopping_basket_outlined,
                title: 'لم تختر أي صنف بعد',
                subtitle: 'حدد الكميات من الكتالوج',
              )
            else
              ..._quantities.entries.map((e) {
                final p = _catalog.firstWhere((x) => x.id == e.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      LtrText('×${e.value}',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 12),
                      LtrText(
                        Money.formatWithCurrency(p.cartonPrice * e.value),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                );
              }),
            const Divider(height: 24),
            Row(
              children: [
                const Text('إجمالي الطلب',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const Spacer(),
                LtrText(
                  Money.formatWithCurrency(_total),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _sendWhatsApp,
              icon: const Icon(Icons.chat, size: 20),
              label: const Text('إرسال الطلب للمورد عبر واتساب'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: product.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(product.icon, size: 22, color: product.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  LtrText(
                    '${Money.format(product.cartonPrice)} أوقية / كرتون (${product.cartonSize} وحدة)',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.danger, size: 22),
                ),
                SizedBox(
                  width: 50,
                  child: LtrText(
                    '$quantity',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.primary, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
