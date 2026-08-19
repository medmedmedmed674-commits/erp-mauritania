import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../theme/app_theme.dart';
import '../../utils/money.dart';
import '../../utils/retail_store.dart';
import '../../widgets/ltr_text.dart';
import '../../widgets/shared_widgets.dart';
import 'invoice_dialog.dart';

/// Tab 6 — Analytics & Daily Summary.
///
/// A prominent **inline calendar** is shown at the top of the screen.
/// The user can tap any day (today, yesterday, last week, or any past
/// month) to instantly recompute:
///   - Total Sales for that day
///   - Net Profit for that day
///   - Number of invoices issued that day
///   - Average invoice value
///   - Itemized list of all invoices issued on that date — each row
///     tappable to open the printable [InvoiceDialog].
class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = _stripTime(DateTime.now());
    _selectedDate = now;
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  /// Strips the time component so day comparisons are clean.
  DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickDateViaPicker() async {
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'اختر التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      locale: const Locale('ar', 'MR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = _stripTime(picked);
        _displayedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDate = DateTime(
        _displayedMonth.year,
        _displayedMonth.month,
        day,
      );
    });
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  bool get _isToday {
    final now = _stripTime(DateTime.now());
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  /// Returns true if the given day matches the selected date.
  bool _isSelected(int day) =>
      _selectedDate.year == _displayedMonth.year &&
      _selectedDate.month == _displayedMonth.month &&
      _selectedDate.day == day;

  /// Returns true if the given day is in the future and should be disabled.
  bool _isFuture(int day) {
    final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
    final now = _stripTime(DateTime.now());
    return date.isAfter(now);
  }

  /// Returns the number of invoices on the given day (used for badge).
  int _invoiceCount(int day) {
    final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
    return context.read<RetailStore>().invoicesForDay(date).length;
  }

  /// Returns the Arabic month name for the [_displayedMonth].
  String get _monthLabel {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}';
  }

  /// Builds the calendar grid: weekday header + day cells.
  /// RTL means the week starts with Saturday.
  Widget _buildCalendar() {
    // First day of the displayed month.
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    // 7=Saturday, 1=Monday, etc. (DateTime.weekday returns Mon=1..Sun=7)
    // Convert to RTL order: Sat, Sun, Mon, Tue, Wed, Thu, Fri.
    final firstWeekday = firstOfMonth.weekday; // 1=Mon..7=Sun
    // Offset for Sat-start week: Sat=0, Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6
    final int leadingBlanks;
    switch (firstWeekday) {
      case 1: // Monday
        leadingBlanks = 2;
      case 2: // Tuesday
        leadingBlanks = 3;
      case 3: // Wednesday
        leadingBlanks = 4;
      case 4: // Thursday
        leadingBlanks = 5;
      case 5: // Friday
        leadingBlanks = 6;
      case 6: // Saturday
        leadingBlanks = 0;
      case 7: // Sunday
        leadingBlanks = 1;
      default:
        leadingBlanks = 0;
    }
    final daysInMonth =
        DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    final cells = <Widget>[];
    // Leading blanks
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final selected = _isSelected(day);
      final future = _isFuture(day);
      final count = future ? 0 : _invoiceCount(day);
      cells.add(_DayCell(
        day: day,
        selected: selected,
        future: future,
        invoiceCount: count,
        onTap: future ? null : () => _selectDay(day),
      ));
    }

    return Column(
      children: [
        // Month navigation header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_right, size: 22),
                tooltip: 'الشهر السابق',
              ),
              Expanded(
                child: Text(
                  _monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_left, size: 22),
                tooltip: 'الشهر التالي',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Weekday header (RTL: Sat → Fri)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['سبت', 'أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Day grid (7 columns)
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.0,
          children: cells,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final invoices = store.invoicesForDay(_selectedDate);
    final sales = store.salesForDay(_selectedDate);
    final profit = store.profitForDay(_selectedDate);
    final invoiceCount = invoices.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionTitle(
            title: 'التحليلات اليومية',
            subtitle: 'اختر يوماً من التقويم لعرض مبيعاته وأرباحه وفواتيره',
            icon: Icons.analytics_outlined,
          ),
          const SizedBox(height: 16),
          // ----- Calendar card -----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Selected date header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isToday ? 'اليوم' : 'التاريخ المحدد',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            LtrText(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickDateViaPicker,
                        icon: const Icon(Icons.edit_calendar_outlined,
                            size: 16),
                        label: const Text('تقويم',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildCalendar(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ----- Daily metrics -----
          Row(
            children: [
              Expanded(
                child: _DailyKpiCard(
                  title: 'إجمالي المبيعات',
                  value: Money.formatWithCurrency(sales),
                  tone: StatTone.success,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DailyKpiCard(
                  title: 'صافي الربح',
                  value: Money.formatWithCurrency(profit),
                  tone: StatTone.info,
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DailyKpiCard(
                  title: 'عدد الفواتير',
                  value: '$invoiceCount',
                  tone: StatTone.neutral,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DailyKpiCard(
                  title: 'متوسط الفاتورة',
                  value: invoiceCount > 0
                      ? Money.formatWithCurrency(sales / invoiceCount)
                      : '0 أوقية',
                  tone: StatTone.warning,
                  icon: Icons.point_of_sale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ----- Invoices list for the selected day -----
          Row(
            children: [
              const Text('فواتير هذا اليوم',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LtrText(
                  '$invoiceCount فاتورة',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('اضغط على أي فاتورة لعرضها وطباعتها',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            const _EmptyDayCard()
          else
            ...invoices.map((inv) => _DayInvoiceTile(
                  invoice: inv,
                  onTap: () => _openReceipt(inv),
                )),
        ],
      ),
    );
  }

  /// Re-opens the printable [InvoiceDialog] for a past invoice so the
  /// user can save as PNG, save as PDF, or print it again.
  void _openReceipt(Invoice invoice) {
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => InvoiceDialog(
        invoice: invoice,
        customerName: invoice.customerName,
        customerPhone: invoice.customerPhone,
      ),
    );
  }
}

/// A single calendar day cell. Shows the day number, a small badge
/// with the invoice count when > 0, and is filled with the brand
/// colour when selected.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.future,
    required this.invoiceCount,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool future;
  final int invoiceCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = future || onTap == null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary
              : (invoiceCount > 0
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : (invoiceCount > 0
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : Colors.transparent),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : (disabled
                          ? AppTheme.textSecondary.withValues(alpha: 0.4)
                          : AppTheme.textPrimary),
                ),
              ),
            ),
            if (invoiceCount > 0 && !selected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$invoiceCount',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else if (selected && invoiceCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$invoiceCount',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyKpiCard extends StatelessWidget {
  const _DailyKpiCard({
    required this.title,
    required this.value,
    required this.tone,
    required this.icon,
  });
  final String title;
  final String value;
  final StatTone tone;
  final IconData icon;

  Color _bg() => switch (tone) {
        StatTone.success => AppTheme.success,
        StatTone.warning => AppTheme.warning,
        StatTone.danger => AppTheme.danger,
        StatTone.info => AppTheme.info,
        StatTone.neutral => AppTheme.textPrimary,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _bg().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _bg(), size: 16),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            LtrText(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            Icon(Icons.event_busy_outlined,
                size: 36, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('لا توجد فواتير في هذا اليوم',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('اختر يوماً آخر أو سجّل مبيعات جديدة من نقطة البيع',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DayInvoiceTile extends StatelessWidget {
  const _DayInvoiceTile({required this.invoice, required this.onTap});
  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_outlined,
                color: AppTheme.primary, size: 18),
          ),
          title: Row(
            children: [
              LtrText(invoice.id,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              LtrText(
                '${invoice.date.hour.toString().padLeft(2, '0')}:${invoice.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          subtitle: Text(
            '${invoice.customerName} • ${invoice.items.length} صنف • ${invoice.paymentType.arabicLabel}',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LtrText(
                    Money.formatWithCurrency(invoice.total),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                  const SizedBox(height: 2),
                  invoice.isSettled
                      ? const Text('خالص',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.success))
                      : LtrText(
                          'متبقي: ${Money.format(invoice.balance)}',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.danger),
                        ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_left,
                  size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
