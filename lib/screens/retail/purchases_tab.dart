import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_state.dart';
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
/// an orderable line in this tab. The wholesale price (per carton) is
/// initially derived from the product's `wholesaleCost` field — but
/// the user can edit it dynamically per supplier by tapping the
/// "تعديل السعر" (Edit Price) icon. Edited prices override the
/// derived value until the user resets them.
///
/// Items can also be removed from the active order list (the cart)
/// via the delete icon on each summary row.
class PurchasesTab extends StatefulWidget {
  const PurchasesTab({super.key});

  @override
  State<PurchasesTab> createState() => _PurchasesTabState();
}

class _PurchasesTabState extends State<PurchasesTab> {
  final _supplierName = TextEditingController();
  final _supplierPhone = TextEditingController();
  final Map<String, int> _quantities = {};

  /// Per-product override of the carton price. Initial values are
  /// derived from `wholesaleCost × cartonSize` (or `unitPrice × 0.85`
  /// as a fallback margin). Users can tap "تعديل السعر" to override.
  final Map<String, double> _priceOverrides = {};

  static const int _defaultCartonSize = 12;

  /// Returns the wholesale catalog with derived or user-overridden prices.
  /// Reads from the active [RetailStore] (called from the build method
  /// after `context.watch` has subscribed to changes).
  List<Product> _catalogFromStore(RetailStore store) {
    final products = store.products;
    return products.map((p) {
      final derivedPrice = p.wholesaleCost > 0
          ? p.wholesaleCost * _defaultCartonSize
          : p.unitPrice * _defaultCartonSize * 0.85;
      final cartonPrice =
          _priceOverrides[p.id] ?? derivedPrice;
      return p.copyWith(
        cartonPrice: cartonPrice,
        cartonSize: _defaultCartonSize,
      );
    }).toList();
  }

  /// Fallback getter that uses [context.read] — kept for legacy
  /// call sites that haven't been refactored to pass the store.
  List<Product> get _catalog => _catalogFromStore(context.read<RetailStore>());

  double _totalFor(List<Product> catalog) => _quantities.entries.fold(
        0.0,
        (s, e) {
          final match = catalog.where((p) => p.id == e.key).firstOrNull;
          if (match == null) return s;
          return s + match.cartonPrice * e.value;
        },
      );

  double get _total => _totalFor(_catalog);

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

  /// Removes a product from the active order list entirely (sets qty to 0).
  void _removeFromOrder(String productId) {
    setState(() {
      _quantities.remove(productId);
    });
  }

  /// Opens an inline edit dialog for the carton price of the given product.
  Future<void> _editPrice(Product product) async {
    final controller = TextEditingController(
      text: Money.format(_priceOverrides[product.id] ??
          (product.wholesaleCost > 0
              ? product.wholesaleCost * _defaultCartonSize
              : product.unitPrice * _defaultCartonSize * 0.85)),
    );
    final result = await showDialog<double>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل سعر الكرتون'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('المنتج: ${product.name}',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('السعر الحالي مستمد من التكلفة. أدخل السعر الجديد للمورد الحالي:',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'سعر الكرتون (أوقية)',
                  prefixIcon: Icon(Icons.attach_money, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('إلغاء'),
            ),
            if (_priceOverrides.containsKey(product.id))
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(-1.0); // sentinel: reset
                },
                child: const Text('استعادة السعر الافتراضي'),
              ),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(controller.text.trim());
                if (v == null || v < 0) return;
                Navigator.of(dialogContext).pop(v);
              },
              child: const Text('حفظ السعر'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (result < 0) {
        // Reset sentinel — remove the override.
        _priceOverrides.remove(product.id);
      } else {
        _priceOverrides[product.id] = result;
      }
    });
  }

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
      final p = _catalog.where((x) => x.id == pid).firstOrNull;
      if (p == null) return; // cascading-delete safety
      buffer
        ..writeln('• ${p.name}')
        ..writeln('  الكمية: $qty كرتون')
        ..writeln('  السعر: ${Money.format(p.cartonPrice)} أوقية')
        ..writeln();
    });
    // Pull the store name dynamically from the authenticated user —
    // never hardcoded.
    final authUser = context.read<AuthState>().user;
    final storeName = authUser?.businessName.isNotEmpty == true
        ? authUser!.businessName
        : 'متجر التجزئة';
    buffer
      ..writeln('الإجمالي: ${Money.format(_total)} أوقية')
      ..writeln()
      ..writeln('مع خالص الشكر — $storeName');
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
    // Watch the store so we rebuild when products change.
    final store = context.watch<RetailStore>();

    // Cascading-delete hook: prune any quantities entries that point
    // to product ids removed from the store since the last rebuild.
    // This prevents the order list from holding references to deleted
    // products (which would otherwise cause firstWhere to throw).
    final removed = store.consumeRemovedProductIds();
    if (removed.isNotEmpty) {
      // Use a post-frame callback to avoid mutating state during
      // build — we'll prune in the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          for (final id in removed) {
            _quantities.remove(id);
            _priceOverrides.remove(id);
          }
        });
      });
    }

    final isWide = context.isDesktop || context.isTablet;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            title: 'إدارة المشتريات',
            subtitle:
                'كتالوج السوق مشتق من مخزونك — اضغط "تعديل السعر" لتحديث الأسعار حسب المورد',
            icon: Icons.shopping_cart_checkout_outlined,
          ),
          const SizedBox(height: 16),
          if (isWide)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      flex: 6,
                      child: SingleChildScrollView(child: _buildCatalog())),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 4,
                      child: SingleChildScrollView(child: _buildSummary())),
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
      ),
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
                priceOverridden: _priceOverrides.containsKey(p.id),
                onIncrement: () => _increment(p),
                onDecrement: () => _decrement(p),
                onEditPrice: () => _editPrice(p),
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
                final p = _catalog.where((x) => x.id == e.key).firstOrNull;
                if (p == null) {
                  return const SizedBox.shrink(); // cascading-delete safety
                }
                return _SummaryLine(
                  productName: p.name,
                  quantity: e.value,
                  unitPrice: p.cartonPrice,
                  onRemove: () => _removeFromOrder(e.key),
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

/// A single product row in the wholesale catalog. Shows the product
/// name, derived carton price (or "سعر مخصص" badge if overridden), and
/// +/- buttons plus an "edit price" action.
class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.quantity,
    required this.priceOverridden,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEditPrice,
  });

  final Product product;
  final int quantity;
  final bool priceOverridden;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEditPrice;

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
                  Row(
                    children: [
                      LtrText(
                        '${Money.format(product.cartonPrice)} أوقية / كرتون (${product.cartonSize} وحدة)',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      if (priceOverridden) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'سعر مخصص',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Edit price action
            IconButton(
              onPressed: onEditPrice,
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppTheme.primary),
              tooltip: 'تعديل السعر',
              visualDensity: VisualDensity.compact,
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

/// A single line in the active order summary. Includes a delete icon
/// to remove the item from the cart entirely.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.onRemove,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close,
                size: 16, color: AppTheme.danger),
            tooltip: 'حذف من الطلب',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              productName,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          LtrText('×$quantity',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 12),
          LtrText(
            Money.formatWithCurrency(unitPrice * quantity),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
