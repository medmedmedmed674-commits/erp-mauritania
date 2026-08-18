import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/adaptive_dashboard_scaffold.dart';
import '../widgets/responsive.dart';
import '../widgets/shared_widgets.dart';

/// Module 4 — Wholesale Merchant Dashboard.
///
/// Adaptive navigation: bottom nav on mobile, side rail on tablet/desktop.
/// Five primary sections:
/// 1. بيع الجملة (Bulk Sales terminal)
/// 2. إدارة المخازن (Multi-warehouse inventory)
/// 3. العملاء والديون (B2B ledger)
/// 4. الاستيراد والموردين (Supplier ledger)
/// 5. التحليلات والتقارير (Executive analytics)
class WholesaleDashboard extends StatefulWidget {
  const WholesaleDashboard({super.key, this.businessName = 'مؤسسة النور للجملة'});

  final String businessName;

  @override
  State<WholesaleDashboard> createState() => _WholesaleDashboardState();
}

class _WholesaleDashboardState extends State<WholesaleDashboard> {
  int _index = 0;

  static const _tabs = [
    DashboardTab(
        label: 'بيع الجملة', icon: Icons.local_shipping_outlined, subtitle: 'Bulk Sales'),
    DashboardTab(
        label: 'إدارة المخازن',
        icon: Icons.warehouse_outlined,
        subtitle: 'المخزون والدفعت'),
    DashboardTab(
        label: 'العملاء والديون',
        icon: Icons.people_alt_outlined,
        subtitle: 'B2B Ledger'),
    DashboardTab(
        label: 'الاستيراد والموردين',
        icon: Icons.public_outlined,
        subtitle: 'المستحقات'),
    DashboardTab(
        label: 'التحليلات والتقارير',
        icon: Icons.analytics_outlined,
        subtitle: 'Executive'),
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
          _BulkSalesSection(),
          _WarehousesSection(),
          _B2BCustomersSection(),
          _SuppliersSection(),
          _AnalyticsSection(),
        ],
      ),
    );
  }
}

// ===========================================================================
// SECTION 1 — Bulk Sales
// ===========================================================================
class _BulkSalesSection extends StatefulWidget {
  const _BulkSalesSection();

  @override
  State<_BulkSalesSection> createState() => _BulkSalesSectionState();
}

class _BulkSalesSectionState extends State<_BulkSalesSection> {
  final List<CartLine> _cart = [];
  CustomerType _type = CustomerType.registered;
  Customer? _customer;

  void _add(Product p) {
    setState(() {
      final i = _cart.indexWhere((l) => l.product.id == p.id);
      if (i == -1) {
        _cart.add(CartLine(product: p, quantity: 1));
      } else {
        _cart[i] =
            _cart[i].copyWith(quantity: _cart[i].quantity + 1);
      }
    });
  }

  void _setQty(Product p, int q) {
    setState(() {
      final i = _cart.indexWhere((l) => l.product.id == p.id);
      if (q <= 0) {
        if (i != -1) _cart.removeAt(i);
        return;
      }
      if (i == -1) {
        _cart.add(CartLine(product: p, quantity: q));
      } else {
        _cart[i] = _cart[i].copyWith(quantity: q);
      }
    });
  }

  double get _total => _cart.fold(0.0, (s, l) => s + l.lineTotal);
  int get _cartons => _cart.fold(0, (s, l) => s + l.quantity);

  @override
  Widget build(BuildContext context) {
    final isSplit = context.isSplit;
    if (isSplit) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: _BulkCatalog(
              cart: _cart,
              onAdd: _add,
              onSetQty: _setQty,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: _BulkCheckout(
              cart: _cart,
              total: _total,
              cartons: _cartons,
              type: _type,
              customer: _customer,
              onTypeChanged: (t) => setState(() => _type = t),
              onCustomerChanged: (c) =>
                  setState(() => _customer = c),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: _BulkCatalog(
                cart: _cart, onAdd: _add, onSetQty: _setQty),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 4,
          child: _BulkCheckout(
            cart: _cart,
            total: _total,
            cartons: _cartons,
            type: _type,
            customer: _customer,
            onTypeChanged: (t) => setState(() => _type = t),
            onCustomerChanged: (c) => setState(() => _customer = c),
          ),
        ),
      ],
    );
  }
}

class _BulkCatalog extends StatelessWidget {
  const _BulkCatalog({
    required this.cart,
    required this.onAdd,
    required this.onSetQty,
  });

  final List<CartLine> cart;
  final ValueChanged<Product> onAdd;
  final void Function(Product, int) onSetQty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'بيع الجملة',
          subtitle: 'تيرمنال البيع بالجملة بالكرتون والوحدة',
          icon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: AppData.wholesaleProducts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = AppData.wholesaleProducts[i];
            final inCart = cart
                .firstWhere((l) => l.product.id == p.id,
                    orElse: () => CartLine(product: p, quantity: 0))
                .quantity;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(p.icon, size: 22, color: p.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              _BulkChip(
                                icon: Icons.inventory_2_outlined,
                                label: 'مخزون: ${p.stock} كرتون',
                              ),
                              _BulkChip(
                                icon: Icons.batch_prediction_outlined,
                                label: 'دفعة: ${p.batchNumber ?? "—"}',
                                direction: TextDirection.ltr,
                              ),
                              _BulkChip(
                                icon: Icons.straighten_outlined,
                                label: '${p.cartonSize} وحدة/كرتون',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Money.formatWithCurrency(p.cartonPrice),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary),
                        ),
                        const Text('لكل كرتون',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        if (inCart > 0)
                          IconButton(
                            onPressed: () => onSetQty(p, inCart - 1),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.danger, size: 22),
                          ),
                        SizedBox(
                          width: 50,
                          child: TextFormField(
                            initialValue: inCart > 0 ? '$inCart' : '',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              hintText: '0',
                            ),
                            onChanged: (v) =>
                                onSetQty(p, int.tryParse(v) ?? 0),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onAdd(p),
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppTheme.primary, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BulkChip extends StatelessWidget {
  const _BulkChip({
    required this.icon,
    required this.label,
    this.direction,
  });
  final IconData icon;
  final String label;
  final TextDirection? direction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            textDirection: direction,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BulkCheckout extends StatelessWidget {
  const _BulkCheckout({
    required this.cart,
    required this.total,
    required this.cartons,
    required this.type,
    required this.customer,
    required this.onTypeChanged,
    required this.onCustomerChanged,
  });

  final List<CartLine> cart;
  final double total;
  final int cartons;
  final CustomerType type;
  final Customer? customer;
  final ValueChanged<CustomerType> onTypeChanged;
  final ValueChanged<Customer?> onCustomerChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('فاتورة جملة',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      _ChoiceChip2(
                          label: 'زبون دائم',
                          selected: type == CustomerType.registered,
                          onTap: () => onTypeChanged(
                              CustomerType.registered)),
                      _ChoiceChip2(
                          label: 'زبون جديد',
                          selected: type == CustomerType.newCustomer,
                          onTap: () => onTypeChanged(
                              CustomerType.newCustomer)),
                    ],
                  ),
                ),
              ],
            ),
            if (type == CustomerType.registered) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<Customer>(
                value: customer,
                decoration: const InputDecoration(
                    labelText: 'الزبون'),
                items: AppData.customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} — ${c.city}'),
                        ))
                    .toList(),
                onChanged: onCustomerChanged,
              ),
            ],
            const Divider(height: 24),
            if (cart.isEmpty)
              const EmptyState(
                icon: Icons.remove_shopping_cart_outlined,
                title: 'السلة فارغة',
                subtitle: 'أضف أصنافاً بالكرتون من الكتالوج',
              )
            else
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final l = cart[i];
                    return Row(
                      children: [
                        Icon(l.product.icon,
                            size: 18, color: l.product.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(l.product.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                '${l.quantity} كرتون × ${l.product.cartonSize} = ${l.quantity * l.product.cartonSize} وحدة',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Money.formatWithCurrency(l.lineTotal),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const Divider(height: 20),
            _SummaryRow(
                label: 'عدد الكراتين', value: '$cartons كرتون'),
            const SizedBox(height: 4),
            _SummaryRow(
                label: 'الإجمالي',
                value: Money.formatWithCurrency(total),
                bold: true,
                color: AppTheme.primary),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'إصدار فاتورة جملة',
              icon: Icons.receipt_long_outlined,
              onPressed: cart.isEmpty ? () {} : () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip2 extends StatelessWidget {
  const _ChoiceChip2({
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
      color: selected ? AppTheme.primary : AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// SECTION 2 — Warehouses
// ===========================================================================
class _WarehousesSection extends StatelessWidget {
  const _WarehousesSection();

  @override
  Widget build(BuildContext context) {
    final isWide = context.isTablet || context.isDesktop;
    final stockValue = AppData.wholesaleProducts.fold<double>(
        0, (s, p) => s + p.cartonPrice * p.stock);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'إدارة المخازن',
          subtitle: 'تتبّع المخزون عبر المستودعات والكراتين وأرقام الدفعات',
          icon: Icons.warehouse_outlined,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            const StatPill(
                label: 'المستودع الرئيسي',
                value: 'نواكشوط',
                tone: StatTone.info,
                icon: Icons.location_on_outlined),
            StatPill(
                label: 'قيمة المخزون',
                value: Money.formatWithCurrency(stockValue),
                tone: StatTone.success,
                icon: Icons.savings_outlined),
            const StatPill(
                label: 'مستودع فرعي',
                value: 'نواذيبو',
                tone: StatTone.neutral,
                icon: Icons.location_on_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isWide
              ? _buildWideTable()
              : ListView(
                  children: AppData.wholesaleProducts
                      .map((p) => _WarehouseCard(p: p))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildWideTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('الصنف')),
              DataColumn(label: Text('الدفعة'), numeric: true),
              DataColumn(label: Text('الكمية (كرتون)'), numeric: true),
              DataColumn(label: Text('الوحدات'), numeric: true),
              DataColumn(label: Text('السعر/كرتون'), numeric: true),
              DataColumn(label: Text('القيمة')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: AppData.wholesaleProducts.map((p) {
              return DataRow(
                cells: [
                  DataCell(Row(
                    children: [
                      Icon(p.icon, size: 16, color: p.color),
                      const SizedBox(width: 8),
                      Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ],
                  )),
                  DataCell(Text(p.batchNumber ?? '—',
                      textDirection: TextDirection.ltr)),
                  DataCell(Text('${p.stock}',
                      style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(Text('${p.stock * p.cartonSize}')),
                  DataCell(Text(Money.formatWithCurrency(p.cartonPrice))),
                  DataCell(Text(Money.formatWithCurrency(p.cartonPrice * p.stock),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary))),
                  DataCell(p.isLowStock
                      ? const StatPill(
                          label: 'منخفض',
                          value: '',
                          tone: StatTone.danger,
                          icon: Icons.warning_amber)
                      : const StatPill(
                          label: 'متوفر',
                          value: '',
                          tone: StatTone.success,
                          icon: Icons.check_circle_outline)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({required this.p});
  final Product p;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(p.icon, size: 22, color: p.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                if (p.isLowStock)
                  const StatPill(
                      label: 'منخفض',
                      value: '',
                      tone: StatTone.danger,
                      icon: Icons.warning_amber)
                else
                  const StatPill(
                      label: 'متوفر',
                      value: '',
                      tone: StatTone.success,
                      icon: Icons.check_circle_outline),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _BulkChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${p.stock} كرتون'),
                _BulkChip(
                    icon: Icons.straighten_outlined,
                    label: '${p.stock * p.cartonSize} وحدة'),
                _BulkChip(
                    icon: Icons.batch_prediction_outlined,
                    label: 'دفعة: ${p.batchNumber ?? "—"}',
                    direction: TextDirection.ltr),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('سعر الكرتون',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const Spacer(),
                Text(
                  Money.formatWithCurrency(p.cartonPrice),
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
  }
}

// ===========================================================================
// SECTION 3 — B2B Customers
// ===========================================================================
class _B2BCustomersSection extends StatelessWidget {
  const _B2BCustomersSection();

  @override
  Widget build(BuildContext context) {
    final totalDebt =
        AppData.customers.fold(0.0, (s, c) => s + c.outstandingDebt);
    final totalReceivable =
        AppData.customers.fold(0.0, (s, c) => s + c.totalProfit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'العملاء والديون',
          subtitle: 'سجل B2B، أرصدة مستحقة لك، وفواتير التحصيل',
          icon: Icons.people_alt_outlined,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            StatPill(
                label: 'إجمالي العملاء',
                value: '${AppData.customers.length}',
                tone: StatTone.info,
                icon: Icons.people_outline),
            StatPill(
                label: 'الديون لك',
                value: Money.formatWithCurrency(totalDebt),
                tone: StatTone.warning,
                icon: Icons.account_balance_wallet_outlined),
            StatPill(
                label: 'صافي الأرباح',
                value: Money.formatWithCurrency(totalReceivable),
                tone: StatTone.success,
                icon: Icons.trending_up),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: AppData.customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = AppData.customers[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary
                                .withValues(alpha: 0.12),
                            child: Text(c.name.substring(0, 1),
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _BulkChip(
                                        icon: Icons.phone_outlined,
                                        label: c.phone,
                                        direction:
                                            TextDirection.ltr),
                                    _BulkChip(
                                        icon: Icons.location_on_outlined,
                                        label: c.city),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (c.hasDebt)
                            StatPill(
                                label: 'مستحق',
                                value: c.debtLabel,
                                tone: StatTone.danger,
                                icon: Icons.priority_high),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                                label: 'إجمالي الشراء',
                                value: c.purchasesLabel),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                                label: 'صافي الربح',
                                value: c.profitLabel,
                                color: AppTheme.success),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                                label: 'آخر فاتورة',
                                value: c.lastInvoiceDate != null
                                    ? '${c.lastInvoiceDate!.day}/${c.lastInvoiceDate!.month}/${c.lastInvoiceDate!.year}'
                                    : '—'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.receipt_long_outlined,
                                  size: 16),
                              label: const Text('الفواتير')),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.payments_outlined,
                                  size: 16),
                              label: const Text('تحصيل دفعة')),
                          const Spacer(),
                          TextButton(
                              onPressed: () {},
                              child: const Text('السجل الكامل')),
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
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ===========================================================================
// SECTION 4 — Suppliers (Import & Payables)
// ===========================================================================
class _SuppliersSection extends StatelessWidget {
  const _SuppliersSection();

  @override
  Widget build(BuildContext context) {
    final totalPayable =
        AppData.suppliers.fold(0.0, (s, p) => s + p.payable);
    final totalOrders =
        AppData.suppliers.fold(0.0, (s, p) => s + p.totalOrders);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(
          title: 'الاستيراد والموردين',
          subtitle: 'سجل الموردين والاستيراد، والمستحقات عليك',
          icon: Icons.public_outlined,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            StatPill(
                label: 'الموردين',
                value: '${AppData.suppliers.length}',
                tone: StatTone.info,
                icon: Icons.public_outlined),
            StatPill(
                label: 'المستحقات عليك',
                value: Money.formatWithCurrency(totalPayable),
                tone: StatTone.danger,
                icon: Icons.account_balance_outlined),
            StatPill(
                label: 'إجمالي الطلبات',
                value: Money.formatWithCurrency(totalOrders),
                tone: StatTone.success,
                icon: Icons.savings_outlined),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: AppData.suppliers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = AppData.suppliers[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.wholesaleTint
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.public,
                                color: AppTheme.wholesaleTint, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _BulkChip(
                                        icon: Icons.flag_outlined,
                                        label: s.country),
                                    _BulkChip(
                                        icon: Icons.category_outlined,
                                        label: s.category),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (s.hasPayable)
                            StatPill(
                                label: 'مستحق عليك',
                                value: Money.formatWithCurrency(s.payable),
                                tone: StatTone.danger,
                                icon: Icons.priority_high),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _BulkChip(
                              icon: Icons.email_outlined,
                              label: s.contact,
                              direction: TextDirection.ltr),
                          _BulkChip(
                              icon: Icons.event_outlined,
                              label:
                                  'آخر طلب: ${s.lastOrderDate.day}/${s.lastOrderDate.month}/${s.lastOrderDate.year}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                                label: 'إجمالي الطلبات',
                                value: Money.formatWithCurrency(s.totalOrders)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                                label: 'المستحقات',
                                value: Money.formatWithCurrency(s.payable),
                                color: s.hasPayable
                                    ? AppTheme.danger
                                    : AppTheme.success),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStat(
                                label: 'الحالة',
                                value: s.hasPayable
                                    ? 'معلّق'
                                    : 'خالص',
                                color: s.hasPayable
                                    ? AppTheme.warning
                                    : AppTheme.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.history_outlined,
                                  size: 16),
                              label: const Text('سجل الطلبات')),
                          const Spacer(),
                          if (s.hasPayable)
                            ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {},
                                icon: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 16),
                                label: const Text('تسوية مستحق')),
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
// SECTION 5 — Analytics & Reports
// ===========================================================================
class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection();

  @override
  Widget build(BuildContext context) {
    final receivable =
        AppData.customers.fold(0.0, (s, c) => s + c.outstandingDebt);
    final payable =
        AppData.suppliers.fold(0.0, (s, p) => s + p.payable);
    const netProfit = 184200.0;
    const cashFlow = 92500.0;
    final isWide = context.isDesktop || context.isTablet;
    return ListView(
      children: [
        const SectionTitle(
          title: 'التحليلات والتقارير',
          subtitle: 'نظرة تنفيذية على الأرباح والمستحقات والتدفّق النقدي',
          icon: Icons.analytics_outlined,
        ),
        const SizedBox(height: 16),
        if (isWide)
          Row(
            children: [
              Expanded(child: _KpiCard(
                title: 'صافي الأرباح',
                value: Money.formatWithCurrency(netProfit),
                tone: StatTone.success,
                icon: Icons.trending_up,
                delta: '+12.4%',
              )),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(
                title: 'الديون لك',
                value: Money.formatWithCurrency(receivable),
                tone: StatTone.warning,
                icon: Icons.account_balance_wallet_outlined,
                delta: '-3.1%',
              )),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(
                title: 'المستحقات عليك',
                value: Money.formatWithCurrency(payable),
                tone: StatTone.danger,
                icon: Icons.account_balance_outlined,
                delta: '+5.8%',
              )),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(
                title: 'التدفّق النقدي',
                value: Money.formatWithCurrency(cashFlow),
                tone: StatTone.info,
                icon: Icons.savings_outlined,
                delta: '+8.2%',
              )),
            ],
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _KpiCard(
                title: 'صافي الأرباح',
                value: Money.formatWithCurrency(netProfit),
                tone: StatTone.success,
                icon: Icons.trending_up,
                delta: '+12.4%',
              ),
              _KpiCard(
                title: 'الديون لك',
                value: Money.formatWithCurrency(receivable),
                tone: StatTone.warning,
                icon: Icons.account_balance_wallet_outlined,
                delta: '-3.1%',
              ),
              _KpiCard(
                title: 'المستحقات عليك',
                value: Money.formatWithCurrency(payable),
                tone: StatTone.danger,
                icon: Icons.account_balance_outlined,
                delta: '+5.8%',
              ),
              _KpiCard(
                title: 'التدفّق النقدي',
                value: Money.formatWithCurrency(cashFlow),
                tone: StatTone.info,
                icon: Icons.savings_outlined,
                delta: '+8.2%',
              ),
            ],
          ),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'أداء المبيعات الشهري',
          subtitle: 'إجمالي المبيعات لآخر 6 أشهر',
          icon: Icons.bar_chart_outlined,
        ),
        const SizedBox(height: 16),
        _MonthlyBarChart(),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'أعلى الموردين مستحقاً',
          subtitle: 'تذكير بالمستحقات العالقة للموردين',
          icon: Icons.priority_high_outlined,
        ),
        const SizedBox(height: 8),
        ...AppData.suppliers
            .where((s) => s.hasPayable)
            .toList()
            .asMap()
            .entries
            .map((e) => _PayableRank(
                  rank: e.key + 1,
                  name: e.value.name,
                  country: e.value.country,
                  payable: e.value.payable,
                )),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.tone,
    required this.icon,
    required this.delta,
  });

  final String title;
  final String value;
  final StatTone tone;
  final IconData icon;
  final String delta;

  Color _bg() => switch (tone) {
        StatTone.success => AppTheme.success,
        StatTone.warning => AppTheme.warning,
        StatTone.danger => AppTheme.danger,
        StatTone.info => AppTheme.info,
        StatTone.neutral => AppTheme.textPrimary,
      };

  @override
  Widget build(BuildContext context) {
    final isUp = delta.startsWith('+');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _bg().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _bg(), size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isUp ? AppTheme.success : AppTheme.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isUp ? AppTheme.success : AppTheme.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        delta,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              isUp ? AppTheme.success : AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            const Text('مقارنة بالشهر الماضي',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  static const _months = ['مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس'];
  static const _values = [120000, 142000, 138000, 165000, 158000, 184200];
  static const _max = 200000.0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('المبيعات (أوقية)',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('آخر 6 أشهر',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LayoutBuilder(
                builder: (context, c) {
                  final barWidth =
                      (c.maxWidth - 60) / _values.length - 12;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          ...['200k', '150k', '100k', '50k', '0']
                              .map((v) => Text(v,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary)))
                              .toList(),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: _values
                              .asMap()
                              .entries
                              .map((e) {
                            final h = (e.value / _max) *
                                (c.maxHeight - 30);
                            return Flexible(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  Text(
                                    Money.formatWithCurrency(
                                            e.value.toDouble())
                                        .split(' ')[0],
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color:
                                            AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: isWide ? null : barWidth,
                                    constraints:
                                        const BoxConstraints(
                                            maxWidth: 36,
                                            minWidth: 12),
                                    height: h,
                                    decoration:
                                        BoxDecoration(
                                      gradient:
                                          const LinearGradient(
                                        begin: Alignment
                                            .bottomCenter,
                                        end: Alignment
                                            .topCenter,
                                        colors: [
                                          AppTheme.primary,
                                          AppTheme.accent,
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                              6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(_months[e.key],
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w700)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayableRank extends StatelessWidget {
  const _PayableRank({
    required this.rank,
    required this.name,
    required this.country,
    required this.payable,
  });

  final int rank;
  final String name;
  final String country;
  final double payable;

  Color get _rankColor =>
      rank == 1 ? AppTheme.danger : rank == 2 ? AppTheme.warning : AppTheme.info;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _rankColor.withValues(alpha: 0.12),
          child: Text('$rank',
              style: TextStyle(
                  color: _rankColor, fontWeight: FontWeight.w900)),
        ),
        title: Text(name,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800)),
        subtitle: Text(country,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(Money.formatWithCurrency(payable),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.danger)),
            const Text('مستحق',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
