import 'dart:convert';
import 'dart:io';

import 'package:elora/app/app.dart';
import 'package:elora/app/core/config/app_config.dart';
import 'package:elora/app/core/session/session_service.dart';
import 'package:elora/app/core/storage/token_storage.dart';
import 'package:elora/app/data/models/account.dart';
import 'package:elora/app/features/appointments/appointments.dart';
import 'package:elora/app/features/shell/shell.dart';
import 'package:elora/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

String _fx(String name) => File('test/fixtures/$name.json').readAsStringSync();

http.Response _ok(Object? data) => http.Response.bytes(
  utf8.encode(
    jsonEncode({'success': true, 'message': 'تم الحجز', 'data': data}),
  ),
  201,
);

/// Drives the real booking flow end to end against a mock backend and
/// returns the requests the app sent.
Future<List<http.Request>> _book(
  WidgetTester tester,
  Object? createdBooking,
) async {
  final sent = <http.Request>[];
  final client = MockClient((req) async {
    sent.add(req);
    final p = req.url.path.replaceFirst('/api/v1/places/elora', '');
    switch (p) {
      case '':
        return http.Response.bytes(utf8.encode(_fx('place')), 200);
      case '/home':
        return http.Response.bytes(utf8.encode(_fx('home')), 200);
      case '/services/38':
        return http.Response.bytes(utf8.encode(_fx('service')), 200);
      case '/staff':
        return _ok(jsonDecode(_fx('home'))['data']['staff']);
      case '/availability/days':
        return http.Response.bytes(utf8.encode(_fx('days')), 200);
      case '/availability/slots':
        return http.Response.bytes(utf8.encode(_fx('slots')), 200);
      case '/auth/me':
        return _ok({'id': 1, 'name': 'عميلة تجريبية'});
      case '/bookings':
        if (req.method == 'POST') return _ok(createdBooking);
        return _ok([]);
    }
    return http.Response('{"success":true,"data":[]}', 200);
  });

  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  Get.testMode = true;
  Get.reset();
  await tester.pumpWidget(
    EloraApp(
      initialRoute: Routes.main,
      binding: AppBinding(
        config: const AppConfig(
          baseUrl: 'https://example.test/api/v1',
          placeSlug: 'elora',
        ),
        client: client,
        storage: MemoryTokenStorage(),
      ),
    ),
  );
  await Get.find<SessionService>().signIn(
    const AuthResult(
      token: 't',
      user: AppUser(id: 1, name: 'عميلة تجريبية'),
    ),
  );
  await tester.pumpAndSettle();
  Get.toNamed(Routes.booking, arguments: {'serviceId': 38, 'staffId': 22});
  await tester.pumpAndSettle();

  Future<void> next() async {
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
  }

  await next(); // step 1 → 2
  await tester.tap(find.text('10:00 ص').first);
  await tester.pumpAndSettle();
  await next(); // step 2 → 3
  final policy = find.byType(CheckboxListTile);
  await tester.ensureVisible(policy);
  await tester.pumpAndSettle();
  await tester.tap(policy);
  await tester.pumpAndSettle();
  await next(); // step 3 → 4
  await tester.tap(find.text('تأكيد الموعد'));
  await tester.pumpAndSettle();
  return sent;
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('confirmed booking opens the success screen', (tester) async {
    final sent = await _book(tester, {
      'id': 77,
      'number': 'EL-TEST-77',
      'code': 'ABCD',
      'status': 'confirmed',
      'starts_at': '2026-10-20T10:00:00+03:00',
    });
    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, Routes.bookingSuccess);
    expect(find.text('موعدكِ بانتظاركِ'), findsOneWidget);
    final create = sent.singleWhere(
      (r) => r.method == 'POST' && r.url.path.endsWith('/bookings'),
    );
    final body = jsonDecode(create.body) as Map<String, dynamic>;
    expect(body['starts_at'], '2026-10-20T10:00:00+03:00');
    expect(body['staff_id'], 22);
    expect(body['payment_method'], 'cash');
  });

  testWidgets('success screen survives an unexpected create response', (
    tester,
  ) async {
    // e.g. the booking wrapped in another object and a huge inline QR image.
    await _book(tester, {
      'booking': {'id': 78},
      'qr': 'data:image/png;base64,${'A' * 5000}',
      'staff': 'صوفيا',
      'service': 'علاج',
    });
    expect(tester.takeException(), isNull);
    expect(find.text('موعدكِ بانتظاركِ'), findsOneWidget);
  });

  testWidgets('leaving the success screen for the appointment does not throw', (
    tester,
  ) async {
    await _book(tester, {
      'id': 79,
      'number': 'EL-79',
      'starts_at': '2026-10-20T10:00:00+03:00',
    });
    await tester.tap(find.text('عرض تفاصيل الموعد'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, Routes.appointment);
  });

  /// Regression: returning to the tabs after a booking must leave a working
  /// shell (live report: the app froze after booking).
  Future<void> expectTabsWork(WidgetTester tester) async {
    expect(Get.isRegistered<ShellController>(), isTrue);
    await tester.tap(find.text('مواعيدي').last);
    await tester.pumpAndSettle();
    expect(Get.find<ShellController>().index.value, 2);
    expect(Get.isRegistered<AppointmentsController>(), isTrue);
    await tester.tap(find.text('الرئيسية').last);
    await tester.pumpAndSettle();
    expect(Get.find<ShellController>().index.value, 0);
    expect(tester.takeException(), isNull);
  }

  testWidgets('"back to home" after booking keeps the tabs working', (
    tester,
  ) async {
    await _book(tester, {
      'id': 80,
      'number': 'EL-80',
      'starts_at': '2026-10-20T10:00:00+03:00',
    });
    await tester.tap(find.text('العودة إلى الرئيسية'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.main);
    await expectTabsWork(tester);
  });

  testWidgets('system back after booking keeps the tabs working', (
    tester,
  ) async {
    await _book(tester, {
      'id': 81,
      'number': 'EL-81',
      'starts_at': '2026-10-20T10:00:00+03:00',
    });
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.main);
    await expectTabsWork(tester);
  });

  testWidgets('appointment opened from success returns to working tabs', (
    tester,
  ) async {
    await _book(tester, {
      'id': 82,
      'number': 'EL-82',
      'starts_at': '2026-10-20T10:00:00+03:00',
    });
    await tester.tap(find.text('عرض تفاصيل الموعد'));
    await tester.pumpAndSettle();
    Get.back();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.main);
    expect(Get.find<ShellController>().index.value, 2);
    await expectTabsWork(tester);
  });
}
