import 'package:flutter/foundation.dart';

import '../models/app_data.dart';
import '../models/customer.dart';
import '../models/product.dart';

/// Operational expense category used in the new Tab 5.
enum ExpenseCategory {
  rent('إيجار'),
  maintenance('صيانات'),
  electricity('فاتورة كهرباء'),
  water('فاتورة ماء'),
  salary('رواتب'),
  other('أخرى');

  const ExpenseCategory(this.arabicLabel);
  final String arabicLabel;
}

/// A single recorded operational expense.
@immutable
class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String note;
}

/// Mutable central state for the retail dashboard. Holds the live
/// catalogue, customer ledger, invoices, expenses, and exposes simple
/// mutation methods that notify listeners.
///
/// In a production deployment this would be backed by an API client
/// + local cache; the surface stays the same.
class RetailStore extends ChangeNotifier {
  RetailStore() {
    _products = List.of(AppData.retailProducts);
    _customers = List.of(AppData.customers);
    _invoices = List.of(AppData.invoices);
    _expenses = [
      Expense(
        id: 'E-001',
        category: ExpenseCategory.rent,
        amount: 25000,
        date: DateTime(2026, 8, 1),
        note: 'إيجار المحل لشهر أغسطس',
      ),
      Expense(
        id: 'E-002',
        category: ExpenseCategory.electricity,
        amount: 4200,
        date: DateTime(2026, 8, 5),
        note: 'فاتورة الكهرباء',
      ),
      Expense(
        id: 'E-003',
        category: ExpenseCategory.salary,
        amount: 30000,
        date: DateTime(2026, 8, 10),
        note: 'راتب الموظف الشهري',
      ),
    ];
  }

  late List<Product> _products;
  late List<Customer> _customers;
  late List<Invoice> _invoices;
  late List<Expense> _expenses;

  List<Product> get products => List.unmodifiable(_products);
  List<Customer> get customers => List.unmodifiable(_customers);
  List<Invoice> get invoices => List.unmodifiable(_invoices);
  List<Expense> get expenses => List.unmodifiable(_expenses);

  // ----- Aggregates -----
  double get totalDebt =>
      _customers.fold(0.0, (s, c) => s + c.outstandingDebt);
  double get totalProfit =>
      _customers.fold(0.0, (s, c) => s + c.totalProfit);
  double get totalExpenses =>
      _expenses.fold(0.0, (s, e) => s + e.amount);
  double get stockValue =>
      _products.fold(0.0, (s, p) => s + p.unitPrice * p.stock);
  int get lowStockCount =>
      _products.where((p) => p.isLowStock).length;

  // ----- Mutations: products -----
  void addProduct(Product p) {
    _products.insert(0, p);
    notifyListeners();
  }

  /// Removes a product from the catalogue by id.
  /// Returns true if a product was removed.
  bool deleteProduct(String id) {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) return false;
    _products.removeAt(i);
    notifyListeners();
    return true;
  }

  /// Updates a product in place by id. Used by the edit-product flow
  /// when we add it in a future iteration.
  void updateProduct(Product updated) {
    final i = _products.indexWhere((p) => p.id == updated.id);
    if (i != -1) {
      _products[i] = updated;
      notifyListeners();
    }
  }

  // ----- Mutations: customers -----
  Customer? findCustomer(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Adds a new customer to the ledger.
  void addCustomer(Customer c) {
    _customers.insert(0, c);
    notifyListeners();
  }

  /// Removes a customer by id. Returns true if a customer was removed.
  bool deleteCustomer(String id) {
    final i = _customers.indexWhere((c) => c.id == id);
    if (i == -1) return false;
    _customers.removeAt(i);
    notifyListeners();
    return true;
  }

  /// Records a debt-collection payment against a customer.
  /// Returns the updated customer, or null if the customer was not found.
  Customer? recordPayment(String customerId, double amount) {
    final i = _customers.indexWhere((c) => c.id == customerId);
    if (i == -1) return null;
    final updated = _customers[i].applyPayment(amount);
    _customers[i] = updated;
    notifyListeners();
    return updated;
  }

  /// Returns all invoices for a given customer (most recent first).
  List<Invoice> invoicesFor(String customerId) => _invoices
      .where((i) => i.customerId == customerId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // ----- Mutations: invoices -----
  void addInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    notifyListeners();
  }

  // ----- Mutations: expenses -----
  void addExpense(Expense e) {
    _expenses.insert(0, e);
    notifyListeners();
  }

  /// Removes an expense from the ledger by id.
  /// Returns true if an expense was removed.
  bool deleteExpense(String id) {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i == -1) return false;
    _expenses.removeAt(i);
    notifyListeners();
    return true;
  }

  /// Total expenses for the current month, used in the summary header.
  double get monthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  /// Breakdown of expenses by category.
  Map<ExpenseCategory, double> get expenseBreakdown {
    final map = <ExpenseCategory, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // ----- Analytics: date-filtered metrics -----
  /// Returns all invoices whose [date] is on the same calendar day as
  /// the given [day]. Used by the Analytics tab date picker.
  List<Invoice> invoicesForDay(DateTime day) => _invoices
      .where((inv) =>
          inv.date.year == day.year &&
          inv.date.month == day.month &&
          inv.date.day == day.day)
      .toList();

  /// Total sales for a specific day (sum of all invoice totals).
  double salesForDay(DateTime day) =>
      invoicesForDay(day).fold(0.0, (s, i) => s + i.total);

  /// Net profit for a specific day. Computed as the sum of per-line
  /// profit margins (retail price minus wholesale cost) for each
  /// invoice on that day.
  double profitForDay(DateTime day) {
    return invoicesForDay(day).fold<double>(
      0.0,
      (sum, inv) => sum + inv.items.fold<double>(0.0, (s, l) => s + l.quantity * l.product.unitMargin),
    );
  }

  /// Returns all invoices in a given month (used for the monthly bar
  /// chart in the wholesale analytics).
  List<Invoice> invoicesForMonth(DateTime month) => _invoices
      .where((inv) =>
          inv.date.year == month.year && inv.date.month == month.month)
      .toList();
}
