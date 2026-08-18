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
/// stock ledger. `unitPrice` is the retail price, `wholesaleCost` is the
/// purchase cost from the supplier, `cartonPrice` is the wholesale
/// per-carton price.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.stock,
    this.wholesaleCost = 0,
    this.cartonPrice = 0,
    this.cartonSize = 12,
    this.batchNumber,
    this.lowStockThreshold = 10,
    this.icon = Icons.inventory_2_outlined,
    this.color = const Color(0xFF1E6FBA),
    this.imageAsset,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final double unitPrice;
  final double wholesaleCost;
  final int stock;
  final double cartonPrice;
  final int cartonSize;
  final String? batchNumber;
  final int lowStockThreshold;
  final IconData icon;
  final Color color;
  final String? imageAsset;

  bool get isLowStock => stock <= lowStockThreshold;

  /// Per-unit profit margin (retail price minus wholesale cost).
  double get unitMargin => unitPrice - wholesaleCost;

  /// Total inventory valuation at retail price.
  double get stockValue => unitPrice * stock;

  /// Create a copy with overridden fields (used by the Add-Product modal
  /// when editing an existing line).
  Product copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    double? unitPrice,
    double? wholesaleCost,
    int? stock,
    int? lowStockThreshold,
    IconData? icon,
    Color? color,
    String? imageAsset,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        unitPrice: unitPrice ?? this.unitPrice,
        wholesaleCost: wholesaleCost ?? this.wholesaleCost,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        imageAsset: imageAsset ?? this.imageAsset,
      );
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
