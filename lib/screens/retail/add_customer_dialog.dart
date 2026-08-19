import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/retail_store.dart';
import '../../utils/validators.dart';

/// Modal form for adding a new customer to the retail ledger.
///
/// Fields: Name, Phone (8-digit Mauritanian), City, optional Email,
/// and an optional opening debt balance.
///
/// ## Provider-safety
/// The dialog is opened via [showAddCustomerDialog] which passes
/// `useRootNavigator: false` to `showDialog`. Without this flag the
/// dialog mounts on the root navigator — outside the
/// `ChangeNotifierProvider<RetailStore>` that lives inside
/// `RetailDashboard.build()` — and the subsequent
/// `context.read<RetailStore>()` would throw `ProviderNotFoundException`.
class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _debt = TextEditingController();
  String _selectedCity = 'نواكشوط';
  bool _saving = false;

  static const List<String> _mauritanianCities = [
    'نواكشوط',
    'نواذيبو',
    'روصو',
    'كيفه',
    'نواكشوط الشمالية',
    'أطار',
    'زويرات',
    'ألاق',
    'بوتلميت',
    'اكجوجت',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _debt.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final store = context.read<RetailStore>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final customer = Customer(
        id: 'C-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        city: _selectedCity,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        outstandingDebt: double.tryParse(_debt.text.trim()) ?? 0,
        totalPurchases: 0,
        totalProfit: 0,
        type: CustomerType.registered,
        lastInvoiceDate: null,
      );
      store.addCustomer(customer);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة الزبون بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
                          child: const Icon(Icons.person_add_alt_outlined,
                              color: AppTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'إضافة زبون جديد',
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
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'اسم الزبون',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اسم الزبون مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف الموريتاني (8 أرقام)',
                        hintText: '2XXX XXXX',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: AppValidators.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: const InputDecoration(
                        labelText: 'المدينة',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                      items: _mauritanianCities
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCity = v ?? _selectedCity),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني (اختياري)',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _debt,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'رصيد افتتاحي للدين (اختياري)',
                        hintText: '0',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                            size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v);
                        if (n == null || n < 0) {
                          return 'أدخل قيمة صحيحة';
                        }
                        return null;
                      },
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
                            label: const Text('حفظ الزبون'),
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

/// Convenience helper used by the customers tab.
///
/// **IMPORTANT**: `useRootNavigator: false` is critical so the dialog
/// mounts inside the `ChangeNotifierProvider<RetailStore>` tree.
Future<void> showAddCustomerDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (_) => const AddCustomerDialog(),
  );
}

/// Confirmation dialog for deleting a customer. Returns true if the
/// user confirmed. Uses `useRootNavigator: false` for the same
/// provider-safety reason.
Future<bool> confirmDeleteCustomer(
  BuildContext context,
  Customer customer,
) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (dialogContext) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد حذف الزبون'),
        content: Text(
            'هل أنت متأكد من حذف "${customer.name}"؟ سيتم حذفه نهائياً من السجل.'),
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
