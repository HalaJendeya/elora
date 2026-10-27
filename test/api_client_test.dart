import 'dart:convert';
import 'dart:io';

import 'package:elora/app/core/config/app_config.dart';
import 'package:elora/app/core/network/api_client.dart';
import 'package:elora/app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _config = AppConfig(
  baseUrl: 'https://example.test/api/v1',
  placeSlug: 'elora',
  requestTimeout: Duration(milliseconds: 200),
);

ApiClient _client(
  MockClientHandler handler, {
  String? token,
  void Function()? onUnauthorized,
}) => ApiClient(
  client: MockClient(handler),
  config: _config,
  readToken: () => token,
  onUnauthorized: onUnauthorized,
);

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('request building', () {
    test('place paths, headers and query encoding', () async {
      late http.Request seen;
      final api = _client((req) async {
        seen = req;
        return _json({'success': true, 'data': []});
      });
      await api.get(
        api.place('services'),
        query: {
          'q': 'قص شعر',
          'category_id': null,
          'featured': true,
          'empty': '',
          'page': 2,
        },
      );
      expect(seen.url.path, '/api/v1/places/elora/services');
      expect(seen.url.queryParameters, {
        'q': 'قص شعر',
        'featured': '1',
        'page': '2',
      });
      expect(seen.headers[HttpHeaders.acceptHeader], 'application/json');
      expect(seen.headers[HttpHeaders.acceptLanguageHeader], 'ar');
      expect(
        seen.headers.containsKey(HttpHeaders.authorizationHeader),
        isFalse,
      );
    });

    test('adds bearer token on protected requests', () async {
      late http.Request seen;
      final api = _client((req) async {
        seen = req;
        return _json({'success': true, 'data': {}});
      }, token: 'abc');
      await api.post(api.place('bookings'), auth: true, body: {'x': 1});
      expect(seen.headers[HttpHeaders.authorizationHeader], 'Bearer abc');
      expect(jsonDecode(seen.body), {'x': 1});
    });

    test(
      'protected request without a token fails locally, no network',
      () async {
        var called = false;
        final api = _client((req) async {
          called = true;
          return _json({});
        });
        await expectLater(
          api.get(api.place('auth/me'), auth: true),
          throwsA(
            isA<ApiException>().having(
              (e) => e.kind,
              'kind',
              ApiErrorKind.unauthorized,
            ),
          ),
        );
        expect(called, isFalse);
      },
    );
  });

  group('response parsing', () {
    test('decodes UTF-8 Arabic and exposes data/meta', () async {
      final api = _client(
        (_) async => _json({
          'success': true,
          'message': 'تم بنجاح',
          'data': [
            {'name': 'علاج الوجه'},
          ],
          'meta': {'page': 1, 'last_page': 3},
        }),
      );
      final res = await api.get('/ping');
      expect(res.message, 'تم بنجاح');
      expect(res.dataList.single['name'], 'علاج الوجه');
      expect(res.meta['last_page'], 3);
    });

    test('422 maps field errors', () async {
      final api = _client(
        (_) async => _json({
          'success': false,
          'message': 'البيانات المدخلة غير صحيحة',
          'status': 422,
          'error': {
            'code': 'VALIDATION_ERROR',
            'details': {
              'email': [
                'يجب أن يكون البريد الإلكتروني بريدًا إلكترونيًا صحيحًا.',
              ],
              'password': ['حقل كلمة المرور مطلوب.'],
            },
          },
        }, 422),
      );
      try {
        await api.post(api.place('auth/login'), body: {});
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.isValidation, isTrue);
        expect(e.fieldErrors.keys, containsAll(['email', 'password']));
        expect(e.message, 'البيانات المدخلة غير صحيحة');
      }
    });

    test('business error codes and details are preserved', () async {
      final api = _client(
        (_) async => _json({
          'success': false,
          'message': 'الوقت لم يعد متاحًا',
          'error': {
            'code': 'SLOT_UNAVAILABLE',
            'details': {
              'alternatives': [
                {'time': '10:00', 'starts_at': '2026-10-20T10:00:00+03:00'},
              ],
            },
          },
        }, 409),
        token: 't',
      );
      try {
        await api.post(api.place('bookings'), auth: true);
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.hasCode('SLOT_UNAVAILABLE'), isTrue);
        expect(e.details['alternatives'], isA<List>());
      }
    });

    test('success:false with 200 is still an error', () async {
      final api = _client(
        (_) async => _json({'success': false, 'message': 'لا'}),
      );
      expect(api.get('/x'), throwsA(isA<ApiException>()));
    });

    test('non-JSON error body falls back to a readable message', () async {
      final api = _client((_) async => http.Response('<html>502</html>', 502));
      await expectLater(
        api.get('/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.server)
              .having((e) => e.message, 'message', isNotEmpty),
        ),
      );
    });

    test(
      '401 on a protected call notifies the session; public 401 does not',
      () async {
        var hits = 0;
        final api = _client(
          (_) async => _json({
            'success': false,
            'message': 'يجب تسجيل الدخول أولًا',
            'error': {'code': 'UNAUTHENTICATED', 'details': {}},
          }, 401),
          token: 'expired',
          onUnauthorized: () => hits++,
        );
        await expectLater(
          api.get('/a', auth: true),
          throwsA(isA<ApiException>()),
        );
        expect(hits, 1);
        await expectLater(api.post('/login'), throwsA(isA<ApiException>()));
        expect(hits, 1);
      },
    );
  });

  group('transport failures', () {
    test('timeout', () async {
      final api = _client(
        (_) => Future.delayed(const Duration(seconds: 2), () => _json({})),
      );
      await expectLater(
        api.get('/slow'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.timeout,
          ),
        ),
      );
    });

    test('network', () async {
      final api = _client((_) => throw const SocketException('offline'));
      await expectLater(
        api.get('/x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.network,
          ),
        ),
      );
    });
  });
}
