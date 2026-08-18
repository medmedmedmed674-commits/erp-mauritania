import 'package:flutter/material.dart';

/// Enumerated product categories shared by retail + wholesale.
enum ProductCategory {
  groceries('مواد غذائية'),
  beverages('مشروبات'),
  dairy('ألبان ومشتقات'),
  bakery('مخبوزات'),
  hygiene('نظافة ومنظفات'),
  produce('خضر وفواكه'),
  household('مستلزمات منزلية'),
  electronics('إلكترونيات'),
  other('أخرى');

  const ProductCategory(this.arabicLabel);
  final String arabicLabel;
}

/// Single product line in either the retail catalogue or the wholesale
/// stock ledger. `unitPrice` is the retail price, `cartonPrice` is the
/// wholesale price (per carton of [cartonSize] units).
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.stock,
    this.cartonPrice = 0,
    this.cartonSize = 12,
    this.batchNumber,
    this.lowStockThreshold = 10,
    this.icon = Icons.inventory_2_outlined,
    this.color = const Color(0xFF1E6FBA),
  });

  final String id;
  final String name;
  final ProductCategory category;
  final double unitPrice;
  final int stock;
  final double cartonPrice;
  final int cartonSize;
  final String? batchNumber;
  final int lowStockThreshold;
  final IconData icon;
  final Color color;

  bool get isLowStock => stock <= lowStockThreshold;

  /// Format a Mauritanian MRU price, e.g. "1 250 أوقية".
  static String formatMRU(double value) {
    final asInt = value.round();
    final formatted = asInt.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]} ',
    );
    return '$formatted أوقية';
  }
}

/// A line item inside a cart (POS) or a sale invoice.
@immutable
class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get lineTotal => product.unitPrice * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}
