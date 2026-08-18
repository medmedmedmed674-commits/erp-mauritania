import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../utils/retail_store.dart';

/// Modal form for adding a new product to the retail catalogue.
/// Fields: Name, Retail Price, Wholesale Cost, Stock, Category,
/// and an image picker box.
///
/// The image picker uses `file_picker` which works on Web, Android,
/// iOS, macOS, Windows, Linux. On Web the picked bytes are kept in
/// memory and shown as a preview thumbnail.
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

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

  @override
  void dispose() {
    _name.dispose();
    _retail.dispose();
    _wholesale.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageBytes = result.files.first.bytes;
        });
      }
    } catch (e) {
      // The file picker is best-effort; failures don't block product
      // creation, we just leave the preview empty.
      debugPrint('Image picker failed: $e');
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final product = Product(
        id:
            'R-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        name: _name.text.trim(),
        category: _category,
        unitPrice: double.tryParse(_retail.text.trim()) ?? 0,
        wholesaleCost: double.tryParse(_wholesale.text.trim()) ?? 0,
        stock: int.tryParse(_stock.text.trim()) ?? 0,
        lowStockThreshold: 10,
        icon: _iconFor(_category),
        color: _colorFor(_category),
      );
      context.read<RetailStore>().addProduct(product);
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة المنتج بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
                          child: const Icon(Icons.add_box_outlined,
                              color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'إضافة منتج جديد',
                            style: TextStyle(
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
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_a_photo_outlined,
                                        size: 36,
                                        color: AppTheme.textSecondary),
                                    SizedBox(height: 8),
                                    Text('إضافة صورة المنتج',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                AppTheme.textSecondary,
                                            fontWeight:
                                                FontWeight.w700)),
                                    SizedBox(height: 2),
                                    Text('PNG / JPG — اختياري',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppTheme.textSecondary)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج',
                        prefixIcon:
                            Icon(Icons.label_outline, size: 20),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
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
                              prefixIcon: Icon(Icons.attach_money,
                                  size: 20),
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
                                : const Icon(Icons.save_outlined, size: 18),
                            label: const Text('حفظ المنتج'),
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

/// Convenience helper used by the inventory tab.
Future<void> showAddProductDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const AddProductDialog(),
  );
}
