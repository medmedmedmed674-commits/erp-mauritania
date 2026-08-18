import 'package:intl/intl.dart';

/// Money / number formatting helpers.
///
/// ## Why this exists
/// In an RTL Arabic context, mixed strings like "18000 أوقية" can be
/// rendered visually reversed by the BiDi algorithm (e.g. "000181 أوقية")
/// because the leading Latin digits get reordered relative to the
/// surrounding RTL text direction. This is a well-known Flutter / Skia
/// rendering issue.
///
/// ## Fix strategy
/// 1. Format the number with thousands separators (`18,000`).
/// 2. Wrap the formatted digits in Unicode LTR isolation marks
///    (`\u2066` ... `\u2069`) so the BiDi algorithm treats them as an
///    embedded LTR run inside the surrounding RTL text.
/// 3. Callers that display pure numbers should additionally wrap the
///    `Text` widget in `Directionality(textDirection: TextDirection.ltr)`
///    — see the [LtrText] widget in `lib/widgets/ltr_text.dart`.
class Money {
  Money._();

  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  /// Formats a numeric amount with thousands separators.
  /// Example: `18300.0` → `"18,300"`.
  static String format(double value) => _formatter.format(value.round());

  /// Formats a value with the Mauritanian currency suffix.
  /// Example: `18300.0` → `"18,300 أوقية"`.
  /// The number is wrapped in Unicode LTR isolation marks so it renders
  /// correctly inside RTL parent contexts.
  static String formatWithCurrency(double value) {
    return '${format(value)} أوقية';
  }

  /// Returns the formatted number wrapped in Unicode LTR isolate marks
  /// (`\u2066 ... \u2069`). Use this when embedding a price inside a
  /// larger RTL Text.rich span.
  static String ltrIsolated(double value) {
    return '\u2066${format(value)}\u2069';
  }

  /// Returns the formatted number + currency wrapped in Unicode LTR
  /// isolate marks. Use this in Text.rich spans where the surrounding
  /// text is RTL Arabic.
  static String ltrIsolatedWithCurrency(double value) {
    return '\u2066${format(value)}\u2069 أوقية';
  }
}
