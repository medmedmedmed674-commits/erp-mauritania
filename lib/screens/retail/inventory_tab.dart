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
///
/// Shows the live catalogue with category filters + a floating
/// "Add New Product" button that opens a modal form.
///
/// ## Bulk delete
/// Long-press any product to enter selection mode. In selection mode,
/// each card shows a checkbox; tap to toggle selection. A bulk delete
/// action appears in the app bar that removes all selected products
/// with a single confirmation dialog.
class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  ProductCategory? _filter;
  String _search = '';
  final Set<String> _selected = <String>{};
  bool _selectionMode = false;

  List<Product> get _filtered {
    final all = context.read<RetailStore>().products;
    return all.where((p) {
      if (_filter != null && p.category != _filter) return false;
      if (_search.trim().isNotEmpty &&
          !p.name.contains(_search.trim())) return false;
      return true;
    }).toList();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      if (_selected.isEmpty) _selectionMode = false;
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selected.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selected.clear();
      _selectionMode = false;
    });
  }

  Future<void> _confirmBulkDelete() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد حذف المنتجات'),
          content: Text(
              'هل أنت متأكد من حذف $count منتج؟ لا يمكن التراجع عن هذه العملية.'),
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
              child: const Text('حذف الكل'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    // Capture messenger + store before mutating.
    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<RetailStore>();
    for (final id in _selected.toList()) {
      store.deleteProduct(id);
    }
    final deletedCount = count;
    _exitSelectionMode();
    messenger.showSnackBar(
      SnackBar(
        content: Text('تم حذف $deletedCount منتج'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header — switches between filter bar and bulk-action bar
              if (_selectionMode) ...[
                Container(
                  color: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _exitSelectionMode,
                      ),
                      Text(
                        '${_selected.length} محدد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => setState(() {
                                  // Select all currently filtered items
                                  for (final p in _filtered) {
                                    _selected.add(p.id);
                                  }
                                }),
                        icon: const Icon(Icons.select_all,
                            color: Colors.white, size: 18),
                        label: const Text('تحديد الكل',
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _confirmBulkDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 18),
                        label: const Text('حذف المحدد',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        title: 'المخزن والمخزون',
                        subtitle:
                            'تتبّع الكميات والتنبيهات والمخزون حسب الفئة — اضغط مطولاً للتحديد المتعدد',
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
                            child:
                                DropdownButtonFormField<ProductCategory?>(
                              value: _filter,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'الفئة',
                                  prefixIcon:
                                      Icon(Icons.filter_list, size: 18),
                                  isDense: true),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('كل الفئات')),
                                ...ProductCategory.values.map(
                                  (c) => DropdownMenuItem(
                                      value: c, child: Text(c.arabicLabel)),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filter = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'لا توجد أصناف مطابقة',
                        subtitle: 'جرّب تعديل البحث أو الفلاتر',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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
                          return _InventoryCard(
                            product: p,
                            selected: _selected.contains(p.id),
                            selectionMode: _selectionMode,
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelection(p.id);
                              }
                            },
                            onLongPress: () {
                              if (!_selectionMode) {
                                _enterSelectionMode(p.id);
                              } else {
                                _toggleSelection(p.id);
                              }
                            },
                            onConfirmDelete: () =>
                                _confirmDeleteSingle(p),
                          );
                        },
                      ),
              ),
            ],
          ),
          // Floating action button — hidden in selection mode
          if (!_selectionMode)
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
      ),
    );
  }

  Future<void> _confirmDeleteSingle(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
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
      final store = context.read<RetailStore>();
      store.deleteProduct(product.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم حذف "${product.name}"'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.product,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onConfirmDelete,
  });

  final Product product;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.05)
          : AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.primary : AppTheme.divider,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
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
                        child: Icon(product.icon,
                            size: 18, color: product.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800),
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
                              fontSize: 11,
                              color: AppTheme.textSecondary),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
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
            ),
            // Selection checkbox in selection mode
            if (selectionMode)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.divider,
                        width: 1.5),
                  ),
                  child: Icon(
                    selected ? Icons.check : null,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Positioned(
                top: 4,
                left: 4,
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
