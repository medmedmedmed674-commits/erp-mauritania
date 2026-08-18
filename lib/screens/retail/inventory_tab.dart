import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';
import 'add_product_dialog.dart';

/// Tab 3 — Inventory & Add Product.
/// Shows the live catalogue with category filters + a floating
/// "Add New Product" button that opens a modal form.
class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  ProductCategory? _filter;
  String _search = '';

  List<Product> get _filtered {
    final all = context.read<RetailStore>().products;
    return all.where((p) {
      if (_filter != null && p.category != _filter) return false;
      if (_search.trim().isNotEmpty &&
          !p.name.contains(_search.trim())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              title: 'المخزن والمخزون',
              subtitle: 'تتبّع الكميات والتنبيهات والمخزون حسب الفئة',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                StatPill(
                  label: 'أصناف',
                  value: '${store.products.length} صنف',
                  tone: StatTone.info,
                  icon: Icons.category_outlined,
                ),
                StatPill(
                  label: 'تنبيهات نقص',
                  value: '${store.lowStockCount} صنف',
                  tone: StatTone.danger,
                  icon: Icons.warning_amber_outlined,
                ),
                StatPill(
                  label: 'قيمة المخزون',
                  value: Money.formatWithCurrency(store.stockValue),
                  tone: StatTone.success,
                  icon: Icons.savings_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: BrandedSearchField(
                    hint: 'ابحث عن صنف...',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<ProductCategory?>(
                    value: _filter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'الفئة',
                        prefixIcon: Icon(Icons.filter_list, size: 18),
                        isDense: true),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('كل الفئات')),
                      ...ProductCategory.values.map(
                        (c) => DropdownMenuItem(
                            value: c, child: Text(c.arabicLabel)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'لا توجد أصناف مطابقة',
                      subtitle: 'جرّب تعديل البحث أو الفلاتر',
                    )
                  : GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.55,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final p = _filtered[i];
                        return _InventoryCard(product: p);
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => showAddProductDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج جديد'),
          ),
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.product});
  final Product product;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف المنتج'),
          content: Text(
              'هل أنت متأكد من حذف "${product.name}"؟ لا يمكن التراجع عن هذه العملية.'),
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
    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      context.read<RetailStore>().deleteProduct(product.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم حذف "${product.name}"'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: product.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(product.icon, size: 18, color: product.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.category.arabicLabel,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.isLowStock) ...[
                        const SizedBox(width: 6),
                        const StatPill(
                          label: 'منخفض',
                          value: '',
                          tone: StatTone.danger,
                          icon: Icons.warning_amber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'الكمية: ${product.stock}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: LtrText(
                            Money.formatWithCurrency(product.unitPrice),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Long-press hint affordance
              Positioned(
                top: 0,
                left: 0,
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
