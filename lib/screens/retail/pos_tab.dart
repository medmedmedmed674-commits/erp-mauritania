import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/responsive.dart';
import '../../widgets/shared_widgets.dart';
import 'invoice_dialog.dart';

/// Tab 1 — POS terminal.
/// Interactive product catalog + cart + checkout flow that emits a
/// printable digital invoice on completion.
class PosTab extends StatefulWidget {
  const PosTab({super.key});

  @override
  State<PosTab> createState() => _PosTabState();
}

class _PosTabState extends State<PosTab> {
  final List<CartLine> _cart = [];
  CustomerType _checkoutType = CustomerType.walkIn;
  Customer? _selectedCustomer;
  PaymentType _paymentType = PaymentType.cash;

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

  double get _cartTotal => _cart.fold(0.0, (s, l) => s + l.lineTotal);

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    final customerName = switch (_checkoutType) {
      CustomerType.walkIn => 'عميل عادي',
      CustomerType.registered => _selectedCustomer?.name ?? 'عميل عادي',
      CustomerType.newCustomer => 'زبون جديد',
    };
    final phone = _selectedCustomer?.phone;
    await showInvoiceDialog(
      context,
      customerName: customerName,
      customerPhone: phone,
      customerType: _checkoutType,
      paymentType: _paymentType,
      items: _cart,
      paid: _paymentType == PaymentType.credit ? 0 : _cartTotal,
    );
    setState(_cart.clear);
  }

  @override
  Widget build(BuildContext context) {
    final isSplit = context.isSplit;
    if (isSplit) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: _ProductGrid(onAdd: _add, onDec: _dec, cart: _cart),
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
              checkoutType: _checkoutType,
              paymentType: _paymentType,
              selectedCustomer: _selectedCustomer,
              onCheckoutTypeChanged: (t) =>
                  setState(() => _checkoutType = t),
              onPaymentTypeChanged: (p) =>
                  setState(() => _paymentType = p),
              onCustomerChanged: (c) =>
                  setState(() => _selectedCustomer = c),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: _ProductGrid(onAdd: _add, onDec: _dec, cart: _cart),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: _CartPanel(
            cart: _cart,
            total: _cartTotal,
            onAdd: _add,
            onDec: _dec,
            onRemove: _removeLine,
            onCheckout: _checkout,
            checkoutType: _checkoutType,
            paymentType: _paymentType,
            selectedCustomer: _selectedCustomer,
            onCheckoutTypeChanged: (t) =>
                setState(() => _checkoutType = t),
            onPaymentTypeChanged: (p) =>
                setState(() => _paymentType = p),
            onCustomerChanged: (c) =>
                setState(() => _selectedCustomer = c),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Product grid (reads from RetailStore so newly added products appear)
// ---------------------------------------------------------------------------
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
    final products = context.watch<RetailStore>().products;
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
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
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

class _ProductTile extends StatefulWidget {
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
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 120),
    vsync: this,
    lowerBound: 0.0,
    upperBound: 1.0,
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tap() {
    _controller.forward(from: 0.0);
    widget.onAdd();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _tap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              widget.product.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: widget.product.imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    widget.product.imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Icon(
                                      widget.product.icon,
                                      size: 36,
                                      color: widget.product.color,
                                    ),
                                  ),
                                )
                              : widget.product.imageAsset != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        widget.product.imageAsset!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          widget.product.icon,
                                          size: 36,
                                          color: widget.product.color,
                                        ),
                                      ),
                                    )
                                  : Icon(widget.product.icon,
                                      size: 36, color: widget.product.color),
                        ),
                      ),
                      if (widget.product.isLowStock)
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
                              style: TextStyle(
                                  fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                LtrText(
                  'الكمية: ${widget.product.stock}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LtrText(
                        Money.formatWithCurrency(widget.product.unitPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (widget.inCart > 0) ...[
                      InkWell(
                        onTap: widget.onDec,
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.surfaceAlt,
                          child: Icon(Icons.remove, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: LtrText('${widget.inCart}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                    InkWell(
                      onTap: widget.onAdd,
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primary,
                        child:
                            Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart panel with checkout controls
// ---------------------------------------------------------------------------
class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.total,
    required this.onAdd,
    required this.onDec,
    required this.onRemove,
    required this.onCheckout,
    required this.checkoutType,
    required this.paymentType,
    required this.selectedCustomer,
    required this.onCheckoutTypeChanged,
    required this.onPaymentTypeChanged,
    required this.onCustomerChanged,
  });

  final List<CartLine> cart;
  final double total;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onDec;
  final ValueChanged<int> onRemove;
  final VoidCallback onCheckout;
  final CustomerType checkoutType;
  final PaymentType paymentType;
  final Customer? selectedCustomer;
  final ValueChanged<CustomerType> onCheckoutTypeChanged;
  final ValueChanged<PaymentType> onPaymentTypeChanged;
  final ValueChanged<Customer?> onCustomerChanged;

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<RetailStore>().customers;
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
                const Text('السلة الحالية',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LtrText(
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
                    return Dismissible(
                      key: ValueKey(line.product.id),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (_) => onRemove(i),
                      background: Container(
                        color: AppTheme.danger,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete,
                            color: Colors.white, size: 20),
                      ),
                      child: Padding(
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
                                  LtrText(
                                    '${Money.format(line.product.unitPrice)} × ${line.quantity}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            LtrText(
                              Money.formatWithCurrency(line.lineTotal),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Divider(height: 24),
            // ----- Checkout type selector -----
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ChoiceChip(
                    label: 'عميل عادي',
                    selected: checkoutType == CustomerType.walkIn,
                    onTap: () => onCheckoutTypeChanged(CustomerType.walkIn)),
                _ChoiceChip(
                    label: 'زبون دائم مسجل',
                    selected: checkoutType == CustomerType.registered,
                    onTap: () =>
                        onCheckoutTypeChanged(CustomerType.registered)),
                _ChoiceChip(
                    label: 'إضافة زبون جديد',
                    selected: checkoutType == CustomerType.newCustomer,
                    onTap: () =>
                        onCheckoutTypeChanged(CustomerType.newCustomer)),
              ],
            ),
            if (checkoutType == CustomerType.registered) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<Customer>(
                value: selectedCustomer,
                decoration: const InputDecoration(
                    labelText: 'اختر زبوناً مسجلاً',
                    isDense: true,
                    prefixIcon: Icon(Icons.person_outline, size: 18)),
                items: customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.name} — ${c.phone}'),
                        ))
                    .toList(),
                onChanged: onCustomerChanged,
              ),
            ],
            const SizedBox(height: 8),
            // ----- Payment type selector -----
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PaymentType.values
                  .map((p) => _ChoiceChip(
                        label: p.arabicLabel,
                        selected: paymentType == p,
                        onTap: () => onPaymentTypeChanged(p),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('الإجمالي',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const Spacer(),
                LtrText(
                  Money.formatWithCurrency(total),
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
              label: 'إتمام الدفع وإصدار الفاتورة',
              icon: Icons.receipt_long_outlined,
              onPressed: cart.isEmpty ? () {} : onCheckout,
            ),
          ],
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
      color: selected ? AppTheme.primary : AppTheme.surfaceAlt,
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
