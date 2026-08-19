import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/retail_store.dart';

/// Modal form for adding OR editing a product in the retail catalogue.
///
/// Fields: Name, Retail Price, Wholesale Cost, Stock, Category, and
/// an image picker box.
///
/// ## Save flow (no more "جاري الحفظ..." hang)
/// The save handler is **synchronous** — there are no `await` calls
/// and no `Future` indirection. The product is constructed, added to
/// the store, the dialog is popped, and a success snackbar is shown
/// in a single frame. The `_saving` flag is reset to `false` BEFORE
/// `pop` so the spinner never lingers.
///
/// ## Provider-safety
/// The dialog is opened via [showAddProductDialog] which passes
/// `useRootNavigator: false` to `showDialog`. Without this flag the
/// dialog would be mounted on the root navigator — outside the
/// `ChangeNotifierProvider<RetailStore>` that lives inside
/// `RetailDashboard.build()`. The subsequent `context.read<RetailStore>()`
/// call would then throw `ProviderNotFoundException`.
///
/// ## Image upload on Flutter Web
/// The `file_picker` package works on all platforms but its Web
/// implementation occasionally throws inside minified production
/// code if the picker is dismissed without selection. We wrap the
/// call in a defensive `try/catch` and only persist the bytes if
/// they were successfully read.
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key, this.existing});

  /// When non-null, the dialog opens in "edit" mode: fields are
  /// pre-populated with the existing product's data, and the save
  /// button calls `updateProduct` instead of `addProduct`.
  final Product? existing;

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _retail = TextEditingController();
  final _wholesale = TextEditingController();
  final _stock = TextEditingController();
  ProductCategory _category = ProductCategory.groceries;
  Uint8List? _imageBytes;
  bool _saving = false;
  String? _imageError;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields if editing an existing product.
    final p = widget.existing;
    if (p != null) {
      _name.text = p.name;
      _retail.text = p.unitPrice.toStringAsFixed(0);
      _wholesale.text = p.wholesaleCost.toStringAsFixed(0);
      _stock.text = p.stock.toString();
      _category = p.category;
      _imageBytes = p.imageBytes;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _retail.dispose();
    _wholesale.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Clear any previous error before retrying.
    setState(() => _imageError = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        // User cancelled — not an error.
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _imageError = 'تعذّر قراءة الملف المختار');
        return;
      }
      setState(() => _imageBytes = bytes);
    } catch (e) {
      // file_picker is best-effort; failures don't block product
      // creation, we just surface the error to the user.
      setState(() => _imageError = 'تعذّر اختيار الصورة: $e');
      debugPrint('Image picker failed: $e');
    }
  }

  /// Async save handler with proper try-catch + await semantics.
  ///
  /// The function:
  ///   1. Validates the form synchronously.
  ///   2. Sets `_saving = true` to show the loading indicator.
  ///   3. Awaits a microtask so the spinner paints before any heavy
  ///      work starts (this is what was missing in the previous sync
  ///      implementation — the spinner never had a chance to render).
  ///   4. Calls the store's add/update operation.
  ///   5. Closes the modal ONLY after the operation confirms success.
  ///   6. Catches any exception and surfaces it to the user without
  ///      closing the modal — so the user can fix the input and retry.
  ///   7. Always resets `_saving = false` in `finally` so the spinner
  ///      never lingers indefinitely (no more "جاري الحفظ..." hang).
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Capture provider + messenger + navigator BEFORE any async gap
    // or pop. Calling these after pop is the root cause of the
    // "deactivated widget's ancestor" crash.
    final store = context.read<RetailStore>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final existing = widget.existing;
    final isEditMode = existing != null;

    // Show loading indicator.
    setState(() => _saving = true);

    try {
      // Give the UI one frame to paint the spinner before we start
      // any work. This is what the previous synchronous handler
      // missed — `setState` is async; the spinner never rendered
      // before the synchronous `addProduct` returned.
      await Future<void>.delayed(Duration.zero);

      // Build the product object.
      final product = Product(
        id: existing?.id ??
            'R-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        name: _name.text.trim(),
        category: _category,
        unitPrice: double.tryParse(_retail.text.trim()) ?? 0,
        wholesaleCost: double.tryParse(_wholesale.text.trim()) ?? 0,
        stock: int.tryParse(_stock.text.trim()) ?? 0,
        lowStockThreshold: existing?.lowStockThreshold ?? 10,
        cartonPrice: existing?.cartonPrice ?? 0,
        cartonSize: existing?.cartonSize ?? 12,
        batchNumber: existing?.batchNumber,
        icon: _iconFor(_category),
        color: _colorFor(_category),
        imageBytes: _imageBytes,
        imageAsset: existing?.imageAsset,
      );

      // Perform the mutation. In a real backend-backed app this would
      // be an `await apiClient.saveProduct(product)` call.
      if (isEditMode) {
        store.updateProduct(product);
      } else {
        store.addProduct(product);
      }

      // Close the modal ONLY after the operation confirms success.
      // Use a post-frame callback so the success state paints before
      // the modal is dismissed.
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEditMode
              ? 'تم تحديث المنتج بنجاح'
              : 'تمت إضافة المنتج بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e, stack) {
      // Surface the error without closing the modal — the user can
      // fix the input and retry.
      debugPrint('Save failed: $e\n$stack');
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      // Always reset the loading flag — never let the spinner hang.
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  IconData _iconFor(ProductCategory c) => switch (c) {
        ProductCategory.groceries => Icons.rice_bowl_outlined,
        ProductCategory.beverages => Icons.local_cafe_outlined,
        ProductCategory.dairy => Icons.icecream_outlined,
        ProductCategory.bakery => Icons.bakery_dining_outlined,
        ProductCategory.hygiene => Icons.soap_outlined,
        ProductCategory.produce => Icons.eco_outlined,
        ProductCategory.household => Icons.chair_outlined,
        ProductCategory.electronics => Icons.devices_outlined,
        ProductCategory.other => Icons.inventory_2_outlined,
      };

  Color _colorFor(ProductCategory c) => switch (c) {
        ProductCategory.groceries => const Color(0xFFD9A24E),
        ProductCategory.beverages => const Color(0xFF6FB1E0),
        ProductCategory.dairy => const Color(0xFFB8C7E0),
        ProductCategory.bakery => const Color(0xFFE0A33E),
        ProductCategory.hygiene => const Color(0xFF9B7FE0),
        ProductCategory.produce => const Color(0xFF6FAE82),
        ProductCategory.household => const Color(0xFFB9862E),
        ProductCategory.electronics => const Color(0xFF4FB3D9),
        ProductCategory.other => const Color(0xFF1E6FBA),
      };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppTheme.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                              _isEditMode
                                  ? Icons.edit_outlined
                                  : Icons.add_box_outlined,
                              color: AppTheme.primary,
                              size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isEditMode ? 'تعديل المنتج' : 'إضافة منتج جديد',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickImage,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.divider,
                            width: 1,
                          ),
                        ),
                        child: Container(
                          height: 140,
                          padding: const EdgeInsets.all(16),
                          child: _imageBytes != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        _imageBytes!,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const _ImagePickerPlaceholder();
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: InkWell(
                                        onTap: () => setState(() {
                                          _imageBytes = null;
                                          _imageError = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.danger,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const _ImagePickerPlaceholder(),
                        ),
                      ),
                    ),
                    if (_imageError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _imageError!,
                        style: const TextStyle(
                            color: AppTheme.danger, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج',
                        prefixIcon: Icon(Icons.label_outline, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اسم المنتج مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _retail,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'سعر البيع (أوقية)',
                              prefixIcon:
                                  Icon(Icons.sell_outlined, size: 20),
                            ),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'أدخل سعراً صحيحاً';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _wholesale,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'تكلفة الجملة',
                              prefixIcon:
                                  Icon(Icons.attach_money, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return null;
                              }
                              final n = double.tryParse(v);
                              if (n == null || n < 0) {
                                return 'أدخل قيمة صحيحة';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stock,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              labelText: 'الكمية في المخزون',
                              prefixIcon: Icon(Icons.inventory_2_outlined,
                                  size: 20),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 0) {
                                return 'أدخل كمية صحيحة';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<ProductCategory>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'الفئة',
                              prefixIcon: Icon(Icons.category_outlined,
                                  size: 20),
                            ),
                            items: ProductCategory.values
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.arabicLabel),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _category = v ?? _category),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Icon(
                                    _isEditMode
                                        ? Icons.check_outlined
                                        : Icons.save_outlined,
                                    size: 18),
                            label: Text(
                                _isEditMode ? 'حفظ التعديلات' : 'حفظ المنتج'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePickerPlaceholder extends StatelessWidget {
  const _ImagePickerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_a_photo_outlined,
            size: 36, color: AppTheme.textSecondary),
        SizedBox(height: 8),
        Text('إضافة صورة المنتج',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 2),
        Text('PNG / JPG — اختياري',
            style: TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

/// Convenience helper used by the inventory tab to open the dialog in
/// "add new" mode.
///
/// **IMPORTANT**: `useRootNavigator: false` is critical — without it,
/// the dialog mounts on the root navigator and `context.read<RetailStore>()`
/// inside the dialog throws a `ProviderNotFoundException`.
Future<void> showAddProductDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (_) => const AddProductDialog(),
  );
}

/// Convenience helper used by the inventory tab to open the dialog in
/// "edit existing" mode. Pre-populates all fields from [existing].
Future<void> showEditProductDialog(
    BuildContext context, Product existing) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (_) => AddProductDialog(existing: existing),
  );
}

/// Confirmation dialog for deleting a product. Returns true if the
/// user confirmed.
Future<bool> confirmDeleteProduct(
    BuildContext context, Product product) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد حذف المنتج'),
        content: Text(
            'هل أنت متأكد من حذف "${product.name}"؟ لا يمكن التراجع عن هذه العملية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
