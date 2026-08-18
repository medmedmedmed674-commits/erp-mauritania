import 'package:flutter/material.dart';

import '../utils/money.dart';
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

  String get debtLabel => Money.formatWithCurrency(outstandingDebt);
  String get profitLabel => Money.formatWithCurrency(totalProfit);
  String get purchasesLabel => Money.formatWithCurrency(totalPurchases);

  /// Returns a new Customer with the given payment subtracted from
  /// the outstanding debt. Used by the debt-collection flow.
  Customer applyPayment(double amount) => Customer(
        id: id,
        name: name,
        phone: phone,
        city: city,
        outstandingDebt: (outstandingDebt - amount).clamp(0, double.infinity),
        totalPurchases: totalPurchases,
        totalProfit: totalProfit,
        email: email,
        type: type,
        lastInvoiceDate: lastInvoiceDate,
      );
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

/// Payment type used on POS invoices and customer debt settlement.
enum PaymentType {
  cash('نقدي'),
  card('بطاقة بنكية'),
  credit('آجل (دين)'),
  mobileMoney('محفظة إلكترونية');

  const PaymentType(this.arabicLabel);
  final String arabicLabel;
}

/// Simplified invoice used in customer ledger views + printable receipts.
@immutable
class Invoice {
  const Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.total,
    required this.paid,
    required this.items,
    required this.paymentType,
    required this.storeName,
    this.customerPhone,
  });

  final String id;
  final String customerId;
  final String customerName;
  final DateTime date;
  final double total;
  final double paid;
  final List<CartLine> items;
  final PaymentType paymentType;
  final String storeName;
  final String? customerPhone;

  double get balance => total - paid;
  bool get isSettled => balance <= 0;

  /// Subtotal of all line items before any rounding.
  double get subtotal =>
      items.fold(0.0, (s, l) => s + l.lineTotal);
}
