import 'package:get/get.dart';

import '../features/shell/shell.dart';
import 'app_routes.dart';

/// Navigation to the tab shell.
///
/// Never re-create the shell while one is alive: GetX deletes a route's
/// controllers by type when that route is disposed, so `offAllNamed(main)`
/// (or pushing a second shell) from inside an existing shell removes the
/// controllers the new shell is using and leaves dead, unresponsive tabs.
class AppNav {
  AppNav._();

  static bool get shellAlive => Get.isRegistered<ShellController>();

  /// Returns to the existing shell (popping anything above it) and selects
  /// [tab]; builds a fresh shell only when none exists.
  static void toMain({int? tab, bool refresh = false}) {
    if (!shellAlive) {
      Get.offAllNamed(
        Routes.main,
        arguments: tab == null ? null : {'tab': tab},
      );
      return;
    }
    Get.until((route) => route.settings.name == Routes.main);
    if (tab != null) {
      Get.find<ShellController>().select(tab, refresh: refresh);
    }
  }

  /// Opens an allowlisted destination; tab destinations reuse the shell.
  static Future<dynamic>? open(PendingDestination dest) {
    if (dest.route == Routes.main) {
      final args = dest.arguments;
      toMain(
        tab: args is Map && args['tab'] is int ? args['tab'] as int : null,
      );
      return null;
    }
    return Get.toNamed(dest.route, arguments: dest.arguments);
  }
}
