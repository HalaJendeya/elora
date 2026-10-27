import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../appointments/appointments.dart';
import '../home/home.dart';
import '../profile/profile.dart';
import '../services/services_list.dart';

/// Owns the bottom-tab index. Tab controllers live as long as the shell.
class ShellController extends GetxController {
  final index = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['tab'] is int) index.value = args['tab'] as int;
  }

  /// [refresh] reloads the appointments tab even if it is already visible
  /// (e.g. right after a booking was created).
  void select(int i, {bool refresh = false}) {
    final changed = index.value != i;
    index.value = i;
    if (i == 2 && (changed || refresh)) {
      Get.find<AppointmentsController>().onShown();
    }
  }

  /// Opens the services tab, optionally pre-filtered by category.
  void openServices({int? categoryId}) {
    Get.find<ServicesController>().applyCategory(categoryId);
    index.value = 1;
  }
}

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ShellController());
    Get.lazyPut(() => HomeController(Get.find(), Get.find(), Get.find()));
    Get.lazyPut(() => ServicesController(Get.find()));
    Get.lazyPut(() => AppointmentsController(Get.find(), Get.find()));
    Get.lazyPut(() => ProfileController(Get.find()));
  }
}

class ShellScreen extends GetView<ShellController> {
  const ShellScreen({super.key});

  static const _tabs = [
    ('الرئيسية', 'tab_home'),
    ('الخدمات', 'tab_services'),
    ('مواعيدي', 'tab_appointments'),
    ('حسابي', 'tab_profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final i = controller.index.value;
      return PopScope(
        canPop: i == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.select(0);
        },
        child: Scaffold(
          body: IndexedStack(
            index: i,
            children: const [
              HomeView(),
              ServicesView(),
              AppointmentsView(),
              ProfileView(),
            ],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xF5FFFFFF),
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 1.3),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    for (var t = 0; t < _tabs.length; t++)
                      Expanded(
                        child: Semantics(
                          selected: t == i,
                          button: true,
                          label: _tabs[t].$1,
                          excludeSemantics: true,
                          child: InkWell(
                            onTap: () => controller.select(t),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppIcon(
                                  _tabs[t].$2,
                                  size: 21,
                                  color: t == i
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _tabs[t].$1,
                                  style: AppText.caption.copyWith(
                                    fontSize: 10.5,
                                    color: t == i
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
