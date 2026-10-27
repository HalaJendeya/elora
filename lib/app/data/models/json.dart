/// Tolerant JSON readers. The backend is the source of truth, but optional or
/// unverified fields must never crash parsing.
typedef Json = Map<String, dynamic>;

int? asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

double? asDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

String? asString(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return fallback;
}

Json asMap(dynamic v) => v is Map<String, dynamic> ? v : const {};

Json? asMapOrNull(dynamic v) => v is Map<String, dynamic> ? v : null;

List<T> asList<T>(dynamic v, T Function(Json) parse) =>
    v is List ? v.whereType<Map<String, dynamic>>().map(parse).toList() : <T>[];

List<String> asStringList(dynamic v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

DateTime? asDate(dynamic v) {
  final s = asString(v);
  return s == null ? null : DateTime.tryParse(s);
}

/// Parses an ISO timestamp as the salon's wall-clock time, ignoring the UTC
/// offset, so times render exactly as the server scheduled them regardless of
/// the device timezone.
DateTime? asWallClock(dynamic v) {
  final s = asString(v);
  if (s == null) return null;
  return DateTime.tryParse(s.replaceFirst(RegExp(r'(Z|[+-]\d\d:?\d\d)$'), ''));
}
