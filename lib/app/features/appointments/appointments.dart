import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_guard.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../shared/widgets/form_fields.dart';

StatusTone bookingTone(String status) => switch (status) {
  'confirmed' ||
  'checked_in' ||
  'arrived' ||
  'in_progress' => StatusTone.success,
  'completed' => StatusTone.neutral,
  'cancelled' || 'no_show' || 'rejected' => StatusTone.accent,
  _ => StatusTone.warning,
};

String bookingStatusLabel(Booking b) =>
    b.statusLabel ??
    switch (b.status) {
      'confirmed' => 'مؤكد',
      'pending' => 'بانتظار التأكيد',
      'completed' => 'مكتمل',
      'cancelled' => 'ملغي',
      'no_show' => 'لم تحضري',
      'checked_in' => 'تم تسجيل الوصول',
      _ => b.status,
    };

/// Upcoming / past tab. Private data: reset whenever the session changes.
class AppointmentsController extends GetxController {
  AppointmentsController(this._repo, this._session);

  final BookingRepository _repo;
  final SessionService _session;

  final tab = 0.obs;
  final upcoming = <Booking>[].obs;
  final past = <Booking>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final loaded = <int>{};
  final loadingMore = false.obs;
  final _pages = <int, int>{};
  final _lastPages = <int, int>{};
  Worker? _sessionWorker;

  bool hasMore(int tab) => (_pages[tab] ?? 1) < (_lastPages[tab] ?? 1);

  bool get signedIn => _session.isSignedIn;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_session.epochStream, (_) {
      upcoming.clear();
      past.clear();
      loaded.clear();
      _pages.clear();
      _lastPages.clear();
      error.value = null;
      if (_session.isSignedIn) load();
    });
    if (signedIn) load();
  }

  void switchTab(int i) {
    tab.value = i;
    if (!loaded.contains(i)) load();
  }

  Future<void> load() async {
    if (!signedIn) return;
    final i = tab.value;
    final epoch = _session.epoch;
    loading.value = true;
    error.value = null;
    try {
      final page = await _repo.list(upcoming: i == 0);
      if (!_session.isCurrent(epoch)) return;
      (i == 0 ? upcoming : past).assignAll(page.items);
      _pages[i] = page.meta.page;
      _lastPages[i] = page.meta.lastPage;
      loaded.add(i);
    } on ApiException catch (e) {
      if (_session.isCurrent(epoch)) error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  /// Next page for the visible tab; failures keep what is shown.
  Future<void> loadMore() async {
    final i = tab.value;
    if (!signedIn || loading.value || loadingMore.value || !hasMore(i)) return;
    final epoch = _session.epoch;
    loadingMore.value = true;
    try {
      final page = await _repo.list(
        upcoming: i == 0,
        page: (_pages[i] ?? 1) + 1,
      );
      if (!_session.isCurrent(epoch)) return;
      final list = i == 0 ? upcoming : past;
      final known = list.map((b) => b.id).toSet();
      list.addAll(page.items.where((b) => !known.contains(b.id)));
      _pages[i] = page.meta.page;
      _lastPages[i] = page.meta.lastPage;
    } on ApiException {
      // Scrolling again retries.
    } finally {
      loadingMore.value = false;
    }
  }

  /// Called when the tab becomes visible again: bookings change elsewhere
  /// (new booking, cancellation, check-in), so refresh silently.
  void onShown() {
    if (signedIn && !loading.value) load();
  }

  Future<void> review(Booking b) async {
    final done = await Get.toNamed(Routes.submitReview, arguments: b);
    if (done == true) load();
  }

  Future<void> open(Booking b) async {
    final changed = await Get.toNamed(
      Routes.appointment,
      arguments: {'id': b.id},
    );
    if (changed == true) {
      loaded.clear();
      load();
    }
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    super.onClose();
  }
}

/// Figma 06.01.
class AppointmentsView extends GetView<AppointmentsController> {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const EloraHeader(showBack: false),
          const PageTitle(
            eyebrow: 'كل شيء في مكانه',
            title: 'مواعيدي',
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
          ),
          Expanded(
            child: Obx(() {
              if (!Get.find<SessionService>().isSignedIn) {
                return EmptyView(
                  icon: Icons.lock_outline_rounded,
                  title: 'سجّلي الدخول لعرض مواعيدكِ',
                  message: 'احجزي وتابعي مواعيدكِ من مكان واحد.',
                  actionLabel: 'تسجيل الدخول',
                  onAction: () => AuthGate.showSheet(),
                );
              }
              final list = c.tab.value == 0 ? c.upcoming : c.past;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SegmentedPills(
                      labels: [
                        c.upcoming.isEmpty
                            ? 'القادمة'
                            : 'القادمة (${c.upcoming.length})',
                        'السابقة',
                      ],
                      index: c.tab.value,
                      onChanged: c.switchTab,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: c.loading.value && list.isEmpty
                        ? const SingleChildScrollView(
                            child: SkeletonList(height: 120),
                          )
                        : c.error.value != null && list.isEmpty
                        ? ErrorView(message: c.error.value!, onRetry: c.load)
                        : RefreshIndicator(
                            onRefresh: c.load,
                            child: list.isEmpty
                                ? ListView(
                                    children: [
                                      EmptyView(
                                        icon: Icons.event_available_outlined,
                                        title: c.tab.value == 0
                                            ? 'لا مواعيد قادمة'
                                            : 'لا مواعيد سابقة',
                                        message: c.tab.value == 0
                                            ? 'اكتشفي خدماتنا واحجزي تجربتكِ القادمة.'
                                            : null,
                                      ),
                                    ],
                                  )
                                : NotificationListener<ScrollNotification>(
                                    onNotification: (n) {
                                      if (n.metrics.extentAfter < 300) {
                                        c.loadMore();
                                      }
                                      return false;
                                    },
                                    child: ListView(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        20,
                                        24,
                                      ),
                                      children: [
                                        for (final b in list)
                                          _AppointmentCard(
                                            booking: b,
                                            onTap: () => c.open(b),
                                            onReview: b.canReview
                                                ? () => c.review(b)
                                                : null,
                                          ),
                                        if (c.loadingMore.value)
                                          const LoadingView(),
                                      ],
                                    ),
                                  ),
                          ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.booking,
    required this.onTap,
    this.onReview,
  });

  final Booking booking;
  final VoidCallback onTap;

  /// Shown only when the server marks the visit reviewable (`can_review`).
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final d = booking.startsAt;
    return EloraCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 62,
              decoration: BoxDecoration(
                color: AppColors.cardFill,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    Fmt.monthShort(d),
                    style: AppText.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  Text(
                    '${d?.day ?? ''}',
                    style: const TextStyle(
                      fontFamily: AppText.latin,
                      fontSize: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    Fmt.weekday(d),
                    style: AppText.caption.copyWith(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.displayNumber,
                          style: AppText.caption.copyWith(fontSize: 10),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.serviceName ?? '',
                          style: AppText.title,
                        ),
                      ),
                      StatusChip(
                        label: bookingStatusLabel(booking),
                        tone: bookingTone(booking.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(Fmt.clock(d), style: AppText.caption),
                    ],
                  ),
                  if (booking.staff != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(booking.staff!.name, style: AppText.caption),
                      ],
                    ),
                  if (onReview != null)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LinkButton(
                        label: 'قيّمي زيارتكِ',
                        icon: Icons.star_outline_rounded,
                        onPressed: onReview,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
