import 'dart:convert';
import 'dart:io';

import 'package:elora/app/app.dart';
import 'package:elora/app/core/config/app_config.dart';
import 'package:elora/app/core/session/session_service.dart';
import 'package:elora/app/core/session/unread_service.dart';
import 'package:elora/app/core/storage/token_storage.dart';
import 'package:elora/app/data/models/account.dart';
import 'package:elora/app/features/shell/shell.dart';
import 'package:elora/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

String _fx(String name) => File('test/fixtures/$name.json').readAsStringSync();

http.Response _ok(Object? data, [Map<String, dynamic>? meta]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode({'success': true, 'data': data, 'meta': ?meta})),
      200,
    );

Map<String, dynamic> _booking(int id, {bool canReview = false}) => {
  'id': id,
  'number': 'EL-$id',
  'status': 'completed',
  'service': {'id': 38, 'name': 'خدمة $id'},
  'starts_at': '2026-10-0${id % 9 + 1}T10:00:00+03:00',
  'can_review': canReview,
};

final requests = <String>[];

final _client = MockClient((req) async {
  final p = req.url.path.replaceFirst('/api/v1/places/elora', '');
  requests.add('${req.method} $p?${req.url.query}');
  switch (p) {
    case '':
      return http.Response.bytes(utf8.encode(_fx('place')), 200);
    case '/home':
      return http.Response.bytes(utf8.encode(_fx('home')), 200);
    case '/auth/me':
      return _ok({'id': 1, 'name': 'عميلة تجريبية'});
    case '/notifications':
      return _ok([
        {'id': 'a', 'title': 'جديد', 'read_at': null},
        {'id': 'b', 'title': 'جديد 2', 'read_at': null},
        {'id': 'c', 'title': 'قديم', 'read_at': '2026-10-01'},
      ]);
    case '/bookings':
      final page = int.parse(req.url.queryParameters['page'] ?? '1');
      if (req.url.queryParameters['scope'] == 'upcoming') {
        return _ok([], {'page': 1, 'last_page': 1});
      }
      return _ok(
        page == 1
            ? [for (var i = 1; i <= 8; i++) _booking(i, canReview: i == 1)]
            : [_booking(100)],
        {'page': page, 'last_page': 2},
      );
  }
  return _ok([]);
});

Future<void> _start(
  WidgetTester tester, {
  required bool signedIn,
  int tab = 0,
}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  Get.testMode = true;
  Get.reset();
  requests.clear();
  await tester.pumpWidget(
    EloraApp(
      initialRoute: Routes.onboarding,
      binding: AppBinding(
        config: const AppConfig(
          baseUrl: 'https://example.test/api/v1',
          placeSlug: 'elora',
        ),
        client: _client,
        storage: MemoryTokenStorage(),
      ),
    ),
  );
  if (signedIn) {
    await Get.find<SessionService>().signIn(
      const AuthResult(
        token: 't',
        user: AppUser(id: 1, name: 'عميلة تجريبية'),
      ),
    );
  }
  Get.offAllNamed(Routes.main, arguments: {'tab': tab});
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('home bell shows the unread count and clears on sign-out', (
    tester,
  ) async {
    await _start(tester, signedIn: true);
    expect(Get.find<UnreadService>().count.value, 2);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await Get.find<SessionService>().signOut(remote: false);
    await tester.pumpAndSettle();
    expect(Get.find<UnreadService>().count.value, 0);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('guests get no bell and no notification request', (tester) async {
    await _start(tester, signedIn: false);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    expect(requests.where((r) => r.contains('/notifications')), isEmpty);
  });

  testWidgets(
    'past appointments page in and only reviewable visits offer a rating',
    (tester) async {
      await _start(tester, signedIn: true, tab: 2);
      await tester.tap(find.text('السابقة'));
      await tester.pumpAndSettle();
      expect(find.text('قيّمي زيارتكِ'), findsOneWidget);

      await tester.fling(
        find.byType(ListView).last,
        const Offset(0, -3000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(
        requests.any((r) => r.contains('scope=past') && r.contains('page=2')),
        isTrue,
      );
      expect(find.text('خدمة 100'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('returning to the appointments tab refreshes it', (tester) async {
    await _start(tester, signedIn: true);
    await tester.tap(find.text('مواعيدي').last);
    await tester.pumpAndSettle();
    final before = requests.where((r) => r.startsWith('GET /bookings')).length;
    await tester.tap(find.text('الرئيسية').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('مواعيدي').last);
    await tester.pumpAndSettle();
    expect(
      requests.where((r) => r.startsWith('GET /bookings')).length,
      greaterThan(before),
    );
  });

  testWidgets('logout from the profile tab leaves working tabs', (
    tester,
  ) async {
    await _start(tester, signedIn: true, tab: 3);
    await tester.ensureVisible(find.text('تسجيل الخروج').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل الخروج').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(Get.find<SessionService>().isSignedIn, isFalse);
    expect(Get.currentRoute, Routes.main);
    expect(Get.find<ShellController>().index.value, 0);
    await tester.tap(find.text('الخدمات').last);
    await tester.pumpAndSettle();
    expect(Get.find<ShellController>().index.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile shortcut to appointments switches tab in place', (
    tester,
  ) async {
    await _start(tester, signedIn: true, tab: 3);
    await tester.tap(find.text('مواعيدي').first);
    await tester.pumpAndSettle();
    expect(Get.find<ShellController>().index.value, 2);
    await tester.tap(find.text('الرئيسية').last);
    await tester.pumpAndSettle();
    expect(Get.find<ShellController>().index.value, 0);
    expect(tester.takeException(), isNull);
  });
}
