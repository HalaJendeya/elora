import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/catalog.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_guard.dart';
import '../../shared/controllers/load_controller.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';

class SpecialistsController extends LoadController<List<Staff>> {
  SpecialistsController(this._repo, {this.serviceId, this.serviceName});

  final CatalogRepository _repo;
  final int? serviceId;
  final String? serviceName;

  @override
  Future<List<Staff>> fetch() => _repo.staff(serviceId: serviceId);
}

class SpecialistsBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments is Map ? Get.arguments as Map : const {};
    Get.lazyPut(
      () => SpecialistsController(
        Get.find(),
        serviceId: args['serviceId'] as int?,
        serviceName: args['serviceName'] as String?,
      ),
    );
  }
}

/// Figma 03.01 / 03.02.
class SpecialistsScreen extends GetView<SpecialistsController> {
  const SpecialistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            PageTitle(
              title: 'فريق ÉLORA',
              eyebrow: controller.serviceName,
              center: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            ),
            if (controller.serviceId != null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'يعرض الفريق الذي يقدّم الخدمة المختارة.',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: LoadBuilder<List<Staff>>(
                controller: controller,
                builder: (staff) => staff.isEmpty
                    ? const EmptyView(
                        title: 'لا يوجد فريق متاح',
                        message: 'لا توجد أخصائيات لهذه الخدمة حاليًا.',
                      )
                    : RefreshIndicator(
                        onRefresh: controller.load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                            for (final s in staff)
                              StaffCard(
                                staff: s,
                                onTap: () => Get.toNamed(
                                  Routes.specialist,
                                  arguments: s.id,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecialistController extends LoadController<Staff> {
  SpecialistController(this._repo, this.staffId);

  final CatalogRepository _repo;
  final int staffId;

  @override
  Future<Staff> fetch() => _repo.staffMember(staffId);

  /// Books with this specialist pre-selected. With several services the
  /// customer first picks one.
  void book(Staff staff) {
    if (staff.services.length == 1) {
      AuthGate.open(
        Routes.booking,
        arguments: {'serviceId': staff.services.first.id, 'staffId': staff.id},
      );
      return;
    }
    Get.bottomSheet(
      SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text('اختاري الخدمة مع ${staff.name}', style: AppText.h2),
            const SizedBox(height: 12),
            for (final s in staff.services)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.name, style: AppText.bodyStrong),
                subtitle: Text(
                  Fmt.duration(s.durationMinutes, label: s.durationLabel),
                  style: AppText.caption,
                ),
                trailing: Text(
                  Fmt.price(s.finalPrice, currency()),
                  style: AppText.price.copyWith(fontSize: 15),
                ),
                onTap: () {
                  Get.back();
                  AuthGate.open(
                    Routes.booking,
                    arguments: {'serviceId': s.id, 'staffId': staff.id},
                  );
                },
              ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }
}

class SpecialistBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as int;
    Get.lazyPut(() => SpecialistController(Get.find(), id), tag: '$id');
  }
}

/// Figma 03.03 / 03.04.
class SpecialistScreen extends GetView<SpecialistController> {
  const SpecialistScreen({super.key, required this.id});

  final int id;

  @override
  String? get tag => '$id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LoadBuilder<Staff>(
          controller: controller,
          builder: (s) => Column(
            children: [
              const EloraHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: PersonAvatar(
                        name: s.name,
                        imageUrl: s.avatar,
                        initials: s.initials,
                        color: s.color,
                        size: 110,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (s.title != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          s.title!,
                          style: AppText.eyebrow,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Text(
                      s.name,
                      style: AppText.display,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: RatingLabel(
                        average: s.rating.average,
                        count: s.rating.count,
                      ),
                    ),
                    const _Divider(),
                    _Section(
                      title: 'عن ${s.name}',
                      child: Text(
                        s.bio ?? 'لم تُضف نبذة تعريفية بعد.',
                        style: AppText.body,
                      ),
                    ),
                    const _Divider(),
                    _Section(
                      title: 'ساعات العمل',
                      child: HoursTable(days: s.hours, closedLabel: 'إجازة'),
                    ),
                    const _Divider(),
                    _Section(
                      title: 'الخدمات المقدّمة',
                      child: s.services.isEmpty
                          ? const Text(
                              'لا توجد خدمات مرتبطة حاليًا.',
                              style: AppText.caption,
                            )
                          : Column(
                              children: [
                                for (final svc in s.services)
                                  EloraCard(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    onTap: () => Get.toNamed(
                                      Routes.serviceDetails,
                                      arguments: svc.id,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                svc.name,
                                                style: AppText.title,
                                              ),
                                              Text(
                                                Fmt.duration(
                                                  svc.durationMinutes,
                                                ),
                                                style: AppText.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          Fmt.price(svc.finalPrice, currency()),
                                          style: AppText.price.copyWith(
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    const _Divider(),
                    _Section(
                      title: 'أحدث التقييمات',
                      child: s.latestReviews.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.cardFill.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'لا توجد تقييمات حديثة.',
                                style: AppText.caption,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: [
                                for (final r in s.latestReviews)
                                  ReviewCard(review: r),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              if (s.services.isNotEmpty)
                SummaryBar(
                  caption: 'مع الأخصائية',
                  price: s.name,
                  button: PrimaryButton(
                    label: 'احجزي مع ${s.name}',
                    onPressed: () => controller.book(s),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h2),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Divider(),
  );
}
