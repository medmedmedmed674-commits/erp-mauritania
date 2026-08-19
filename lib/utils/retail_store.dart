import 'package:flutter/foundation.dart';

import '../models/app_data.dart';
import '../models/customer.dart';
import '../models/product.dart';
import 'database_service.dart';

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
/// ## Database integration
/// On native builds (Android, iOS, Windows, macOS, Linux) the store
/// lazily connects to the Neon PostgreSQL database via
/// [DatabaseService] on construction. All mutations are persisted
/// to the DB before the local cache is updated — so the UI always
/// reflects the true DB state.
///
/// On Flutter Web the `postgres` package doesn't work (browsers can't
/// open TCP sockets), so the store falls back to the in-memory seed
/// data from [AppData]. Mutations are kept in memory for the session.
///
/// Every mutation method is async + try-catch wrapped. On DB failure
/// the mutation still applies to the local cache (so the UI keeps
/// working) but the error is surfaced via [lastError] for the UI to
/// show a snackbar.
class RetailStore extends ChangeNotifier {
  RetailStore() {
    if (DatabaseService.instance.isAvailable) {
      // ── DB mode (native builds with NEON_CONNECTION_STRING) ──
      // Start with EMPTY lists so new/clean accounts load with a fully
      // zeroed-out state (zero debt, empty invoices, empty products).
      // The real data is loaded asynchronously from Neon in
      // _loadFromDatabase().
      _products = <Product>[];
      _customers = <Customer>[];
      _invoices = <Invoice>[];
      _expenses = <Expense>[];
    } else {
      // ── Fallback mode (Flutter Web, or no connection string) ──
      // Use the in-memory seed data so the app stays demoable on the
      // Vercel web deployment. A small yellow banner makes this mode
      // visible to the user.
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

    // Attempt to load from Neon in the background. On web this is a
    // no-op (DatabaseService.isAvailable returns false). On native
    // builds it opens the SSL connection and populates the lists
    // with the real DB rows.
    _loadFromDatabase();
  }

  /// The most recent DB error (or null). The UI surfaces this via a
  /// snackbar / banner so the user knows when persistence failed.
  String? _lastError;
  String? get lastError => _lastError;
  void clearLastError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  /// True if the Neon database connection is available in this build.
  /// Returns false on Web (postgres package doesn't work in browsers)
  /// or when no NEON_CONNECTION_STRING env var is set.
  bool get isDbAvailable => DatabaseService.instance.isAvailable;

  /// Background loader. On web it's a no-op; on native it opens the
  /// connection, fetches products/customers/invoices, and populates
  /// the lists with the real DB rows (even if empty — so a clean
  /// account loads with a fully zeroed-out state). Never throws —
  /// errors are surfaced via [lastError].
  Future<void> _loadFromDatabase() async {
    if (!DatabaseService.instance.isAvailable) {
      // Web build, or no connection string — keep using the seed data.
      return;
    }
    try {
      final ok = await DatabaseService.instance.ensureConnected();
      if (!ok) {
        _lastError = DatabaseService.instance.initError;
        notifyListeners();
        return;
      }
      // Fetch products — always replace, even with an empty list, so a
      // clean DB account loads with zero products (no mock fallback).
      final productsResult =
          await DatabaseService.instance.fetchProducts();
      if (productsResult.success && productsResult.data != null) {
        _products = List.of(productsResult.data!);
      } else if (!productsResult.success) {
        _lastError = productsResult.error;
      }
      // Fetch customers — always replace, even with an empty list.
      final customersResult =
          await DatabaseService.instance.fetchCustomers();
      if (customersResult.success && customersResult.data != null) {
        _customers = List.of(customersResult.data!);
      } else if (!customersResult.success) {
        _lastError = customersResult.error;
      }
      notifyListeners();
    } catch (e, stack) {
      _lastError = 'فشل تحميل البيانات: $e';
      debugPrint('[RetailStore] _loadFromDatabase failed: $e\n$stack');
      notifyListeners();
    }
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
  /// Adds a product to the local catalogue AND fires an async UPSERT
  /// into the Neon `products` table. The local mutation is
  /// synchronous so the UI updates immediately; the DB write happens
  /// in the background and any error is surfaced via [lastError].
  void addProduct(Product p) {
    _products.insert(0, p);
    notifyListeners();
    _persistProduct(p);
  }

  /// Background persistence — never throws to the caller.
  Future<void> _persistProduct(Product p) async {
    if (!DatabaseService.instance.isAvailable) return;
    try {
      final r = await DatabaseService.instance.upsertProduct(p);
      if (!r.success) {
        _lastError = r.error;
        notifyListeners();
      }
    } catch (e, stack) {
      _lastError = 'فشل حفظ المنتج: $e';
      debugPrint('[RetailStore] _persistProduct failed: $e\n$stack');
      notifyListeners();
    }
  }

  /// Set of product ids that have been removed via [deleteProduct]
  /// since the last call to [consumeRemovedProductIds]. The Purchases
  /// tab reads this on each rebuild and prunes its quantities map.
  ///
  /// This implements a "cascading delete" pattern without coupling
  /// the store to the tab's internal state — the tab just observes
  /// what was removed and reconciles.
  final Set<String> _removedProductIds = <String>{};

  /// Returns the set of product ids that have been removed since the
  /// last call, then clears the internal buffer. Used by the Purchases
  /// tab to prune its local quantities map.
  Set<String> consumeRemovedProductIds() {
    final copy = Set<String>.of(_removedProductIds);
    _removedProductIds.clear();
    return copy;
  }

  /// Removes a product from the catalogue by id. Also records the id
  /// in the "removed" set so downstream consumers (e.g. the Purchases
  /// tab's quantities map) can prune themselves on the next rebuild.
  ///
  /// This is the "cascading delete" hook — any widget that holds
  /// references to product ids should watch [consumeRemovedProductIds]
  /// and clean up. The DB row is also DELETEd in the background.
  bool deleteProduct(String id) {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) return false;
    _products.removeAt(i);
    _removedProductIds.add(id);
    notifyListeners();
    _deleteProductFromDb(id);
    return true;
  }

  Future<void> _deleteProductFromDb(String id) async {
    if (!DatabaseService.instance.isAvailable) return;
    try {
      final r = await DatabaseService.instance.deleteProduct(id);
      if (!r.success) {
        _lastError = r.error;
        notifyListeners();
      }
    } catch (e, stack) {
      _lastError = 'فشل حذف المنتج: $e';
      debugPrint('[RetailStore] _deleteProductFromDb failed: $e\n$stack');
      notifyListeners();
    }
  }

  /// Updates a product in place by id. Used by the edit-product flow.
  /// Also fires an UPSERT into the Neon `products` table.
  void updateProduct(Product updated) {
    final i = _products.indexWhere((p) => p.id == updated.id);
    if (i != -1) {
      _products[i] = updated;
      notifyListeners();
      _persistProduct(updated);
    }
  }

  // ----- Mutations: customers -----
  Customer? findCustomer(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Adds a new customer to the local ledger AND fires an async UPSERT
  /// into the Neon `customers` table.
  void addCustomer(Customer c) {
    _customers.insert(0, c);
    notifyListeners();
    _persistCustomer(c);
  }

  Future<void> _persistCustomer(Customer c) async {
    if (!DatabaseService.instance.isAvailable) return;
    try {
      final r = await DatabaseService.instance.upsertCustomer(c);
      if (!r.success) {
        _lastError = r.error;
        notifyListeners();
      }
    } catch (e, stack) {
      _lastError = 'فشل حفظ الزبون: $e';
      debugPrint('[RetailStore] _persistCustomer failed: $e\n$stack');
      notifyListeners();
    }
  }

  /// Removes a customer by id. Returns true if a customer was removed.
  /// Also DELETEs the row in Neon (cascades to invoices via FK).
  bool deleteCustomer(String id) {
    final i = _customers.indexWhere((c) => c.id == id);
    if (i == -1) return false;
    _customers.removeAt(i);
    notifyListeners();
    _deleteCustomerFromDb(id);
    return true;
  }

  Future<void> _deleteCustomerFromDb(String id) async {
    if (!DatabaseService.instance.isAvailable) return;
    try {
      final r = await DatabaseService.instance.deleteCustomer(id);
      if (!r.success) {
        _lastError = r.error;
        notifyListeners();
      }
    } catch (e, stack) {
      _lastError = 'فشل حذف الزبون: $e';
      debugPrint('[RetailStore] _deleteCustomerFromDb failed: $e\n$stack');
      notifyListeners();
    }
  }

  /// Records a debt-collection payment against a customer.
  /// Returns the updated customer, or null if the customer was not found.
  ///
  /// The new debt is computed locally (old debt - amount, clamped to 0)
  /// and then persisted to Neon via UPDATE customers SET outstanding_debt.
  /// If `amount == outstandingDebt`, the new debt becomes 0 (full settlement).
  /// If `amount < outstandingDebt`, new debt = old debt - amount.
  Customer? recordPayment(String customerId, double amount) {
    final i = _customers.indexWhere((c) => c.id == customerId);
    if (i == -1) return null;
    final updated = _customers[i].applyPayment(amount);
    _customers[i] = updated;
    notifyListeners();
    _persistDebtUpdate(customerId, updated.outstandingDebt);
    return updated;
  }

  Future<void> _persistDebtUpdate(
      String customerId, double newDebt) async {
    if (!DatabaseService.instance.isAvailable) return;
    try {
      final r =
          await DatabaseService.instance.updateCustomerDebt(customerId, newDebt);
      if (!r.success) {
        _lastError = r.error;
        notifyListeners();
      }
    } catch (e, stack) {
      _lastError = 'فشل تحديث الدين: $e';
      debugPrint('[RetailStore] _persistDebtUpdate failed: $e\n$stack');
      notifyListeners();
    }
  }

  /// Returns all invoices for a given customer (most recent first).
  List<Invoice> invoicesFor(String customerId) => _invoices
      .where((i) => i.customerId == customerId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  // ----- Mutations: invoices -----
  /// Adds an invoice to the local ledger AND fires an async INSERT
  /// into the Neon `invoices` table.
  void addInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    notifyListeners();
    _persistInvoice(invoice);
  }

  Future<void> _persistInvoice(Invoice invoice) async {
    if (!DatabaseService.instance.isAvailable) return;
    try {
      final r = await DatabaseService.instance.insertInvoice(invoice);
      if (!r.success) {
        _lastError = r.error;
        notifyListeners();
      }
    } catch (e, stack) {
      _lastError = 'فشل حفظ الفاتورة: $e';
      debugPrint('[RetailStore] _persistInvoice failed: $e\n$stack');
      notifyListeners();
    }
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

  // ----- Async DB-backed analytics -----
  //
  // These methods delegate to DatabaseService.fetchDayAnalytics which
  // executes real SQL aggregates:
  //   SELECT COUNT(*), COALESCE(SUM(total), 0), COALESCE(SUM(paid), 0)
  //   FROM invoices WHERE invoice_date >= @start AND invoice_date < @end
  //
  // On web (no DB), they return a failure so the caller can fall back
  // to the in-memory computation.

  /// Fetches real SQL-aggregated analytics for a single day from Neon.
  /// Returns null on failure (caller falls back to in-memory computation).
  Future<DayAnalytics?> fetchDayAnalyticsFromDb(DateTime day) async {
    if (!DatabaseService.instance.isAvailable) return null;
    try {
      final r = await DatabaseService.instance.fetchDayAnalytics(day);
      if (r.success && r.data != null) return r.data;
      _lastError = r.error;
      notifyListeners();
      return null;
    } catch (e) {
      _lastError = 'فشل تحميل التحليلات: $e';
      notifyListeners();
      return null;
    }
  }

  /// Fetches the total outstanding debt across all customers from Neon.
  /// Returns null on failure.
  Future<double?> fetchTotalDebtFromDb() async {
    if (!DatabaseService.instance.isAvailable) return null;
    try {
      final r = await DatabaseService.instance.fetchTotalOutstandingDebt();
      if (r.success && r.data != null) return r.data;
      _lastError = r.error;
      notifyListeners();
      return null;
    } catch (e) {
      _lastError = 'فشل تحميل الديون: $e';
      notifyListeners();
      return null;
    }
  }
}
