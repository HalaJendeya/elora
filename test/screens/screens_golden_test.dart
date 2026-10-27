// Renders key screens with the real fonts at 390×844 for visual comparison
// with Figma. Protected screens use clearly fake fixture data (not live API
// results). Regenerate with:
//   flutter test --update-goldens test/screens
@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:elora/app/app.dart';
import 'package:elora/app/core/config/app_config.dart';
import 'package:elora/app/core/session/session_service.dart';
import 'package:elora/app/core/storage/token_storage.dart';
import 'package:elora/app/data/models/account.dart';
import 'package:elora/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

String _fx(String name) => File('test/fixtures/$name.json').readAsStringSync();

http.Response _ok(Object? data, [Map<String, dynamic>? meta]) =>
    http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'success': true,
          'message': 'ok',
          'data': data,
          'meta': ?meta,
        }),
      ),
      200,
    );

final _booking = {
  'id': 901,
  'number': 'EL-TEST-01',
  'code': 'TEST-CODE',
  'status': 'confirmed',
  'service': {'id': 38, 'name': 'علاج الوجه الملكي للإشراقة'},
  'staff': {'id': 22, 'name': 'صوفيا'},
  'starts_at': '2026-10-20T16:30:00+03:00',
  'duration_minutes': 60,
  'final_price': 150,
  'can_cancel': true,
  'can_reschedule': true,
  'cancel_is_late': true,
  'timeline': [
    {'label': 'تم تأكيد الموعد', 'done': true, 'at_human': 'اليوم 9:12 ص'},
    {'label': 'بانتظار موعدكِ', 'current': true, 'at_human': 'الثلاثاء 4:30 م'},
    {'label': 'تسجيل الوصول'},
  ],
};

/// Serve the sanitized live /auth/me shape instead of the hand-written one.
bool _liveProfile = false;

final _client = MockClient((req) async {
  final p = req.url.path.replaceFirst('/api/v1/places/elora', '');
  switch (p) {
    case '':
      return http.Response.bytes(utf8.encode(_fx('place')), 200);
    case '/home':
      return http.Response.bytes(utf8.encode(_fx('home')), 200);
    case '/services/38':
      return http.Response.bytes(utf8.encode(_fx('service')), 200);
    case '/reviews':
      return http.Response.bytes(utf8.encode(_fx('reviews')), 200);
    case '/insights/busy-hours':
      return http.Response.bytes(utf8.encode(_fx('busy_hours')), 200);
    case '/availability/days':
      return http.Response.bytes(utf8.encode(_fx('days')), 200);
    case '/availability/slots':
      return http.Response.bytes(utf8.encode(_fx('slots')), 200);
    case '/services':
      return _ok(
        [jsonDecode(_fx('service'))['data']],
        {'page': 1, 'per_page': 15, 'total': 1, 'last_page': 1},
      );
    case '/categories':
      return _ok(jsonDecode(_fx('home'))['data']['categories']);
    case '/staff':
      return _ok(jsonDecode(_fx('home'))['data']['staff']);
    case '/auth/me':
      if (_liveProfile) {
        return _ok(jsonDecode(_fx('private_sanitized'))['me']['data']);
      }
      return _ok({
        'id': 1,
        'name': 'عميلة تجريبية',
        'email': 'test@example.com',
        'phone': '0590000000',
        'reliability': {'score': 92, 'label': 'موثوقية ممتازة'},
      });
    case '/bookings':
      return _ok([_booking], {'page': 1, 'last_page': 1, 'total': 1});
    case '/bookings/901':
      return _ok(_booking);
    case '/bookings/777':
      // Live-shaped booking (sanitized capture of the real API).
      return _ok(
        (jsonDecode(_fx('private_sanitized'))['upcoming']['data'] as List)
            .first,
      );
    case '/queue':
      return _ok({
        'enabled': true,
        'open': true,
        'accepting': true,
        'now_serving': ['A-004'],
        'waiting_count': 6,
        'estimated_wait_minutes': 25,
      });
    case '/queue/my-ticket':
      return _ok(null);
    case '/waitlist/5':
      return _ok({
        'id': 5,
        'status': 'offered',
        'service': {'id': 38, 'name': 'علاج الوجه الملكي للإشراقة'},
        'date': '2026-10-21',
        'from_time': '16:00',
        'to_time': '20:00',
        'offer': {'time': '16:30', 'seconds_left': 582},
      });
    case '/notifications':
      return _ok([
        {
          'id': 'n1',
          'title': 'تم تأكيد حجزكِ',
          'body': 'علاج الوجه الملكي · الثلاثاء 4:30 م',
          'url': 'bookings/901',
          'read_at': null,
          'type': 'booking',
        },
        {
          'id': 'n2',
          'title': 'موعد متاح لكِ',
          'body': 'أصبح موعد متاحًا من قائمة الانتظار.',
          'url': 'waitlist/5',
          'read_at': '2026-10-17',
          'type': 'waitlist',
        },
      ]);
  }
  return http.Response('{"success":false,"message":"not found"}', 404);
});

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
  }

  await family('IBMPlexSansArabic', [
    'IBMPlexSansArabic-Regular.ttf',
    'IBMPlexSansArabic-Medium.ttf',
    'IBMPlexSansArabic-SemiBold.ttf',
    'IBMPlexSansArabic-Bold.ttf',
  ]);
  await family('Amiri', ['Amiri-Regular.ttf', 'Amiri-Bold.ttf']);
  await family('Gelasio', [
    'Gelasio-Variable.ttf',
    'Gelasio-Italic-Variable.ttf',
  ]);
  // Material icons for chevrons, stars, etc.
  final icons = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  String route, {
  dynamic arguments,
  bool signedIn = false,
  bool settle = true,
  Future<void> Function()? interact,
}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  Get.testMode = true;
  Get.reset();
  final storage = MemoryTokenStorage();
  if (signedIn) storage.value = 'test-token';
  await tester.pumpWidget(
    EloraApp(
      initialRoute: Routes.onboarding,
      binding: AppBinding(
        config: const AppConfig(
          baseUrl: 'https://example.test/api/v1',
          placeSlug: 'elora',
        ),
        client: _client,
        storage: storage,
      ),
    ),
  );
  if (signedIn) {
    await Get.find<SessionService>().signIn(
      const AuthResult(
        token: 'test-token',
        user: AppUser(id: 1, name: 'عميلة تجريبية'),
      ),
    );
  }
  Get.offAllNamed(route, arguments: arguments);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  if (interact != null) {
    await interact();
    await tester.pumpAndSettle();
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await _loadFonts();
  });

  testWidgets(
    '01.02 welcome',
    (t) => _shot(t, '01_02_welcome', Routes.onboarding),
  );
  testWidgets('01.03 sign in', (t) => _shot(t, '01_03_sign_in', Routes.login));
  testWidgets(
    '01.04 sign in errors',
    (t) => _shot(
      t,
      '01_04_sign_in_errors',
      Routes.login,
      interact: () async {
        await t.tap(find.byType(FilledButton).first);
      },
    ),
  );
  testWidgets(
    '01.05 register',
    (t) => _shot(t, '01_05_register', Routes.register),
  );
  testWidgets('01.07 salon', (t) => _shot(t, '01_07_salon', Routes.salon));
  testWidgets(
    '02.02 home guest',
    (t) => _shot(t, '02_02_home_guest', Routes.main),
  );
  testWidgets(
    '02.03 services',
    (t) => _shot(t, '02_03_services', Routes.main, arguments: {'tab': 1}),
  );
  testWidgets(
    '02.06 filter sheet',
    (t) => _shot(
      t,
      '02_06_filters',
      Routes.main,
      arguments: {'tab': 1},
      interact: () async {
        await t.tap(find.byIcon(Icons.tune_rounded));
      },
    ),
  );
  testWidgets(
    '02.09 service details',
    (t) =>
        _shot(t, '02_09_service_details', Routes.serviceDetails, arguments: 38),
  );
  testWidgets(
    '03.01 specialists',
    (t) => _shot(t, '03_01_specialists', Routes.specialists),
  );
  testWidgets(
    '03.05 busy hours',
    (t) => _shot(t, '03_05_busy_hours', Routes.busyHours),
  );
  testWidgets(
    '04.02 reviews empty',
    (t) => _shot(t, '04_02_reviews_empty', Routes.reviews),
  );
  testWidgets(
    '05.01 booking step 1',
    (t) => _shot(
      t,
      '05_01_booking_staff',
      Routes.booking,
      arguments: {'serviceId': 38},
      signedIn: true,
    ),
  );
  testWidgets(
    '05.02 booking step 2',
    (t) => _shot(
      t,
      '05_02_booking_time',
      Routes.booking,
      arguments: {'serviceId': 38, 'staffId': 22},
      signedIn: true,
      interact: () async {
        await t.tap(find.text('متابعة'));
        await t.pumpAndSettle();
        await t.tap(find.text('10:00 ص').first);
      },
    ),
  );
  testWidgets(
    '06.01 appointments',
    (t) => _shot(
      t,
      '06_01_appointments',
      Routes.main,
      arguments: {'tab': 2},
      signedIn: true,
    ),
  );
  testWidgets(
    '06.02b appointment details (live shape)',
    (t) => _shot(
      t,
      '06_02b_appointment_live',
      Routes.appointment,
      arguments: {'id': 777},
      signedIn: true,
    ),
  );
  testWidgets('09.01b profile (live shape)', (t) async {
    _liveProfile = true;
    addTearDown(() => _liveProfile = false);
    await _shot(
      t,
      '09_01b_profile_live',
      Routes.main,
      arguments: {'tab': 3},
      signedIn: true,
    );
  });
  testWidgets(
    '06.02 appointment details',
    (t) => _shot(
      t,
      '06_02_appointment',
      Routes.appointment,
      arguments: {'id': 901},
      signedIn: true,
    ),
  );
  testWidgets(
    '07.04 waitlist offer',
    (t) => _shot(
      t,
      '07_04_waitlist_offer',
      Routes.waitlistEntry,
      arguments: 5,
      signedIn: true,
      settle: false,
    ),
  );
  testWidgets(
    '08.01 queue board',
    (t) => _shot(t, '08_01_queue', Routes.queue, settle: false),
  );
  testWidgets(
    '09.01 profile',
    (t) => _shot(
      t,
      '09_01_profile',
      Routes.main,
      arguments: {'tab': 3},
      signedIn: true,
    ),
  );
  testWidgets(
    '10.01 notifications',
    (t) =>
        _shot(t, '10_01_notifications', Routes.notifications, signedIn: true),
  );
}
