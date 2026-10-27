/// Parsed success envelope `{ success, message, data, meta }`.
class ApiResponse {
  const ApiResponse({required this.data, this.message, this.meta = const {}});

  final dynamic data;
  final String? message;
  final Map<String, dynamic> meta;

  Map<String, dynamic> get dataMap =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : const {};

  List<Map<String, dynamic>> get dataList => data is List
      ? (data as List).whereType<Map<String, dynamic>>().toList()
      : const [];
}

/// Pagination info from `meta`.
class PageMeta {
  const PageMeta({
    this.page = 1,
    this.perPage = 15,
    this.total = 0,
    this.lastPage = 1,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
    page: _int(json['page'], 1),
    perPage: _int(json['per_page'], 15),
    total: _int(json['total'], 0),
    lastPage: _int(json['last_page'], 1),
  );

  final int page;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasMore => page < lastPage;

  static int _int(dynamic v, int fallback) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
}

class Paged<T> {
  const Paged(this.items, this.meta);

  final List<T> items;
  final PageMeta meta;
}
