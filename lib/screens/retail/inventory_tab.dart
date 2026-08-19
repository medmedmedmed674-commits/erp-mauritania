import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/product_service.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';
import 'add_product_dialog.dart';

/// Tab 3 — Inventory & Add Product.
///
/// Shows the live catalogue with category filters + a floating
/// "Add New Product" button that opens a modal form.
///
/// ## Per-card actions
/// Each product card has a 3-dots [PopupMenuButton] in the top-right
/// corner with two actions:
///   - "تعديل المنتج" → opens [showEditProductDialog] pre-populated.
///   - "حذف المنتج" → opens a confirmation dialog, then deletes.
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

  Future<void> _editProduct(Product product) async {
    await showEditProductDialog(context, product);
  }

  Future<void> _deleteSingle(Product product) async {
    final confirmed = await confirmDeleteProduct(context, product);
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<RetailStore>();
    // Use the ProductService cascading-delete entry point — this
    // both removes the product AND records the id so the Purchases
    // tab can prune itself on the next rebuild.
    final service = ProductService(store);
    final result = service.cascadeDeleteProduct(product.id);
    if (result == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('المنتج غير موجود'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('تم حذف "${product.name}" وإزالته من قائمة المشتريات'),
        backgroundColor: AppTheme.danger,
      ),
    );
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

    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<RetailStore>();
    // Use the ProductService bulk-delete helper — internally calls
    // cascadeDeleteProduct for each id, recording every removal in the
    // store's _removedProductIds buffer so the Purchases tab can prune.
    final service = ProductService(store);
    final deletedCount = service.bulkDelete(_selected.toList());
    _exitSelectionMode();
    messenger.showSnackBar(
      SnackBar(
        content: Text('تم حذف $deletedCount منتج وإزالتها من قائمة المشتريات'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  void _onCardTap(Product product) {
    if (_selectionMode) {
      _toggleSelection(product.id);
    }
    // Tap outside selection mode is a no-op — actions are in the menu.
  }

  void _onCardLongPress(Product product) {
    if (!_selectionMode) {
      _enterSelectionMode(product.id);
    } else {
      _toggleSelection(product.id);
    }
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
                            'اضغط على ⋮ للتعديل أو الحذف — اضغط مطولاً للتحديد المتعدد',
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
                            onTap: () => _onCardTap(p),
                            onLongPress: () => _onCardLongPress(p),
                            onEdit: () => _editProduct(p),
                            onDelete: () => _deleteSingle(p),
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
}

/// A single inventory card with 3-dots action menu.
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.product,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: product.imageBytes != null
                            ? Image.memory(
                                product.imageBytes!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _categoryIcon(product),
                              )
                            : product.imageAsset != null
                                ? Image.asset(
                                    product.imageAsset!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _categoryIcon(product),
                                  )
                                : _categoryIcon(product),
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
            // 3-dots action menu (hidden in selection mode)
            if (!selectionMode)
              Positioned(
                top: 0,
                left: 0,
                child: PopupMenuButton<_CardAction>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  iconColor: AppTheme.textSecondary,
                  padding: EdgeInsets.zero,
                  tooltip: 'خيارات',
                  onSelected: (action) {
                    switch (action) {
                      case _CardAction.edit:
                        onEdit();
                      case _CardAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _CardAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text('تعديل المنتج'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: _CardAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppTheme.danger),
                          SizedBox(width: 8),
                          Text('حذف المنتج'),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            // Selection checkbox in selection mode
            else
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
              ),
          ],
        ),
      ),
    );
  }

  /// Renders the category icon inside a tinted square — used when the
  /// product has no image bytes (default state) or when image decoding
  /// fails for any reason.
  Widget _categoryIcon(Product product) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: product.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(product.icon, size: 18, color: product.color),
    );
  }
}

enum _CardAction { edit, delete }
