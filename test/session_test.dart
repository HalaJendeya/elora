import 'dart:async';
import 'dart:convert';

import 'package:elora/app/app.dart';
import 'package:elora/app/core/config/app_config.dart';
import 'package:elora/app/core/network/api_client.dart';
import 'package:elora/app/core/session/session_service.dart';
import 'package:elora/app/core/storage/token_storage.dart';
import 'package:elora/app/data/models/account.dart';
import 'package:elora/app/shared/controllers/load_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

class _SlowPrivate extends LoadController<String> {
  _SlowPrivate(this.gate);

  final Completer<String> gate;

  @override
  bool get private => true;

  @override
  Future<String> fetch() => gate.future;
}

void main() {
  late MemoryTokenStorage storage;
  late SessionService session;
  late List<String> calls;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    calls = [];
    storage = MemoryTokenStorage();
    final client = MockClient((req) async {
      calls.add('${req.method} ${req.url.path}');
      if (req.url.path.endsWith('/auth/me')) {
        return req.headers['authorization'] == 'Bearer good'
            ? _json({
                'success': true,
                'data': {'id': 1, 'name': 'ليان', 'reliability': 90},
              })
            : _json({
                'success': false,
                'error': {'code': 'UNAUTHENTICATED'},
              }, 401);
      }
      return _json({'success': true, 'data': null});
    });
    AppBinding(
      config: const AppConfig(
        baseUrl: 'https://example.test/api/v1',
        placeSlug: 'elora',
      ),
      client: client,
      storage: storage,
    ).dependencies();
    session = Get.find<SessionService>();
  });

  tearDown(Get.reset);

  test('sign in persists token, sign out clears every private trace', () async {
    final before = session.epoch;
    await session.signIn(
      const AuthResult(
        token: 'good',
        user: AppUser(id: 1, name: 'ليان'),
      ),
    );
    expect(storage.value, 'good');
    expect(session.isSignedIn, isTrue);
    expect(session.epoch, before + 1);

    await session.signOut();
    expect(storage.value, isNull);
    expect(session.token, isNull);
    expect(session.user.value, isNull);
    expect(session.isSignedIn, isFalse);
    expect(calls, contains('POST /api/v1/places/elora/auth/logout'));
  });

  test('restored but revoked token is dropped after a 401', () async {
    storage.value = 'revoked';
    await session.restore();
    expect(session.isSignedIn, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(session.isSignedIn, isFalse);
    expect(storage.value, isNull);
  });

  test('a private response from an earlier session is discarded', () async {
    await session.signIn(
      const AuthResult(
        token: 'good',
        user: AppUser(id: 1, name: 'ليان'),
      ),
    );
    final gate = Completer<String>();
    final c = _SlowPrivate(gate)..onInit();
    await session.signOut();
    gate.complete('private appointments of previous user');
    await Future<void>.delayed(Duration.zero);
    expect(c.data.value, isNull);
  });

  test('api client never sends a token after sign out', () async {
    await session.signIn(
      const AuthResult(
        token: 'good',
        user: AppUser(id: 1, name: 'ليان'),
      ),
    );
    await session.signOut();
    final api = Get.find<ApiClient>();
    expect(() => api.get('/x', auth: true), throwsA(anything));
  });
}
