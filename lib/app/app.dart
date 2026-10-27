import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/session/place_service.dart';
import 'core/session/session_service.dart';
import 'core/session/unread_service.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'shared/widgets/display.dart';

/// App-lifetime dependencies only: one http.Client, the API client, session,
/// public salon config and stateless repositories. Screen controllers are
/// created by their route bindings.
class AppBinding extends Bindings {
  AppBinding({this.config, this.client, this.storage});

  final AppConfig? config;
  final http.Client? client;
  final TokenStorage? storage;

  @override
  void dependencies() {
    final cfg = config ?? AppConfig.fromEnvironment();
    final session = Get.put(
      SessionService(storage ?? SecureTokenStorage()),
      permanent: true,
    );
    final api = Get.put(
      ApiClient(
        client: client ?? http.Client(),
        config: cfg,
        readToken: () => session.token,
        onUnauthorized: () {
          if (session.token == null) return;
          session.handleUnauthorized();
          showMessage('انتهت جلستكِ. سجّلي الدخول مجددًا للمتابعة.');
        },
      ),
      permanent: true,
    );
    final auth = Get.put(AuthRepository(api), permanent: true);
    session.attach(auth);
    final catalog = Get.put(CatalogRepository(api), permanent: true);
    Get.put(BookingRepository(api), permanent: true);
    Get.put(WaitlistRepository(api), permanent: true);
    Get.put(QueueRepository(api), permanent: true);
    final notifications = Get.put(NotificationRepository(api), permanent: true);
    Get.put(UnreadService(notifications, session), permanent: true);
    Get.put(PlaceService(catalog), permanent: true);
  }
}

class EloraApp extends StatelessWidget {
  const EloraApp({super.key, this.binding, this.initialRoute = Routes.splash});

  final Bindings? binding;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ÉLORA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialBinding: binding ?? AppBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      builder: (context, child) {
        // Respect user text scaling, but cap it so dense booking layouts
        // stay usable.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
