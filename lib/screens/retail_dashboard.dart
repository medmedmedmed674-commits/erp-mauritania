import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_dashboard_scaffold.dart';
import '../widgets/responsive.dart';
import '../widgets/shared_widgets.dart';

/// Module 3 — Retail Store Dashboard.
///
/// Adaptive navigation: bottom nav on mobile, side rail on tablet/desktop.
/// Four primary sections:
/// 1. نقطة البيع (POS)
/// 2. إدارة الزبناء والديون
/// 3. المخزن والمخزون
/// 4. إدارة المشتريات
class RetailDashboard extends StatefulWidget {
  const RetailDashboard({super.key, this.businessName = 'مؤسسة النور للتجزئة'});

  final String businessName;

  @override
  State<RetailDashboard> createState() => _RetailDashboardState();
}

class _RetailDashboardState extends State<RetailDashboard> {
  int _index = 0;

  static const _tabs = [
    DashboardTab(
        label: 'نقطة البيع', icon: Icons.point_of_sale, subtitle: 'POS'),
    DashboardTab(
        label: 'الزبناء والديون',
        icon: Icons.people_alt_outlined,
        subtitle: 'العملاء والمستحقات'),
    DashboardTab(
        label: 'المخزن والمخزون',
        icon: Icons.inventory_2_outlined,
        subtitle: 'الكميات والتنبيهات'),
    DashboardTab(
        label: 'إدارة المشتريات',
        icon: Icons.shopping_cart_checkout_outlined,
        subtitle: 'تزويد المتجر'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveDashboardScaffold(
      title: widget.businessName,
      businessName: widget.businessName,
      tabs: _tabs,
      currentIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      child: IndexedStack(
        index: _index,
        children: const [
          _PosSection(),
          _CustomersSection(),
          _InventorySection(),
          _PurchasesSection(),
        ],
      ),
    );
  }
}

// ===========================================================================
// SECTION 1 — POS
// ===========================================================================
class _PosSection extends StatefulWidget {
  const _PosSection();

  @override
  State<_PosSection> createState() => _PosSectionState();
}

class _PosSectionState extends State<_PosSection> {
  final List<CartLine> _cart = [];
  CustomerType _checkoutType = CustomerType.walkIn;
  Customer? _selectedCustomer;

  void _add(Product p) {
    setState(() {
      final i = _cart.indexWhere((l) => l.product.id == p.id);
      if (i == -1) {
        _cart.add(CartLine(product: p, quantity: 1));
      } else {
        _cart[i] = _cart[i].copyWith(quantity: _cart[i].quantity + 1);
      }
    });
  }

  void _dec(Product p) {
    setState(() {
      final i = _cart.indexWhere((l) => l.product.id == p.id);
      if (i == -1) return;
      final q = _cart[i].quantity - 1;
      if (q <= 0) {
        _cart.removeAt(i);
      } else {
        _cart[i] = _cart[i].copyWith(quantity: q);
      }
    });
  }

  void _removeLine(int i) => setState(() => _cart.removeAt(i));

  void _checkout() {
    if (_cart.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CheckoutSheet(
        total: _cartTotal,
        type: _checkoutType,
        customer: _selectedCustomer,
        onTypeChanged: (t) => setState(() => _checkoutType = t),
        onCustomerChanged: (c) => setState(() => _selectedCustomer = c),
        onConfirm: () {
          Navigator.pop(context);
          _showReceipt();
        },
      ),
    );
  }

  void _showReceipt() {
    setState(_cart.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت عملية البيع بنجاح — تم طباعة الإيصال'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  double get _cartTotal =>
      _cart.fold(0.0, (sum, l) => sum + l.lineTotal);

  @override
  Widget build(BuildContext context) {
    final isSplit = context.isSplit;
    if (isSplit) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: _ProductGrid(
              onAdd: _add,
              onDec: _dec,
              cart: _cart,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: _CartPanel(
              cart: _cart,
              total: _cartTotal,
              onAdd: _add,
              onDec: _dec,
              onRemove: _removeLine,
              onCheckout: _checkout,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: _ProductGrid(
            onAdd: _add,
            onDec: _dec,
            cart: _cart,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: _CartPanel(
            cart: _cart,
            total: _cartTotal,
            onAdd: _add,
            onDec: _dec,
            onRemove: _removeLine,
            onCheckout: _checkout,
          ),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.onAdd,
    required this.onDec,
    required this.cart,
  });

  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onDec;
  final List<CartLine> cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'المنتجات',
          subtitle: 'اضغط على المنتج لإضافته إلى السلة',
          icon: Icons.grid_view_outlined,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: AppData.retailProducts.length,
            itemBuilder: (context, i) {
              final p = AppData.retailProducts[i];
              final inCart = cart
                  .firstWhere(
                    (l) => l.product.id == p.id,
                    orElse: () => CartLine(product: p, quantity: 0),
                  )
                  .quantity;
              return _ProductTile(
                product: p,
                inCart: inCart,
                onAdd: () => onAdd(p),
                onDec: () => onDec(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.inCart,
    required this.onAdd,
    required this.onDec,
  });

  final Product product;
  final int inCart;
  final VoidCallback onAdd;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: product.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(product.icon,
                            size: 36, color: product.color),
                      ),
                      if (product.isLowStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'مخزون منخفض',
                              style:
                                  TextStyle(fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'الكمية: ${product.stock}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Product.formatMRU(product.unitPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  if (inCart > 0) ...[
                    InkWell(
                      onTap: onDec,
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.surfaceAlt,
                        child: Icon(Icons.remove, size: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '$inCart',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                  InkWell(
                    onTap: onAdd,
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.total,
    required this.onAdd,
    required this.onDec,
    required this.onRemove,
    required this.onCheckout,
  });

  final List<CartLine> cart;
  final double total;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onDec;
  final ValueChanged<int> onRemove;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'السلة الحالية',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cart.length} صنف',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (cart.isEmpty)
              const EmptyState(
                icon: Icons.remove_shopping_cart_outlined,
                title: 'السلة فارغة',
                subtitle: 'اضغط على المنتجات لإضافتها',
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final line = cart[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                line.product.color.withValues(alpha: 0.15),
                            child: Icon(line.product.icon,
                                size: 16, color: line.product.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${Product.formatMRU(line.product.unitPrice)} × ${line.quantity}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color:
                                          AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Product.formatMRU(line.lineTotal),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary),
                          ),
                          IconButton(
                            onPressed: () => onRemove(i),
                            icon: const Icon(Icons.close,
                                size: 16, color: AppTheme.danger),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                const Text('الإجمالي',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const Spacer(),
                Text(
                  Product.formatMRU(total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'إتمام الدفع',
              icon: Icons.payment_outlined,
              onPressed: cart.isEmpty ? () {} : onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSheet extends StatelessWidget {
  const _CheckoutSheet({
    required this.total,
    required this.type,
    required this.customer,
    required this.onTypeChanged,
    required this.onCustomerChanged,
    required this.onConfirm,
  });

  final double total;
  final CustomerType type;
  final Customer? customer;
  final ValueChanged<CustomerType> onTypeChanged;
  final ValueChanged<Customer?> onCustomerChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'تأكيد عملية البيع',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('نوع الزبون',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _ChoiceChip(
                      label: 'عميل عادي',
                      selected: type == CustomerType.walkIn,
                      onTap: () => onTypeChanged(CustomerType.walkIn)),
                  _ChoiceChip(
                      label: 'زبون دائم مسجل',
                      selected: type == CustomerType.registered,
                      onTap: () => onTypeChanged(CustomerType.registered)),
                  _ChoiceChip(
                      label: 'إضافة زبون جديد',
                      selected: type == CustomerType.newCustomer,
                      onTap: () => onTypeChanged(CustomerType.newCustomer)),
                ],
              ),
              const SizedBox(height: 16),
              if (type == CustomerType.registered)
                DropdownButtonFormField<Customer>(
                  value: customer,
                  decoration: const InputDecoration(
                      labelText: 'اختر زبوناً مسجلاً'),
                  items: AppData.customers
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.name} — ${c.phone}'),
                          ))
                      .toList(),
                  onChanged: onCustomerChanged,
                ),
              if (type == CustomerType.newCustomer) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            labelText: 'اسم الزبون'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            labelText: 'الهاتف'),
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'المدينة'),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('الإجمالي المستحق',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(
                      Product.formatMRU(total),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryActionButton(
                label: 'تأكيد الدفع وإصدار الإيصال',
                icon: Icons.check_circle_outline,
                onPressed: onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primary
          : AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// SECTION 2 — Customers & Debt
// ===========================================================================
class _CustomersSection extends StatelessWidget {
  const _CustomersSection();

  @override
  Widget build(BuildContext context) {
    final customers = AppData.customers;
    final totalDebt =
        customers.fold(0.0, (s, c) => s + c.outstandingDebt);
    final totalProfit =
        customers.fold(0.0, (s, c) => s + c.totalProfit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'إدارة الزبناء والديون',
          subtitle: 'سجل العملاء، الأرصدة المستحقة، وهامش الربح لكل زبون',
          icon: Icons.people_alt_outlined,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            StatPill(
              label: 'إجمالي العملاء',
              value: '${customers.length} زبون',
              tone: StatTone.info,
              icon: Icons.people_outline,
            ),
            StatPill(
              label: 'إجمالي الديون',
              value: Product.formatMRU(totalDebt),
              tone: StatTone.danger,
              icon: Icons.account_balance_wallet_outlined,
            ),
            StatPill(
              label: 'صافي الأرباح',
              value: Product.formatMRU(totalProfit),
              tone: StatTone.success,
              icon: Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CustomerCard(c: customers[i]),
          ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.c});
  final Customer c;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
          child: Text(
            c.name.substring(0, 1),
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.w800),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                c.name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            if (c.hasDebt)
              StatPill(
                label: 'دين مستحق',
                value: c.debtLabel,
                tone: StatTone.danger,
                icon: Icons.priority_high,
              )
            else
              const StatPill(
                label: 'خالص',
                value: 'لا دين',
                tone: StatTone.success,
                icon: Icons.check_circle_outline,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 12,
            children: [
              _InfoChip(
                  icon: Icons.phone_outlined,
                  label: c.phone,
                  direction: TextDirection.ltr),
              _InfoChip(icon: Icons.location_on_outlined, label: c.city),
              _InfoChip(
                  icon: Icons.trending_up,
                  label: 'ربح: ${c.profitLabel}',
                  tone: StatTone.success),
            ],
          ),
        ),
        children: [
          if (isWide)
            Row(
              children: const [
                Expanded(child: Text('فواتير الزبون')),
              ],
            )
          else
            Container(),
          _CustomerInvoiceList(customerId: c.id),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('عرض كل الفواتير'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('تحصيل دفعة'),
              ),
              if (c.hasDebt)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('تسوية الدين'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.tone,
    this.direction,
  });
  final IconData icon;
  final String label;
  final StatTone? tone;
  final TextDirection? direction;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatTone.success => AppTheme.success,
      StatTone.danger => AppTheme.danger,
      StatTone.warning => AppTheme.warning,
      StatTone.info => AppTheme.info,
      _ => AppTheme.textSecondary,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          textDirection: direction,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CustomerInvoiceList extends StatelessWidget {
  const _CustomerInvoiceList({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) {
    final list = AppData.invoices
        .where((i) => i.customerId == customerId)
        .toList();
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا توجد فواتير مسجلة لهذا الزبون',
          style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.8),
              fontSize: 13),
        ),
      );
    }
    return Column(
      children: list
          .map(
            (inv) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.id,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${inv.date.day}/${inv.date.month}/${inv.date.year}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    Product.formatMRU(inv.total),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ===========================================================================
// SECTION 3 — Inventory
// ===========================================================================
class _InventorySection extends StatefulWidget {
  const _InventorySection();

  @override
  State<_InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<_InventorySection> {
  ProductCategory? _filter;
  String _search = '';

  List<Product> get _filtered => AppData.retailProducts.where((p) {
        if (_filter != null && p.category != _filter) return false;
        if (_search.trim().isNotEmpty &&
            !p.name.contains(_search.trim())) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final lowCount =
        AppData.retailProducts.where((p) => p.isLowStock).length;
    final stockValue = AppData.retailProducts.fold<double>(
        0, (s, p) => s + p.unitPrice * p.stock);
    return Column(
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
              value: '${AppData.retailProducts.length} صنف',
              tone: StatTone.info,
              icon: Icons.category_outlined,
            ),
            StatPill(
              label: 'تنبيهات نقص',
              value: '$lowCount صنف',
              tone: StatTone.danger,
              icon: Icons.warning_amber_outlined,
            ),
            StatPill(
              label: 'قيمة المخزون',
              value: Product.formatMRU(stockValue),
              tone: StatTone.success,
              icon: Icons.savings_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BrandedSearchField(
                hint: 'ابحث عن صنف...',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButtonFormField<ProductCategory?>(
              value: _filter,
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
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              final p = _filtered[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: p.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(p.icon, size: 18, color: p.color),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p.name,
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
                          Text(
                            p.category.arabicLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                          ),
                          const Spacer(),
                          if (p.isLowStock)
                            const StatPill(
                              label: 'منخفض',
                              value: '',
                              tone: StatTone.danger,
                              icon: Icons.warning_amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'الكمية: ${p.stock}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            Product.formatMRU(p.unitPrice),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SECTION 4 — Purchases (replenishment from wholesale market)
// ===========================================================================
class _PurchasesSection extends StatefulWidget {
  const _PurchasesSection();

  @override
  State<_PurchasesSection> createState() => _PurchasesSectionState();
}

class _PurchasesSectionState extends State<_PurchasesSection> {
  final List<CartLine> _purchases = [];

  void _add(Product p) {
    setState(() {
      final i =
          _purchases.indexWhere((l) => l.product.id == p.id);
      if (i == -1) {
        _purchases.add(CartLine(product: p, quantity: 1));
      } else {
        _purchases[i] =
            _purchases[i].copyWith(quantity: _purchases[i].quantity + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isDesktop || context.isTablet;
    final total =
        _purchases.fold(0.0, (s, l) => s + l.lineTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'إدارة المشتريات',
          subtitle: 'تزويد المتجر من سوق الجملة لتعويض المخزون المباع',
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
                  child: SingleChildScrollView(
                    child: _PurchaseCatalog(onAdd: _add),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: _PurchaseSummary(
                      purchases: _purchases,
                      total: total,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView(
              children: [
                _PurchaseCatalog(onAdd: _add),
                const SizedBox(height: 16),
                _PurchaseSummary(
                  purchases: _purchases,
                  total: total,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PurchaseCatalog extends StatelessWidget {
  const _PurchaseCatalog({required this.onAdd});
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'كتالوج سوق الجملة',
          subtitle: 'أسعار الشراء من الموردين لتعويض المخزون',
          icon: Icons.store_outlined,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppData.wholesaleProducts.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final p = AppData.wholesaleProducts[i];
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(p.icon, size: 18, color: p.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text(
                        'الكرتون ${p.cartonSize} وحدة • ${p.batchNumber ?? "—"}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Product.formatMRU(p.cartonPrice),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => onAdd(p),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('إضافة للشراء'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PurchaseSummary extends StatelessWidget {
  const _PurchaseSummary({
    required this.purchases,
    required this.total,
  });

  final List<CartLine> purchases;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('طلب شراء',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            if (purchases.isEmpty)
              const EmptyState(
                icon: Icons.shopping_basket_outlined,
                title: 'لا توجد أصناف مضافة بعد',
              )
            else
              ...purchases.map(
                (l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.product.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('×${l.quantity}',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 12),
                      Text(
                        Product.formatMRU(l.lineTotal),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                const Text('إجمالي الشراء',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary)),
                const Spacer(),
                Text(
                  Product.formatMRU(total),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'تأكيد أمر الشراء',
              icon: Icons.send_outlined,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
