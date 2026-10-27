/// Client-side checks mirror the server's required fields. The server stays
/// authoritative: its 422 field errors are always shown when returned.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _phone = RegExp(r'^\+?[0-9\s-]{9,15}$');

  static String? name(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'يرجى إدخال الاسم';
    if (t.length < 2) return 'الاسم قصير جدًا';
    return null;
  }

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!_email.hasMatch(t)) return 'يرجى إدخال بريد إلكتروني صحيح';
    return null;
  }

  static String? phone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'يرجى إدخال رقم الهاتف';
    if (!_phone.hasMatch(t)) return 'يرجى إدخال رقم هاتف صحيح';
    return null;
  }

  static String? loginPassword(String? v) =>
      (v ?? '').isEmpty ? 'يرجى إدخال كلمة المرور' : null;

  /// Strength rules are the server's (returned as 422); only presence is
  /// checked locally.
  static String? newPassword(String? v) =>
      (v ?? '').isEmpty ? 'يرجى إدخال كلمة المرور' : null;

  static String? confirm(String? v, String original) {
    if ((v ?? '').isEmpty) return 'يرجى تأكيد كلمة المرور';
    if (v != original) return 'كلمتا المرور غير متطابقتين';
    return null;
  }
}
