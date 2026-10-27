import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/place_service.dart';
import '../../core/session/session_service.dart';
import '../../core/session/unread_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/catalog.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/deep_links.dart';
import '../../routes/auth_guard.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../shell/shell.dart';
import '../../routes/app_nav.dart';

class HomeController extends GetxController {
  HomeController(this._repo, this._place, this.session);

  final CatalogRepository _repo;
  final PlaceService _place;
  final SessionService session;

  final data = Rxn<HomeData>();
  final loading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
    // Covers a session restored at launch (no sign-in event fires).
    Get.find<UnreadService>().reload();
  }

  Future<void> load() async {
    error.value = null;
    if (data.value == null) loading.value = true;
    try {
      final home = await _repo.home();
      data.value = home;
      _place.update(home.place);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  String get greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'صباح الجمال،' : 'مساء الجمال،';
  }
}

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        if (c.loading.value) return const LoadingView();
        final home = c.data.value;
        if (home == null) {
          return ErrorView(message: c.error.value ?? '', onRetry: c.load);
        }
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              _Header(home: home),
              _Categories(categories: home.categories),
              if (home.banners.isNotEmpty) _Banners(banners: home.banners),
              SectionHeading(
                eyebrow: 'اختيارات الدار',
                title: 'علاجاتنا المميزة',
                onAction: () => Get.find<ShellController>().openServices(),
              ),
              _Featured(
                services: home.featured.isNotEmpty ? home.featured : const [],
              ),
              if (home.popular.isNotEmpty) ...[
                const SectionHeading(
                  eyebrow: 'محبوبة لديكِ',
                  title: 'الأكثر طلبًا',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (final s in home.popular.take(4))
                        ServiceCard(
                          service: s,
                          onTap: () => Get.toNamed(
                            Routes.serviceDetails,
                            arguments: s.id,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              SectionHeading(
                eyebrow: 'بأيدٍ خبيرة',
                title: 'فريق ÉLORA',
                onAction: () => Get.toNamed(Routes.specialists),
              ),
              _Team(staff: home.staff),
              const SizedBox(height: 20),
              _Shortcuts(queue: home.queue),
              SectionHeading(
                eyebrow: 'من زائراتنا',
                title: 'أحدث التقييمات',
                onAction: () => Get.toNamed(Routes.reviews),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: home.latestReviews.isEmpty
                    ? const _InlineEmpty('لا توجد تقييمات منشورة بعد.')
                    : Column(
                        children: [
                          for (final r in home.latestReviews.take(3))
                            ReviewCard(review: r),
                        ],
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Header extends GetView<HomeController> {
  const _Header({required this.home});

  final HomeData home;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Obx(() {
              final user = controller.session.user.value;
              final signedIn = controller.session.isSignedIn;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signedIn ? controller.greeting : 'أهلًا بكِ في',
                    style: AppText.caption.copyWith(fontSize: 12),
                  ),
                  Text(
                    signedIn ? (user?.firstName ?? '') : 'ÉLORA',
                    style: AppText.display.copyWith(fontSize: 28, height: 1.2),
                  ),
                ],
              );
            }),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Wordmark(size: 22),
                  Obx(
                    () => controller.session.isSignedIn
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 10,
                            ),
                            child: _Bell(
                              count: Get.find<UnreadService>().count.value,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Get.toNamed(Routes.salon),
                child: StatusChip(
                  label: home.place.openNow ? 'مفتوح الآن' : 'مغلق الآن',
                  tone: home.place.openNow
                      ? StatusTone.success
                      : StatusTone.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 9 ? '9+' : '$count'),
    backgroundColor: AppColors.primary,
    child: CircleIconButton(
      icon: Icons.notifications_none_rounded,
      size: 38,
      tooltip: count > 0 ? 'الإشعارات، $count جديدة' : 'الإشعارات',
      onTap: () => Get.toNamed(Routes.notifications),
    ),
  );
}

class _Categories extends StatelessWidget {
  const _Categories({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final shell = Get.find<ShellController>();
    final items = <(String, IconData, int?)>[
      ('الكل', Icons.auto_awesome_outlined, null),
      for (final c in categories) (c.shortName, categoryIcon(c.icon), c.id),
    ];
    return SizedBox(
      // Grows with the user's text scale so labels never clip.
      height: 70 + MediaQuery.textScalerOf(context).scale(26),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final (label, icon, id) = items[i];
          final first = i == 0;
          return Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => shell.openServices(categoryId: id),
              child: SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: first ? AppColors.primary : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: first
                              ? AppColors.primary
                              : AppColors.borderSoft,
                          width: 1.3,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: first ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        fontSize: 10.5,
                        height: 1.2,
                        color: first
                            ? AppColors.primaryDeep
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Banners extends StatelessWidget {
  const _Banners({required this.banners});

  final List<HomeBanner> banners;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: PageView(
        controller: PageController(viewportFraction: 0.9),
        children: [
          for (final b in banners)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                // Only allowlisted in-app destinations; anything else is inert.
                onTap: () {
                  final dest = DeepLinks.resolve(b.url);
                  if (dest == null) return;
                  if (Routes.protected.contains(dest.route)) {
                    AuthGate.open(dest.route, arguments: dest.arguments);
                  } else {
                    AppNav.open(dest);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImage(b.image),
                      if (b.title != null)
                        Container(
                          alignment: AlignmentDirectional.bottomStart,
                          padding: const EdgeInsets.all(16),
                          color: const Color(0x55251C18),
                          child: Text(
                            b.title!,
                            style: AppText.h2.copyWith(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured({required this.services});

  final List<Service> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _InlineEmpty('لا توجد خدمات مميزة حاليًا.'),
      );
    }
    return SizedBox(
      height: 238,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (_, i) => FeaturedServiceCard(
          service: services[i],
          width: i == 0 ? 266 : 190,
          onTap: () =>
              Get.toNamed(Routes.serviceDetails, arguments: services[i].id),
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  const _Team({required this.staff});

  final List<Staff> staff;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _InlineEmpty('سيتم تعريفكِ بفريقنا قريبًا.'),
      );
    }
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: staff.length,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final s = staff[i];
          return Semantics(
            button: true,
            label: s.name,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => Get.toNamed(Routes.specialist, arguments: s.id),
              child: SizedBox(
                width: 80,
                child: Column(
                  children: [
                    PersonAvatar(
                      name: s.name,
                      imageUrl: s.avatar,
                      initials: s.initials,
                      color: s.color,
                      size: 66,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.name,
                      style: AppText.title.copyWith(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (s.title != null)
                      Text(
                        s.title!,
                        style: AppText.caption.copyWith(
                          fontSize: 10,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({this.queue});

  final QueueSummary? queue;

  @override
  Widget build(BuildContext context) {
    Widget tile(
      String eyebrow,
      String title,
      IconData icon,
      VoidCallback onTap,
    ) => Expanded(
      child: EloraCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.cardFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryDeep),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow, style: AppText.caption.copyWith(fontSize: 10)),
                  Text(
                    title,
                    style: AppText.title.copyWith(fontSize: 12.5),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              tile(
                'خططي زيارتكِ',
                'أفضل وقت للزيارة',
                Icons.insights_outlined,
                () => Get.toNamed(Routes.busyHours),
              ),
              const SizedBox(width: 10),
              tile(
                'تجارب حقيقية',
                'آراء زائراتنا',
                Icons.star_outline_rounded,
                () => Get.toNamed(Routes.reviews),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              tile(
                'ساعات العمل والسياسات',
                'معلومات الصالون',
                Icons.info_outline_rounded,
                () => Get.toNamed(Routes.salon),
              ),
              const SizedBox(width: 10),
              tile(
                queue != null && queue!.enabled && queue!.open
                    ? 'في الانتظار: ${queue!.waitingCount}'
                    : 'الدور الحي',
                'لوحة الدور',
                Icons.confirmation_number_outlined,
                () => Get.toNamed(Routes.queue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.cardFill.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text, style: AppText.caption, textAlign: TextAlign.center),
  );
}
