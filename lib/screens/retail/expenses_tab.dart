import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';

/// NEW Tab 5 — Expense Management.
/// Operational expenses (rent, maintenance, electricity, water,
/// salaries, other) with an "Add Expense" modal and a summary view.
class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final expenses = store.expenses;
    final total = store.totalExpenses;
    final monthTotal = store.monthExpenses;
    final breakdown = store.expenseBreakdown;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              title: 'إدارة المصروفات',
              subtitle: 'المصاريف التشغيلية: إيجار، صيانات، فواتير، رواتب',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                StatPill(
                  label: 'إجمالي المصروفات',
                  value: Money.formatWithCurrency(total),
                  tone: StatTone.danger,
                  icon: Icons.trending_down,
                ),
                StatPill(
                  label: 'مصروفات الشهر',
                  value: Money.formatWithCurrency(monthTotal),
                  tone: StatTone.warning,
                  icon: Icons.calendar_today_outlined,
                ),
                StatPill(
                  label: 'عدد السجلات',
                  value: '${expenses.length}',
                  tone: StatTone.info,
                  icon: Icons.list_alt_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (breakdown.isNotEmpty) ...[
              const SectionTitle(
                title: 'حسب الفئة',
                subtitle: 'تفصيل المصروفات لكل نوع',
                icon: Icons.pie_chart_outline,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: breakdown.entries.map((e) {
                  return StatPill(
                    label: e.key.arabicLabel,
                    value: Money.formatWithCurrency(e.value),
                    tone: _toneFor(e.key),
                    icon: _iconFor(e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: expenses.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'لا توجد مصروفات مسجلة',
                      subtitle: 'أضف أول مصروف لتتبّع التدفق النقدي',
                    )
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) => _ExpenseTile(
                          expense: expenses[i]),
                    ),
            ),
          ],
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => showAddExpenseDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('إضافة مصروف جديد'),
          ),
        ),
      ],
    );
  }

  StatTone _toneFor(ExpenseCategory c) => switch (c) {
        ExpenseCategory.rent => StatTone.danger,
        ExpenseCategory.maintenance => StatTone.warning,
        ExpenseCategory.electricity => StatTone.info,
        ExpenseCategory.water => StatTone.info,
        ExpenseCategory.salary => StatTone.success,
        ExpenseCategory.other => StatTone.neutral,
      };

  IconData _iconFor(ExpenseCategory c) => switch (c) {
        ExpenseCategory.rent => Icons.home_outlined,
        ExpenseCategory.maintenance => Icons.build_outlined,
        ExpenseCategory.electricity => Icons.bolt_outlined,
        ExpenseCategory.water => Icons.water_drop_outlined,
        ExpenseCategory.salary => Icons.people_outline,
        ExpenseCategory.other => Icons.more_horiz,
      };
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('حذف المصروف'),
                content: Text(
                    'هل تريد حذف مصروف "${expense.category.arabicLabel}" بقيمة ${Money.formatWithCurrency(expense.amount)}؟'),
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
        },
        onDismissed: (_) {
          final messenger = ScaffoldMessenger.of(context);
          context.read<RetailStore>().deleteExpense(expense.id);
          messenger.showSnackBar(
            SnackBar(
              content: Text('تم حذف المصروف'),
              backgroundColor: AppTheme.danger,
            ),
          );
        },
        background: Container(
          color: AppTheme.danger,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 24),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward,
                color: AppTheme.danger, size: 18),
          ),
          title: Text(
            expense.note.isEmpty
                ? expense.category.arabicLabel
                : expense.note,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: Wrap(
            spacing: 8,
            children: [
              Text(expense.category.arabicLabel,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              LtrText(
                '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          trailing: LtrText(
            Money.formatWithCurrency(expense.amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.danger,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Expense dialog
// ---------------------------------------------------------------------------
Future<void> showAddExpenseDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (_) => const _AddExpenseDialog(),
  );
}

class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.rent;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    // Capture provider + messenger + navigator BEFORE pop — calling
    // ScaffoldMessenger.of(context) after Navigator.pop crashes with
    // "deactivated widget's ancestor". And the dialog must NOT use the
    // root navigator (useRootNavigator: false in showAddExpenseDialog)
    // or context.read<RetailStore>() will throw ProviderNotFoundException.
    final store = context.read<RetailStore>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final amount = double.tryParse(_amount.text.trim()) ?? 0;
      if (amount <= 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('المبلغ يجب أن يكون أكبر من صفر'),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
      final expense = Expense(
        id: 'E-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        category: _category,
        amount: amount,
        date: _date,
        note: _note.text.trim(),
      );
      store.addExpense(expense);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل المصروف بنجاح'),
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
            borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                            color: AppTheme.danger.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_card_outlined,
                              color: AppTheme.danger, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('إضافة مصروف جديد',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'نوع المصروف',
                        prefixIcon:
                            Icon(Icons.category_outlined, size: 20),
                      ),
                      items: ExpenseCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.arabicLabel)))
                          .toList(),
                      onChanged: (v) => setState(
                          () => _category = v ?? _category),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ (أوقية)',
                        prefixIcon:
                            Icon(Icons.payments_outlined, size: 20),
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'أدخل مبلغاً صحيحاً';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.divider, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.event_outlined,
                                  size: 20, color: AppTheme.textSecondary),
                              const SizedBox(width: 10),
                              const Text('التاريخ',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          AppTheme.textSecondary)),
                              const Spacer(),
                              LtrText(
                                '${_date.day}/${_date.month}/${_date.year}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon:
                            Icon(Icons.note_alt_outlined, size: 20),
                      ),
                      maxLines: 2,
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
                                : const Icon(Icons.save_outlined,
                                    size: 18),
                            label: const Text('حفظ المصروف'),
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
