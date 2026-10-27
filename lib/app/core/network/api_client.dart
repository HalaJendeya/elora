import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

typedef TokenReader = String? Function();

/// A file attached to a multipart request.
class UploadFile {
  const UploadFile({required this.field, required this.path, this.filename});

  final String field;
  final String path;
  final String? filename;
}

/// Single shared HTTP entry point. Handles headers, auth, timeouts, UTF-8
/// decoding, query encoding, the response envelope and error mapping.
class ApiClient {
  ApiClient({
    required this._client,
    required this._config,
    required this._readToken,
    this.onUnauthorized,
    bool? logShapes,
    this.retryDelay = const Duration(milliseconds: 600),
  }) : logShapes = logShapes ?? kDebugMode;

  /// Debug aid: print response shapes (keys and types only). Off in release.
  final bool logShapes;
  final Duration retryDelay;

  final http.Client _client;
  final AppConfig _config;
  final TokenReader _readToken;

  /// Called when an authenticated request returns 401 (expired/revoked token).
  void Function()? onUnauthorized;

  /// Builds `/places/{slug}/<path>`.
  String place([String path = '']) {
    final base = '/places/${Uri.encodeComponent(_config.placeSlug)}';
    return path.isEmpty ? base : '$base/$path';
  }

  Uri buildUri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(_config.baseUrl);
    final cleanQuery = <String, String>{};
    query?.forEach((key, value) {
      if (value == null) return;
      final text = value is bool ? (value ? '1' : '0') : value.toString();
      if (text.isEmpty) return;
      cleanQuery[key] = text;
    });
    return base.replace(
      path: '${base.path}$path',
      queryParameters: cleanQuery.isEmpty ? null : cleanQuery,
    );
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = false,
  }) => _send('GET', path, query: query, auth: auth);

  Future<ApiResponse> post(String path, {Object? body, bool auth = false}) =>
      _send('POST', path, body: body, auth: auth);

  Future<ApiResponse> put(String path, {Object? body, bool auth = false}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<ApiResponse> delete(String path, {bool auth = false}) =>
      _send('DELETE', path, auth: auth);

  Future<ApiResponse> multipart(
    String path, {
    Map<String, String> fields = const {},
    List<UploadFile> files = const [],
    bool auth = true,
  }) async {
    final request = http.MultipartRequest('POST', buildUri(path));
    request.headers.addAll(_headers(auth: auth, json: false));
    request.fields.addAll(fields);
    for (final file in files) {
      request.files.add(
        await http.MultipartFile.fromPath(
          file.field,
          file.path,
          filename: file.filename,
        ),
      );
    }
    return _execute(
      () async => http.Response.fromStream(
        await _client.send(request).timeout(_config.uploadTimeout),
      ),
      auth: auth,
      timeout: _config.uploadTimeout,
      label: 'POST(multipart) $path',
    );
  }

  Map<String, String> _headers({required bool auth, bool json = true}) {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.acceptLanguageHeader: _config.locale,
    };
    if (json) headers[HttpHeaders.contentTypeHeader] = 'application/json';
    if (auth) {
      final token = _readToken();
      if (token == null || token.isEmpty) {
        throw ApiException(
          kind: ApiErrorKind.unauthorized,
          message: ApiException.fallbackMessage(ApiErrorKind.unauthorized),
          statusCode: 401,
          code: 'UNAUTHENTICATED',
        );
      }
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = false,
  }) async {
    final uri = buildUri(path, query);
    final headers = _headers(auth: auth, json: body != null);
    final encoded = body == null ? null : jsonEncode(body);
    return _execute(
      () {
        switch (method) {
          case 'GET':
            return _client.get(uri, headers: headers);
          case 'POST':
            return _client.post(uri, headers: headers, body: encoded);
          case 'PUT':
            return _client.put(uri, headers: headers, body: encoded);
          case 'DELETE':
            return _client.delete(uri, headers: headers);
        }
        throw ArgumentError('Unsupported method $method');
      },
      auth: auth,
      timeout: _config.requestTimeout,
      label: '$method $path',
      retryOnce: method == 'GET',
    );
  }

  Future<ApiResponse> _execute(
    Future<http.Response> Function() run, {
    required bool auth,
    required Duration timeout,
    required String label,
    bool retryOnce = false,
  }) async {
    http.Response response;
    try {
      response = await run().timeout(timeout);
    } on Object catch (error) {
      final kind = _transportKind(error);
      if (kind == null) rethrow;
      // Reads are idempotent: one quiet retry covers flaky mobile networks.
      if (retryOnce) {
        await Future<void>.delayed(retryDelay);
        return _execute(run, auth: auth, timeout: timeout, label: label);
      }
      throw ApiException(
        kind: kind,
        message: ApiException.fallbackMessage(kind),
      );
    }
    if (logShapes) {
      debugPrint(
        '[API] $label → ${response.statusCode} '
        '${describeBody(response.bodyBytes)}',
      );
    }
    return parseResponse(response.statusCode, response.bodyBytes, auth: auth);
  }

  static ApiErrorKind? _transportKind(Object error) {
    if (error is TimeoutException) return ApiErrorKind.timeout;
    if (error is SocketException || error is http.ClientException) {
      return ApiErrorKind.network;
    }
    return null;
  }

  /// Field names and value types of a response body — never the values — so
  /// unverified contracts can be checked from a debug run without leaking
  /// personal data or tokens.
  static String describeBody(List<int> bytes) {
    try {
      return describeShape(
        jsonDecode(utf8.decode(bytes, allowMalformed: true)),
      );
    } on FormatException {
      return '<non-JSON ${bytes.length} bytes>';
    }
  }

  static String describeShape(dynamic value, [int depth = 0]) {
    if (depth > 4) return '…';
    if (value == null) return 'null';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is num) return 'num';
    if (value is String) return 'str';
    if (value is List) {
      return value.isEmpty
          ? '[]'
          : '[${value.length}× ${describeShape(value.first, depth + 1)}]';
    }
    if (value is Map) {
      final fields = value.entries
          .map((e) => '${e.key}: ${describeShape(e.value, depth + 1)}')
          .join(', ');
      return '{$fields}';
    }
    return value.runtimeType.toString();
  }

  /// Parses a raw response. Public for unit tests.
  ApiResponse parseResponse(int status, List<int> bytes, {bool auth = false}) {
    dynamic decoded;
    final text = utf8.decode(bytes, allowMalformed: true);
    if (text.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on FormatException {
        decoded = null;
      }
    }
    final map = decoded is Map<String, dynamic> ? decoded : null;
    final success = map?['success'];
    final ok = status >= 200 && status < 300 && success != false;

    if (ok) {
      if (map == null && text.trim().isNotEmpty) {
        throw ApiException(
          kind: ApiErrorKind.parsing,
          message: ApiException.fallbackMessage(ApiErrorKind.parsing),
          statusCode: status,
        );
      }
      return ApiResponse(
        data: map?['data'],
        message: map?['message']?.toString(),
        meta: map?['meta'] is Map<String, dynamic>
            ? map!['meta'] as Map<String, dynamic>
            : const {},
      );
    }

    final kind = status >= 200 && status < 300
        ? ApiErrorKind.unknown
        : ApiException.kindForStatus(status);
    final error = map?['error'] is Map<String, dynamic>
        ? map!['error'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final details = error['details'] is Map<String, dynamic>
        ? error['details'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final message = map?['message']?.toString();
    final exception = ApiException(
      kind: error['code'] == 'VALIDATION_ERROR'
          ? ApiErrorKind.validation
          : kind,
      message: (message == null || message.isEmpty)
          ? ApiException.fallbackMessage(kind)
          : message,
      statusCode: status,
      code: error['code']?.toString(),
      details: details,
    );
    if (auth && exception.isUnauthorized) onUnauthorized?.call();
    throw exception;
  }
}
