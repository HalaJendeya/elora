enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  rateLimited,
  server,
  parsing,
  unknown,
}

/// Normalised error produced by [ApiClient] for every failed request.
class ApiException implements Exception {
  ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    Map<String, dynamic>? details,
  }) : details = details ?? const {};

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  /// Backend error code, e.g. `VALIDATION_ERROR`, `SLOT_UNAVAILABLE`, `SLOT_TAKEN`.
  final String? code;
  final Map<String, dynamic> details;

  bool get isValidation => kind == ApiErrorKind.validation;
  bool get isUnauthorized => kind == ApiErrorKind.unauthorized;
  bool hasCode(String value) => code == value;

  /// Field errors for 422 responses: `{ field: [messages] }` → `{ field: first }`.
  Map<String, String> get fieldErrors {
    if (!isValidation) return const {};
    final result = <String, String>{};
    details.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        result[key] = value.first.toString();
      } else if (value is String) {
        result[key] = value;
      }
    });
    return result;
  }

  static ApiErrorKind kindForStatus(int status) {
    if (status == 401) return ApiErrorKind.unauthorized;
    if (status == 403) return ApiErrorKind.forbidden;
    if (status == 404) return ApiErrorKind.notFound;
    if (status == 409) return ApiErrorKind.conflict;
    if (status == 422) return ApiErrorKind.validation;
    if (status == 429) return ApiErrorKind.rateLimited;
    if (status >= 500) return ApiErrorKind.server;
    return ApiErrorKind.unknown;
  }

  static String fallbackMessage(ApiErrorKind kind) {
    switch (kind) {
      case ApiErrorKind.network:
        return 'تعذّر الاتصال بالخادم. تحققي من اتصالكِ بالإنترنت.';
      case ApiErrorKind.timeout:
        return 'استغرق الطلب وقتًا أطول من المتوقع. حاولي مرة أخرى.';
      case ApiErrorKind.unauthorized:
        return 'يجب تسجيل الدخول أولًا.';
      case ApiErrorKind.forbidden:
        return 'لا تملكين صلاحية لهذا الإجراء.';
      case ApiErrorKind.notFound:
        return 'العنصر المطلوب غير موجود.';
      case ApiErrorKind.validation:
        return 'البيانات المدخلة غير صحيحة.';
      case ApiErrorKind.conflict:
        return 'تعذّر إتمام الطلب بسبب تعارض.';
      case ApiErrorKind.rateLimited:
        return 'طلبات كثيرة خلال وقت قصير. انتظري قليلًا ثم حاولي مجددًا.';
      case ApiErrorKind.server:
        return 'حدث خطأ في الخادم. حاولي لاحقًا.';
      case ApiErrorKind.parsing:
        return 'وصلت استجابة غير متوقعة من الخادم.';
      case ApiErrorKind.unknown:
        return 'حدث خطأ غير متوقع.';
    }
  }

  @override
  String toString() => 'ApiException($kind, $statusCode, $code): $message';
}
