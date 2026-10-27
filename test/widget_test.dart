import 'dart:convert';
import 'dart:io';

import 'package:elora/app/app.dart';
import 'package:elora/app/core/config/app_config.dart';
import 'package:elora/app/core/storage/token_storage.dart';
import 'package:elora/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

String _fixture(String name) =>
    File('test/fixtures/$name.json').readAsStringSync();

/// Serves captured public responses; everything else is 404.
final _client = MockClient((req) async {
  final p = req.url.path;
  String? body;
  if (p.endsWith('/places/elora')) body = _fixture('place');
  if (p.endsWith('/home')) body = _fixture('home');
  if (p.endsWith('/reviews')) body = _fixture('reviews');
  if (p.endsWith('/services/38')) body = _fixture('service');
  if (body != null) return http.Response.bytes(utf8.encode(body), 200);
  if (p.endsWith('/services')) {
    return http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'success': true,
          'data': [jsonDecode(_fixture('service'))['data']],
          'meta': {'page': 1, 'per_page': 15, 'total': 1, 'last_page': 1},
        }),
      ),
      200,
    );
  }
  if (p.endsWith('/categories') || p.endsWith('/staff')) {
    return http.Response.bytes(utf8.encode('{"success":true,"data":[]}'), 200);
  }
  return http.Response('{"success":false,"message":"x"}', 404);
});

Widget _app(String route) => EloraApp(
  initialRoute: route,
  binding: AppBinding(
    config: const AppConfig(
      baseUrl: 'https://example.test/api/v1',
      placeSlug: 'elora',
    ),
    client: _client,
    storage: MemoryTokenStorage(),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('ar'));
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  testWidgets('guest is redirected from a protected route to sign in', (
    tester,
  ) async {
    await tester.pumpWidget(_app(Routes.notifications));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.login);
    expect(find.text('مرحبًا بعودتكِ'), findsOneWidget);
  });

  testWidgets('login validates locally before calling the API', (tester) async {
    await tester.pumpWidget(_app(Routes.login));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first);
    await tester.pump();
    expect(find.text('يرجى إدخال البريد الإلكتروني'), findsOneWidget);
    expect(find.text('يرجى إدخال كلمة المرور'), findsOneWidget);
  });

  testWidgets('guest home renders server sections in RTL', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Routes.main));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
    expect(find.text('علاجاتنا المميزة'), findsOneWidget);
    expect(find.text('لا توجد خدمات مميزة حاليًا.'), findsOneWidget);
    expect(find.text('الأكثر طلبًا'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appointments tab asks a guest to sign in', (tester) async {
    await tester.pumpWidget(_app(Routes.main));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مواعيدي').last);
    await tester.pumpAndSettle();
    expect(find.text('سجّلي الدخول لعرض مواعيدكِ'), findsOneWidget);
  });

  testWidgets('services list survives large text on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(Routes.main));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الخدمات').last);
    await tester.pumpAndSettle();
    expect(find.text('علاج الوجه الملكي للإشراقة'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
