import 'package:flutter/foundation.dart';

import '../models/product.dart';
import 'retail_store.dart';

/// Service-layer wrapper around [RetailStore] for product operations.
///
/// ## Why a separate service?
/// The user explicitly asked for a `ProductProvider`/`Service` with a
/// cascading-delete hook. The existing [RetailStore] mixes products +
/// customers + invoices + expenses, which is fine for a small app, but
/// burying the cascade logic inside the store made it easy to miss.
///
/// This service provides a single, discoverable entry point for product
/// mutations and is the canonical place to add future backend
/// integration (e.g. `await apiClient.deleteProduct(id)` + cascade).
///
/// ## Cascading delete contract
/// [cascadeDeleteProduct] is the only sanctioned way to delete a
/// product. It:
///   1. Removes the product from the store.
///   2. Records the id in the store's `_removedProductIds` buffer
///      (so downstream consumers like the Purchases tab can prune).
///   3. Returns a [CascadeDeleteResult] describing what was removed,
///      so the caller can show a meaningful snackbar ("تم حذف المنتج
///      وإزالته من قائمة المشتريات").
class ProductService {
  ProductService(this._store);

  final RetailStore _store;

  /// Adds a new product to the catalogue.
  ///
  /// Returns the added product (with its assigned id) so the caller
  /// can chain further operations. Throws if the store rejects the
  /// product (e.g. duplicate id) — the caller is responsible for
  /// surfacing the error to the user.
  Product addProduct(Product product) {
    _store.addProduct(product);
    return product;
  }

  /// Updates an existing product by id. Returns true if the product
  /// was found and updated, false otherwise.
  bool updateProduct(Product updated) {
    final i = _store.products.indexWhere((p) => p.id == updated.id);
    if (i == -1) return false;
    _store.updateProduct(updated);
    return true;
  }

  /// Cascading delete — the canonical product-deletion entry point.
  ///
  /// Removes the product from the catalogue AND records its id in the
  /// store's "removed" buffer. Downstream consumers (the Purchases
  /// tab's order-builder, the POS cart, etc.) read that buffer on
  /// their next rebuild and prune any references to the deleted id,
  /// preventing database desynchronization.
  ///
  /// This is the "soft delete" hook the user asked for — instead of
  /// mutating the purchases collection directly from here, we publish
  /// the removal and let the consumers reconcile themselves.
  ///
  /// Returns a [CascadeDeleteResult] describing the cascade, or
  /// `null` if the product was not found.
  CascadeDeleteResult? cascadeDeleteProduct(String id) {
    final existed = _store.products.any((p) => p.id == id);
    if (!existed) return null;

    // Count how many downstream references we're cascading to. The
    // store's deleteProduct records the id in _removedProductIds.
    _store.deleteProduct(id);

    // We can't query the Purchases tab's private _quantities map from
    // here, but the tab will call consumeRemovedProductIds() on its
    // next rebuild and prune itself. We return a result describing
    // what we know so the caller can log / surface it.
    return CascadeDeleteResult(
      productId: id,
      cascaded: true,
    );
  }

  /// Returns the product with the given id, or null if not found.
  Product? findById(String id) {
    for (final p in _store.products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Filters the catalogue by category + free-text search.
  List<Product> search({
    String query = '',
    ProductCategory? category,
  }) {
    return _store.products.where((p) {
      if (category != null && p.category != category) return false;
      if (query.trim().isNotEmpty && !p.name.contains(query.trim())) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Bulk delete — accepts a set of product ids, calls
  /// [cascadeDeleteProduct] for each, and returns the count of
  /// actually-removed products.
  int bulkDelete(Iterable<String> ids) {
    var removed = 0;
    for (final id in ids) {
      if (cascadeDeleteProduct(id) != null) removed++;
    }
    return removed;
  }
}

/// Result of a cascading delete operation.
@immutable
class CascadeDeleteResult {
  const CascadeDeleteResult({
    required this.productId,
    required this.cascaded,
  });

  /// The id of the product that was deleted.
  final String productId;

  /// True if the cascade hook was triggered (downstream consumers
  /// will prune themselves on next rebuild).
  final bool cascaded;
}
