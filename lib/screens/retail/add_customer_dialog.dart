import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/retail_store.dart';

/// Modal form for adding a new customer to the retail ledger.
///
/// ## Save flow (no more freeze)
/// The `_save()` handler:
///   1. Validates the form synchronously (returns early on error —
///      no spinner shown so the user sees the validation messages).
///   2. Sets `_saving = true` → button shows spinner.
///   3. Awaits one microtask so the spinner paints.
///   4. Constructs the Customer object from the form fields.
///   5. Calls `store.addCustomer(customer)` — this is synchronous
///      for the local state + fires a background DB UPSERT.
///   6. On success → `navigator.pop()` + success SnackBar.
///   7. On failure → error SnackBar (modal stays open so user can retry).
///   8. `finally` → always resets `_saving = false` if still mounted.
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

  // ─── Validation ───────────────────────────────────────────────
  // Phone: required, at least 8 digits. We're lenient about the
  // starting digit so we don't block valid numbers the user might
  // enter. The strict Mauritanian format (starts with 2/3/4) is
  // enforced only on the auth screen, not here.
  String? _validatePhone(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return 'رقم الهاتف مطلوب';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return '8 أرقام على الأقل';
    return null;
  }

  String? _validateEmail(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return null; // optional
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(raw)) {
      return 'صيغة بريد غير صحيحة';
    }
    return null;
  }

  String? _validateDebt(String? v) {
    final raw = (v ?? '').trim();
    if (raw.isEmpty) return null; // optional, defaults to 0
    final n = double.tryParse(raw);
    if (n == null || n < 0) return 'أدخل قيمة صحيحة';
    return null;
  }

  // ─── Save ─────────────────────────────────────────────────────
  Future<void> _save() async {
    // 1. Validate — if the form has errors, return WITHOUT showing
    //    the spinner so the user sees the inline validation messages.
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // 2. Capture everything we need from context BEFORE any await.
    //    After `await`, the widget may have been disposed if the
    //    user navigates away.
    final store = context.read<RetailStore>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 3. Show the loading spinner.
    setState(() => _saving = true);

    try {
      // 4. Yield one frame so the spinner actually renders before
      //    we do any work. This is the #1 fix for "frozen button" UX.
      await Future<void>.delayed(Duration.zero);

      // 5. Build the customer from the form fields.
      final debtText = _debt.text.trim();
      final customer = Customer(
        id:
            'C-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        city: _selectedCity,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        outstandingDebt: debtText.isEmpty ? 0 : (double.tryParse(debtText) ?? 0),
        totalPurchases: 0,
        totalProfit: 0,
        type: CustomerType.registered,
        lastInvoiceDate: null,
      );

      // 6. Persist — addCustomer is synchronous for the local state
      //    and fires a background DB UPSERT. It never throws to the
      //    caller; DB errors are surfaced via store.lastError.
      store.addCustomer(customer);

      // 7. Success → close modal + show confirmation.
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة الزبون بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e, stack) {
      // 8. Failure → show error, keep modal open so user can retry.
      debugPrint('Save customer failed: $e\n$stack');
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      // 9. Always reset the spinner — never hang.
      if (mounted) {
        setState(() => _saving = false);
      }
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
                    // Header
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
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    // Name
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'اسم الزبون',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اسم الزبون مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Phone
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        hintText: '2XXX XXXX',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    // City dropdown
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
                      onChanged: _saving
                          ? null
                          : (v) => setState(
                              () => _selectedCity = v ?? _selectedCity),
                    ),
                    const SizedBox(height: 12),
                    // Email (optional)
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني (اختياري)',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    // Opening debt (optional)
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
                      validator: _validateDebt,
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
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

/// Confirmation dialog for deleting a customer.
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
