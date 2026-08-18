import 'package:flutter/material.dart';

import 'product.dart';

/// Customer type for the retail POS checkout flow.
enum CustomerType { walkIn, registered, newCustomer }

/// B2B / B2C customer record shared by retail and wholesale dashboards.
@immutable
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.outstandingDebt,
    required this.totalPurchases,
    required this.totalProfit,
    this.email,
    this.type = CustomerType.registered,
    this.lastInvoiceDate,
  });

  final String id;
  final String name;
  final String phone;
  final String city;
  final double outstandingDebt;
  final double totalPurchases;
  final double totalProfit;
  final String? email;
  final CustomerType type;
  final DateTime? lastInvoiceDate;

  bool get hasDebt => outstandingDebt > 0;

  String get debtLabel => Product.formatMRU(outstandingDebt);
  String get profitLabel => Product.formatMRU(totalProfit);
  String get purchasesLabel => Product.formatMRU(totalPurchases);
}

/// A supplier in the import / wholesale flow.
@immutable
class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.country,
    required this.contact,
    required this.payable,
    required this.totalOrders,
    required this.lastOrderDate,
    this.category = 'استيراد',
  });

  final String id;
  final String name;
  final String country;
  final String contact;
  final double payable; // مستحقات عليك
  final double totalOrders;
  final DateTime lastOrderDate;
  final String category;

  bool get hasPayable => payable > 0;
}

/// Simplified invoice used in customer ledger views.
@immutable
class Invoice {
  const Invoice({
    required this.id,
    required this.customerId,
    required this.date,
    required this.total,
    required this.paid,
    required this.items,
  });

  final String id;
  final String customerId;
  final DateTime date;
  final double total;
  final double paid;
  final List<CartLine> items;

  double get balance => total - paid;
  bool get isSettled => balance <= 0;
}
