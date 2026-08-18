/// Validators shared across the auth + customer forms.
class AppValidators {
  AppValidators._();

  /// Mauritanian phone rules: 8 digits, first digit in {2, 3, 4}.
  /// This matches the Mauritel / Mattel mobile numbering plan.
  static String? phone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'يرجى إدخال رقم الهاتف';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return 'رقم الهاتف يجب أن يتكون من 8 أرقام';
    if (!RegExp(r'^[2-4]').hasMatch(digits)) {
      return 'يجب أن يبدأ الرقم بـ 2 أو 3 أو 4';
    }
    return null;
  }

  static String? email(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null; // optional
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(raw)) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  static String? requiredField(String label, String? value) {
    if (value == null || value.trim().isEmpty) return '$label مطلوب';
    return null;
  }

  static String? password(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) return 'كلمة المرور مطلوبة';
    if (raw.length < 6) return '6 أحرف على الأقل';
    return null;
  }

  static String? matchPassword(String? value, String reference) {
    if (value != reference) return 'كلمتا المرور غير متطابقتين';
    return null;
  }
}
