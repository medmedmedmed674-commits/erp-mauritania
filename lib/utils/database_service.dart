import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';

import '../models/customer.dart';
import '../models/product.dart';

/// Result envelope for DatabaseService operations.
///
/// Either:
///   - [success] = true and [data] holds the parsed result, OR
///   - [success] = false and [error] holds a user-facing message.
class DbResult<T> {
  const DbResult.success(this.data)
      : success = true,
        error = null;
  const DbResult.failure(this.error)
      : success = false,
        data = null;

  final bool success;
  final T? data;
  final String? error;
}

/// Singleton service that brokers all PostgreSQL traffic to the Neon
/// database.
///
/// ## Architecture
///   - The `postgres` package uses `dart:io` sockets, which **do not
///     work on Flutter Web** (browsers can't open raw TCP connections).
///     When the app is built for Web, [isAvailable] returns `false`
///     and every method returns a graceful failure so the calling
///     [RetailStore] can fall back to the in-memory store.
///   - On native builds (Android, iOS, Windows, macOS, Linux) the
///     connection is lazily opened on first use via [ensureConnected].
///   - The connection string is read from the `NEON_CONNECTION_STRING`
///     environment variable (loaded from `.env` via flutter_dotenv,
///     or from the OS environment on Vercel). It is **never** committed
///     to source control.
///   - Every public method wraps its SQL in a try-catch and returns
///     a [DbResult], so callers can show user-friendly error UI.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Connection? _connection;
  bool _initializing = false;
  bool _initialized = false;
  String? _initError;

  /// Whether the database layer is usable in the current build.
  bool get isAvailable {
    if (kIsWeb) return false;
    final conn = _readConnectionString();
    return conn != null && conn.isNotEmpty;
  }

  /// True once [ensureConnected] has succeeded at least once.
  bool get isInitialized => _initialized;

  /// The most recent init error (or null).
  String? get initError => _initError;

  /// Lazily opens the SSL connection to Neon.
  Future<bool> ensureConnected() async {
    if (kIsWeb) {
      _initError = 'قاعدة البيانات غير متاحة على متصفح الويب — '
          'الاستخدام المخزن المحلي.';
      return false;
    }
    if (_initialized && _connection != null && _connection!.isOpen) {
      return true;
    }
    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return _initialized;
    }
    _initializing = true;
    try {
      final connStr = _readConnectionString();
      if (connStr == null || connStr.isEmpty) {
        _initError = 'NEON_CONNECTION_STRING غير مضبوط.';
        return false;
      }
      final uri = Uri.parse(connStr);
      final host = uri.host;
      final port = uri.port == 0 ? 5432 : uri.port;
      final db = uri.path.startsWith('/')
          ? uri.path.substring(1)
          : uri.path;
      final userInfo = uri.userInfo.split(':');
      final user = userInfo.isEmpty ? 'neondb_owner' : userInfo[0];
      final password = userInfo.length > 1 ? userInfo[1] : '';

      final endpoint = Endpoint(
        host: host,
        port: port,
        database: db,
        username: user,
        password: password,
      );
      // Neon requires SSL — use SslMode.require (accepts Neon's cert).
      final settings = ConnectionSettings(
        sslMode: SslMode.require,
        connectTimeout: const Duration(seconds: 30),
        queryTimeout: const Duration(seconds: 30),
      );
      _connection = await Connection.open(endpoint, settings: settings);
      _initialized = true;
      _initError = null;
      debugPrint('[DatabaseService] Connected to Neon at $host:$port/$db');
      await _initSchema(_connection!);
      return true;
    } catch (e, stack) {
      _initError = 'فشل الاتصال بقاعدة البيانات: $e';
      debugPrint('[DatabaseService] Connection failed: $e\n$stack');
      return false;
    } finally {
      _initializing = false;
    }
  }

  /// Reads the Neon connection string from the environment.
  String? _readConnectionString() {
    if (kIsWeb) return null;
    try {
      final fromDotEnv = dotenv.maybeGet('NEON_CONNECTION_STRING');
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    } catch (_) {
      // dotenv not loaded — skip.
    }
    try {
      final fromEnv = Platform.environment['NEON_CONNECTION_STRING'];
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    } catch (_) {
      // Platform.environment may not be available everywhere.
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────
  // Schema initialization
  // ───────────────────────────────────────────────────────────────
  Future<void> _initSchema(Connection conn) async {
    const statements = <String>[
      '''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'other',
        unit_price REAL NOT NULL DEFAULT 0,
        wholesale_cost REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 10,
        carton_price REAL NOT NULL DEFAULT 0,
        carton_size INTEGER NOT NULL DEFAULT 12,
        batch_number TEXT,
        icon_name TEXT NOT NULL DEFAULT 'inventory_2_outlined',
        color_argb INTEGER NOT NULL DEFAULT 4282385530,
        image_asset TEXT,
        image_bytes BYTEA,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT '',
        email TEXT,
        outstanding_debt REAL NOT NULL DEFAULT 0,
        total_purchases REAL NOT NULL DEFAULT 0,
        total_profit REAL NOT NULL DEFAULT 0,
        customer_type TEXT NOT NULL DEFAULT 'registered',
        last_invoice_date TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        invoice_date TIMESTAMPTZ NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        paid REAL NOT NULL DEFAULT 0,
        payment_type TEXT NOT NULL DEFAULT 'cash',
        store_name TEXT NOT NULL DEFAULT '',
        items_json TEXT NOT NULL DEFAULT '[]',
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
      ''',
      '''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL DEFAULT 'other',
        amount REAL NOT NULL DEFAULT 0,
        expense_date TIMESTAMPTZ NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
      ''',
    ];
    for (final s in statements) {
      try {
        await conn.execute(s);
      } catch (e) {
        debugPrint('[DatabaseService] Schema statement failed: $e');
      }
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Products
  // ───────────────────────────────────────────────────────────────

  /// UPSERTs a product row.
  Future<DbResult<void>> upsertProduct(Product p) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<void>.failure(_initError ?? 'DB unavailable');
    }
    try {
      await _connection!.execute(
        Sql.named(r'''
        INSERT INTO products (
          id, name, category, unit_price, wholesale_cost, stock,
          low_stock_threshold, carton_price, carton_size, batch_number,
          icon_name, color_argb, image_asset, image_bytes
        ) VALUES (
          @id, @name, @category, @unit_price, @wholesale_cost, @stock,
          @low_stock_threshold, @carton_price, @carton_size, @batch_number,
          @icon_name, @color_argb, @image_asset, @image_bytes
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          category = EXCLUDED.category,
          unit_price = EXCLUDED.unit_price,
          wholesale_cost = EXCLUDED.wholesale_cost,
          stock = EXCLUDED.stock,
          low_stock_threshold = EXCLUDED.low_stock_threshold,
          carton_price = EXCLUDED.carton_price,
          carton_size = EXCLUDED.carton_size,
          batch_number = EXCLUDED.batch_number,
          icon_name = EXCLUDED.icon_name,
          color_argb = EXCLUDED.color_argb,
          image_asset = EXCLUDED.image_asset,
          image_bytes = EXCLUDED.image_bytes
        '''),
        parameters: <String, dynamic>{
          'id': p.id,
          'name': p.name,
          'category': p.category.name,
          'unit_price': p.unitPrice,
          'wholesale_cost': p.wholesaleCost,
          'stock': p.stock,
          'low_stock_threshold': p.lowStockThreshold,
          'carton_price': p.cartonPrice,
          'carton_size': p.cartonSize,
          'batch_number': p.batchNumber,
          'icon_name': _iconName(p.icon),
          'color_argb': _colorToArgb(p.color),
          'image_asset': p.imageAsset,
          'image_bytes': p.imageBytes,
        },
      );
      return const DbResult<void>.success(null);
    } catch (e, stack) {
      debugPrint('[DatabaseService] upsertProduct failed: $e\n$stack');
      return DbResult<void>.failure('فشل حفظ المنتج: $e');
    }
  }

  /// SELECTs all product rows.
  Future<DbResult<List<Product>>> fetchProducts() async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<List<Product>>.failure(_initError ?? 'DB unavailable');
    }
    try {
      final result = await _connection!.execute(
        Sql.named('SELECT * FROM products ORDER BY created_at DESC'),
      );
      final products =
          result.map(_rowToProduct).whereType<Product>().toList();
      return DbResult<List<Product>>.success(products);
    } catch (e, stack) {
      debugPrint('[DatabaseService] fetchProducts failed: $e\n$stack');
      return DbResult<List<Product>>.failure('فشل تحميل المنتجات: $e');
    }
  }

  /// DELETEs a product row by id.
  Future<DbResult<void>> deleteProduct(String id) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<void>.failure(_initError ?? 'DB unavailable');
    }
    try {
      await _connection!.execute(
        Sql.named('DELETE FROM products WHERE id = @id'),
        parameters: <String, dynamic>{'id': id},
      );
      return const DbResult<void>.success(null);
    } catch (e, stack) {
      debugPrint('[DatabaseService] deleteProduct failed: $e\n$stack');
      return DbResult<void>.failure('فشل حذف المنتج: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Customers
  // ───────────────────────────────────────────────────────────────

  /// UPSERTs a customer row.
  Future<DbResult<void>> upsertCustomer(Customer c) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<void>.failure(_initError ?? 'DB unavailable');
    }
    try {
      await _connection!.execute(
        Sql.named(r'''
        INSERT INTO customers (
          id, name, phone, city, email,
          outstanding_debt, total_purchases, total_profit,
          customer_type, last_invoice_date
        ) VALUES (
          @id, @name, @phone, @city, @email,
          @debt, @purchases, @profit, @type, @last
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          phone = EXCLUDED.phone,
          city = EXCLUDED.city,
          email = EXCLUDED.email,
          outstanding_debt = EXCLUDED.outstanding_debt,
          total_purchases = EXCLUDED.total_purchases,
          total_profit = EXCLUDED.total_profit,
          customer_type = EXCLUDED.customer_type,
          last_invoice_date = EXCLUDED.last_invoice_date
        '''),
        parameters: <String, dynamic>{
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'city': c.city,
          'email': c.email,
          'debt': c.outstandingDebt,
          'purchases': c.totalPurchases,
          'profit': c.totalProfit,
          'type': c.type.name,
          'last': c.lastInvoiceDate?.toUtc(),
        },
      );
      return const DbResult<void>.success(null);
    } catch (e, stack) {
      debugPrint('[DatabaseService] upsertCustomer failed: $e\n$stack');
      return DbResult<void>.failure('فشل حفظ الزبون: $e');
    }
  }

  /// SELECTs all customers.
  Future<DbResult<List<Customer>>> fetchCustomers() async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<List<Customer>>.failure(_initError ?? 'DB unavailable');
    }
    try {
      final result = await _connection!.execute(
        Sql.named('SELECT * FROM customers ORDER BY created_at DESC'),
      );
      final customers =
          result.map(_rowToCustomer).whereType<Customer>().toList();
      return DbResult<List<Customer>>.success(customers);
    } catch (e, stack) {
      debugPrint('[DatabaseService] fetchCustomers failed: $e\n$stack');
      return DbResult<List<Customer>>.failure('فشل تحميل الزبناء: $e');
    }
  }

  /// UPDATEs the customer's outstanding_debt to a new value.
  /// Used by the "Pay Debt" flow.
  /// - If amount == total debt → new debt = 0 (full settlement)
  /// - If amount < total debt  → new debt = old debt - amount
  Future<DbResult<void>> updateCustomerDebt(
      String customerId, double newDebt) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<void>.failure(_initError ?? 'DB unavailable');
    }
    try {
      await _connection!.execute(
        Sql.named(r'''
        UPDATE customers
        SET outstanding_debt = @debt
        WHERE id = @id
        '''),
        parameters: <String, dynamic>{
          'id': customerId,
          'debt': newDebt < 0 ? 0.0 : newDebt,
        },
      );
      return const DbResult<void>.success(null);
    } catch (e, stack) {
      debugPrint('[DatabaseService] updateCustomerDebt failed: $e\n$stack');
      return DbResult<void>.failure('فشل تحديث الدين: $e');
    }
  }

  /// DELETEs a customer row by id. ON DELETE CASCADE in the schema
  /// ensures their invoices are also removed.
  Future<DbResult<void>> deleteCustomer(String id) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<void>.failure(_initError ?? 'DB unavailable');
    }
    try {
      await _connection!.execute(
        Sql.named('DELETE FROM customers WHERE id = @id'),
        parameters: <String, dynamic>{'id': id},
      );
      return const DbResult<void>.success(null);
    } catch (e, stack) {
      debugPrint('[DatabaseService] deleteCustomer failed: $e\n$stack');
      return DbResult<void>.failure('فشل حذف الزبون: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Invoices
  // ───────────────────────────────────────────────────────────────

  /// INSERTs an invoice row (or no-op if id already exists).
  Future<DbResult<void>> insertInvoice(Invoice inv) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<void>.failure(_initError ?? 'DB unavailable');
    }
    try {
      final itemsJson = _serializeInvoiceItems(inv.items);
      await _connection!.execute(
        Sql.named(r'''
        INSERT INTO invoices (
          id, customer_id, customer_name, customer_phone,
          invoice_date, total, paid, payment_type, store_name, items_json
        ) VALUES (
          @id, @cid, @cname, @cphone,
          @date, @total, @paid, @ptype, @sname, @items
        )
        ON CONFLICT (id) DO NOTHING
        '''),
        parameters: <String, dynamic>{
          'id': inv.id,
          'cid': inv.customerId,
          'cname': inv.customerName,
          'cphone': inv.customerPhone,
          'date': inv.date.toUtc(),
          'total': inv.total,
          'paid': inv.paid,
          'ptype': inv.paymentType.name,
          'sname': inv.storeName,
          'items': itemsJson,
        },
      );
      return const DbResult<void>.success(null);
    } catch (e, stack) {
      debugPrint('[DatabaseService] insertInvoice failed: $e\n$stack');
      return DbResult<void>.failure('فشل حفظ الفاتورة: $e');
    }
  }

  /// SELECTs all invoices for a customer.
  Future<DbResult<List<Invoice>>> fetchInvoicesForCustomer(
      String customerId) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<List<Invoice>>.failure(_initError ?? 'DB unavailable');
    }
    try {
      final result = await _connection!.execute(
        Sql.named(r'''
        SELECT * FROM invoices
        WHERE customer_id = @cid
        ORDER BY invoice_date DESC
        '''),
        parameters: <String, dynamic>{'cid': customerId},
      );
      final invoices =
          result.map(_rowToInvoice).whereType<Invoice>().toList();
      return DbResult<List<Invoice>>.success(invoices);
    } catch (e, stack) {
      debugPrint('[DatabaseService] fetchInvoicesForCustomer failed: $e\n$stack');
      return DbResult<List<Invoice>>.failure('فشل تحميل الفواتير: $e');
    }
  }

  /// SELECTs all invoices issued on a specific calendar day.
  Future<DbResult<List<Invoice>>> fetchInvoicesForDay(DateTime day) async {
    final ok = await ensureConnected();
    if (!ok || _connection == null) {
      return DbResult<List<Invoice>>.failure(_initError ?? 'DB unavailable');
    }
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final result = await _connection!.execute(
        Sql.named(r'''
        SELECT * FROM invoices
        WHERE invoice_date >= @start AND invoice_date < @end
        ORDER BY invoice_date DESC
        '''),
        parameters: <String, dynamic>{
          'start': start.toUtc(),
          'end': end.toUtc(),
        },
      );
      final invoices =
          result.map(_rowToInvoice).whereType<Invoice>().toList();
      return DbResult<List<Invoice>>.success(invoices);
    } catch (e, stack) {
      debugPrint('[DatabaseService] fetchInvoicesForDay failed: $e\n$stack');
      return DbResult<List<Invoice>>.failure('فشل تحميل فواتير اليوم: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Row → Model converters (return null on parse failure)
  // ───────────────────────────────────────────────────────────────

  Product? _rowToProduct(ResultRow row) {
    try {
      final byName = row.toColumnMap();
      return Product(
        id: byName['id'] as String,
        name: byName['name'] as String,
        category: _parseCategory(byName['category'] as String? ?? 'other'),
        unitPrice: (byName['unit_price'] as num?)?.toDouble() ?? 0,
        wholesaleCost: (byName['wholesale_cost'] as num?)?.toDouble() ?? 0,
        stock: (byName['stock'] as num?)?.toInt() ?? 0,
        lowStockThreshold:
            (byName['low_stock_threshold'] as num?)?.toInt() ?? 10,
        cartonPrice: (byName['carton_price'] as num?)?.toDouble() ?? 0,
        cartonSize: (byName['carton_size'] as num?)?.toInt() ?? 12,
        batchNumber: byName['batch_number'] as String?,
        icon: _iconFromName(byName['icon_name'] as String? ?? ''),
        color: _argbToColor(byName['color_argb'] as int? ?? 0xFF1E6FBA),
        imageAsset: byName['image_asset'] as String?,
        imageBytes: (byName['image_bytes'] as List?)?.isNotEmpty == true
            ? Uint8List.fromList(
                (byName['image_bytes'] as List).cast<int>())
            : null,
      );
    } catch (e) {
      debugPrint('[DatabaseService] _rowToProduct failed: $e');
      return null;
    }
  }

  Customer? _rowToCustomer(ResultRow row) {
    try {
      final byName = row.toColumnMap();
      return Customer(
        id: byName['id'] as String,
        name: byName['name'] as String,
        phone: byName['phone'] as String,
        city: byName['city'] as String? ?? '',
        email: byName['email'] as String?,
        outstandingDebt:
            (byName['outstanding_debt'] as num?)?.toDouble() ?? 0,
        totalPurchases:
            (byName['total_purchases'] as num?)?.toDouble() ?? 0,
        totalProfit: (byName['total_profit'] as num?)?.toDouble() ?? 0,
        type: _parseCustomerType(byName['customer_type'] as String?),
        lastInvoiceDate: byName['last_invoice_date'] is DateTime
            ? byName['last_invoice_date'] as DateTime
            : null,
      );
    } catch (e) {
      debugPrint('[DatabaseService] _rowToCustomer failed: $e');
      return null;
    }
  }

  Invoice? _rowToInvoice(ResultRow row) {
    try {
      final byName = row.toColumnMap();
      final items = _deserializeInvoiceItems(
          byName['items_json'] as String? ?? '[]');
      return Invoice(
        id: byName['id'] as String,
        customerId: byName['customer_id'] as String,
        customerName: byName['customer_name'] as String? ?? '',
        customerPhone: byName['customer_phone'] as String?,
        date: byName['invoice_date'] is DateTime
            ? byName['invoice_date'] as DateTime
            : DateTime.now(),
        total: (byName['total'] as num?)?.toDouble() ?? 0,
        paid: (byName['paid'] as num?)?.toDouble() ?? 0,
        paymentType: _parsePaymentType(byName['payment_type'] as String?),
        storeName: byName['store_name'] as String? ?? '',
        items: items,
      );
    } catch (e) {
      debugPrint('[DatabaseService] _rowToInvoice failed: $e');
      return null;
    }
  }

  // ───────────────────────────────────────────────────────────────
  // Enum + icon helpers (best-effort, falls back to defaults)
  // ───────────────────────────────────────────────────────────────
  ProductCategory _parseCategory(String s) {
    try {
      return ProductCategory.values.firstWhere((c) => c.name == s);
    } catch (_) {
      return ProductCategory.other;
    }
  }

  CustomerType _parseCustomerType(String? s) {
    if (s == null) return CustomerType.registered;
    try {
      return CustomerType.values.firstWhere((t) => t.name == s);
    } catch (_) {
      return CustomerType.registered;
    }
  }

  PaymentType _parsePaymentType(String? s) {
    if (s == null) return PaymentType.cash;
    try {
      return PaymentType.values.firstWhere((t) => t.name == s);
    } catch (_) {
      return PaymentType.cash;
    }
  }

  String _iconName(IconData icon) {
    // Reverse-lookup the icon from the static map below. Falls back
    // to the codepoint as a string if not found.
    final entry = _iconMap.entries
        .firstWhere(
          (e) => e.value.codePoint == icon.codePoint,
          orElse: () => const MapEntry('', Icons.inventory_2_outlined),
        );
    return entry.key.isEmpty ? icon.codePoint.toString() : entry.key;
  }

  IconData _iconFromName(String s) {
    // Look up by name first (preferred round-trip path).
    final icon = _iconMap[s];
    if (icon != null) return icon;
    // Fall back to parsing a codepoint (legacy rows).
    final code = int.tryParse(s);
    if (code == null) return Icons.inventory_2_outlined;
    return _iconMap.values
        .firstWhere((i) => i.codePoint == code, orElse: () => Icons.inventory_2_outlined);
  }

  /// Static icon registry — avoids non-constant `IconData(int.parse(...))`
  /// invocations that would break Flutter Web's tree-shaking.
  static const Map<String, IconData> _iconMap = <String, IconData>{
    'inventory_2_outlined': Icons.inventory_2_outlined,
    'rice_bowl_outlined': Icons.rice_bowl_outlined,
    'local_cafe_outlined': Icons.local_cafe_outlined,
    'icecream_outlined': Icons.icecream_outlined,
    'bakery_dining_outlined': Icons.bakery_dining_outlined,
    'soap_outlined': Icons.soap_outlined,
    'eco_outlined': Icons.eco_outlined,
    'chair_outlined': Icons.chair_outlined,
    'devices_outlined': Icons.devices_outlined,
    'all_inbox_outlined': Icons.all_inbox_outlined,
  };

  int _colorToArgb(Color c) {
    // Color.value is the 32-bit ARGB int — same as the deprecated toARGB32.
    // ignore: deprecated_member_use
    return c.value;
  }

  Color _argbToColor(int argb) => Color(argb);

  String _serializeInvoiceItems(List<CartLine> items) {
    final buf = StringBuffer();
    for (final l in items) {
      buf
        ..write(l.product.id)
        ..write('|')
        ..write(l.product.name.replaceAll('|', '_'))
        ..write('|')
        ..write(l.product.unitPrice)
        ..write('|')
        ..write(l.product.wholesaleCost)
        ..write('|')
        ..write(l.product.category.name)
        ..write('|')
        ..write(l.quantity)
        ..write(';');
    }
    return buf.toString();
  }

  List<CartLine> _deserializeInvoiceItems(String json) {
    if (json.isEmpty) return const <CartLine>[];
    final out = <CartLine>[];
    for (final part in json.split(';')) {
      if (part.isEmpty) continue;
      final bits = part.split('|');
      if (bits.length < 6) continue;
      try {
        final product = Product(
          id: bits[0],
          name: bits[1],
          category: _parseCategory(bits[4]),
          unitPrice: double.parse(bits[2]),
          wholesaleCost: double.parse(bits[3]),
          stock: 0,
        );
        out.add(CartLine(product: product, quantity: int.parse(bits[5])));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  /// Closes the underlying connection.
  Future<void> dispose() async {
    try {
      await _connection?.close();
    } catch (_) {
      // ignore — best effort.
    }
    _connection = null;
    _initialized = false;
  }
}
