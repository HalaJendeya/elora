import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/session/session_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../shared/widgets/buttons.dart';
import 'app_routes.dart';
import 'app_nav.dart';

/// Safety net: protected routes reached without a session go to login and
/// keep the requested route as the post-login destination.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<SessionService>();
    if (session.isSignedIn || route == null) return null;
    return RouteSettings(
      name: Routes.login,
      arguments: PendingDestination(route, Get.arguments),
    );
  }
}

/// Entry point for protected navigation from guest-capable screens.
class AuthGate {
  AuthGate._();

  static bool get signedIn => Get.find<SessionService>().isSignedIn;

  /// Opens [route] when signed in, otherwise shows the "sign in required"
  /// sheet (Figma 01.06) and resumes [route] after authentication.
  static Future<void> open(String route, {dynamic arguments}) async {
    if (signedIn) {
      await Get.toNamed(route, arguments: arguments);
      return;
    }
    await showSheet(PendingDestination(route, arguments));
  }

  static Future<void> showSheet([PendingDestination? destination]) {
    return Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مساحتكِ الخاصة',
                style: AppText.eyebrow,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'سجّلي الدخول للمتابعة',
                style: AppText.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'سجّلي الدخول للوصول إلى معلومات حسابكِ ومواعيدكِ.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'تسجيل الدخول',
                onPressed: () {
                  Get.back();
                  Get.toNamed(Routes.login, arguments: destination);
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'إنشاء حساب',
                onPressed: () {
                  Get.back();
                  Get.toNamed(Routes.register, arguments: destination);
                },
              ),
              LinkButton(
                label: 'العودة إلى التصفح',
                color: AppColors.textSecondary,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }

  /// Continues to the remembered destination after sign-in, replacing the
  /// auth screen(s).
  static void resume(PendingDestination? destination) {
    // Pop auth screens back to whatever was below them.
    Get.until(
      (route) =>
          route.settings.name != Routes.login &&
          route.settings.name != Routes.register,
    );
    if (Get.currentRoute == Routes.onboarding ||
        Get.currentRoute == Routes.splash ||
        Get.currentRoute.isEmpty ||
        Get.currentRoute == '/') {
      AppNav.toMain();
    }
    if (destination != null) AppNav.open(destination);
  }
}
