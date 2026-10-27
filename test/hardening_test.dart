import 'dart:convert';
import 'dart:io';

import 'package:elora/app/core/config/app_config.dart';
import 'package:elora/app/core/network/api_client.dart';
import 'package:elora/app/core/network/api_exception.dart';
import 'package:elora/app/data/models/account.dart';
import 'package:elora/app/data/repositories/account_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _config = AppConfig(
  baseUrl: 'https://example.test/api/v1',
  placeSlug: 'elora',
);

ApiClient _api(MockClientHandler h, {String? token = 't'}) => ApiClient(
  client: MockClient(h),
  config: _config,
  readToken: () => token,
  logShapes: false,
  retryDelay: Duration.zero,
);

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  couponAndReadAll();
  group('response shape logging', () {
    test('describes keys and types, never values', () {
      final shape = ApiClient.describeBody(
        utf8.encode(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'SECRET-TOKEN-123',
              'user': {'email': 'person@example.com', 'id': 7, 'score': 9.5},
              'items': [
                {'title': 'خاص'},
              ],
              'read_at': null,
            },
          }),
        ),
      );
      expect(shape, contains('token: str'));
      expect(shape, contains('email: str'));
      expect(shape, contains('items: [1× {title: str}]'));
      expect(shape, contains('read_at: null'));
      for (final leaked in ['SECRET', 'person@', 'خاص', '9.5']) {
        expect(shape, isNot(contains(leaked)));
      }
    });

    test('non-JSON bodies only report their size', () {
      expect(
        ApiClient.describeBody(utf8.encode('<html>')),
        '<non-JSON 6 bytes>',
      );
    });
  });

  group('retry and errors', () {
    test('GET retries once after a network failure', () async {
      var calls = 0;
      final api = _api((_) async {
        calls++;
        if (calls == 1) throw const SocketException('flaky');
        return _json({'success': true, 'data': []});
      });
      await api.get('/x');
      expect(calls, 2);
    });

    test('writes are never retried (no double booking)', () async {
      var calls = 0;
      final api = _api((_) async {
        calls++;
        throw const SocketException('down');
      });
      await expectLater(
        api.post('/bookings', auth: true),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
    });

    test('429 becomes a rate-limit error with a readable message', () async {
      final api = _api((_) async => http.Response('', 429));
      await expectLater(
        api.get('/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiErrorKind.rateLimited)
              .having((e) => e.message, 'message', contains('انتظري')),
        ),
      );
    });
  });

  group('notification shape variants', () {
    test('nested Laravel-style payload', () {
      final n = AppNotification.fromJson({
        'id': '9b1c',
        'data': {
          'title': 'تم تأكيد حجزكِ',
          'message': 'الثلاثاء 4:30',
          'url': 'bookings/12',
        },
        'read_at': null,
      });
      expect(n.title, 'تم تأكيد حجزكِ');
      expect(n.body, 'الثلاثاء 4:30');
      expect(n.url, 'bookings/12');
      expect(n.read, isFalse);
    });

    test('read-state conventions', () {
      expect(AppNotification.fromJson({'id': 1, 'is_seen': true}).read, isTrue);
      expect(
        AppNotification.fromJson({'id': 1, 'seen_at': '2026-10-01'}).read,
        isTrue,
      );
      expect(AppNotification.fromJson({'id': 1, 'unread': true}).read, isFalse);
      expect(AppNotification.fromJson({'id': 1, 'unread': false}).read, isTrue);
      expect(AppNotification.fromJson({'id': 1}).read, isFalse);
    });

    test('wrapped list, unread total and paging', () async {
      late Uri seen;
      final repo = NotificationRepository(
        _api((req) async {
          seen = req.url;
          return _json({
            'success': true,
            'data': {
              'unread_count': 12,
              'items': [
                {'id': 'a', 'title': 'x', 'read_at': null},
              ],
            },
            'meta': {'page': 2, 'last_page': 3},
          });
        }),
      );
      final (items, unread, more) = await repo.listPage(page: 2);
      expect(seen.queryParameters['page'], '2');
      expect(items.single.title, 'x');
      expect(unread, 12);
      expect(more, isTrue);
    });
  });
}

void couponAndReadAll() {
  test('COUPON_INVALID surfaces the server message', () async {
    final api = _api(
      (_) async => _json({
        'success': false,
        'message': 'رمز الكوبون غير صالح',
        'status': 422,
        'error': {'code': 'COUPON_INVALID', 'details': {}},
      }, 422),
    );
    try {
      await api.post('/coupons/check', auth: true);
      fail('should throw');
    } on ApiException catch (e) {
      expect(e.code, 'COUPON_INVALID');
      expect(e.message, 'رمز الكوبون غير صالح');
      expect(e.fieldErrors, isEmpty);
    }
  });

  test('read-all returns the server unread count', () async {
    final repo = NotificationRepository(
      _api(
        (_) async => _json({
          'success': true,
          'data': {'unread': 0},
        }),
      ),
    );
    expect(await repo.readAll(), 0);
  });
}
