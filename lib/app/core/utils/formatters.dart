import 'package:intl/intl.dart';

/// Display helpers. Arabic locale; Latin digits are kept for prices and
/// times to match the Figma (e.g. "280 ₪", "09:00").
class Fmt {
  Fmt._();

  static String price(num? value, [String currency = '₪']) {
    if (value == null) return '—';
    final text = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return '$text $currency';
  }

  static String duration(int minutes, {String? label}) {
    if (label != null && label.isNotEmpty) return label;
    if (minutes <= 0) return '';
    if (minutes % 60 == 0) {
      final h = minutes ~/ 60;
      return h == 1
          ? 'ساعة'
          : h == 2
          ? 'ساعتان'
          : '$h ساعات';
    }
    return '$minutes دقيقة';
  }

  /// "HH:mm" (24h, salon time) → "4:30 م".
  static String time12(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return '';
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1
        ? parts[1].padLeft(2, '0').substring(0, 2)
        : '00';
    final suffix = h < 12 ? 'ص' : 'م';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }

  static String clock(DateTime? d) => d == null
      ? ''
      : time12('${d.hour}:${d.minute.toString().padLeft(2, '0')}');

  /// "الخميس، 18 أبريل"
  static String dayMonth(DateTime? d) =>
      d == null ? '' : DateFormat('EEEE، d MMMM', 'ar').format(d).latinDigits;

  static String monthShort(DateTime? d) =>
      d == null ? '' : DateFormat('MMMM', 'ar').format(d);

  static String weekday(DateTime? d) =>
      d == null ? '' : DateFormat('EEEE', 'ar').format(d);

  static String monthYear(DateTime? d) =>
      d == null ? '' : DateFormat('MMMM y', 'ar').format(d).latinDigits;

  static String dateTime(DateTime? d) =>
      d == null ? '' : '${dayMonth(d)} · ${clock(d)}';

  /// mm:ss for countdowns.
  static String countdown(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  static String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}

extension LatinDigits on String {
  String get latinDigits {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in runes) {
      final ch = String.fromCharCode(rune);
      final i = arabic.indexOf(ch);
      buffer.write(i >= 0 ? '$i' : ch);
    }
    return buffer.toString();
  }
}
