import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/booking.dart';
import '../../data/models/catalog.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';

/// Paged reviews for the salon or (when [serviceId] is set) one service.
class ReviewsController extends GetxController {
  ReviewsController(this._repo, {this.serviceId, this.serviceName});

  final CatalogRepository _repo;
  final int? serviceId;
  final String? serviceName;

  final items = <Review>[].obs;
  final summary = const ReviewSummary().obs;
  final loading = true.obs;
  final loadingMore = false.obs;
  final error = RxnString();
  final scroll = ScrollController();
  int _page = 1;
  int _lastPage = 1;

  @override
  void onInit() {
    super.onInit();
    scroll.addListener(() {
      if (scroll.position.pixels > scroll.position.maxScrollExtent - 200) {
        more();
      }
    });
    load();
  }

  Future<(List<Review>, ReviewSummary, int, int)> _fetch(int page) async {
    final (paged, sum) = serviceId == null
        ? await _repo.placeReviews(page: page)
        : await _repo.serviceReviews(serviceId!, page: page);
    return (paged.items, sum, paged.meta.page, paged.meta.lastPage);
  }

  Future<void> load() async {
    error.value = null;
    loading.value = true;
    try {
      final (list, sum, page, last) = await _fetch(1);
      items.assignAll(list);
      summary.value = sum;
      _page = page;
      _lastPage = last;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  Future<void> more() async {
    if (loading.value || loadingMore.value || _page >= _lastPage) return;
    loadingMore.value = true;
    try {
      final (list, _, page, last) = await _fetch(_page + 1);
      items.addAll(list);
      _page = page;
      _lastPage = last;
    } on ApiException {
      // Keep what is shown; scrolling again retries.
    } finally {
      loadingMore.value = false;
    }
  }

  @override
  void onClose() {
    scroll.dispose();
    super.onClose();
  }
}

/// Figma 04.01–04.04.
class ReviewsScreen extends GetView<ReviewsController> {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            Expanded(
              child: Obx(() {
                if (c.loading.value) return const LoadingView();
                if (c.error.value != null) {
                  return ErrorView(message: c.error.value!, onRetry: c.load);
                }
                return RefreshIndicator(
                  onRefresh: c.load,
                  child: ListView(
                    controller: c.scroll,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      PageTitle(
                        eyebrow: c.serviceId == null
                            ? 'آراء زائراتنا'
                            : c.serviceName,
                        title: c.serviceId == null
                            ? 'تقييمات ÉLORA'
                            : 'تقييمات الخدمة',
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                      ),
                      if (c.items.isEmpty)
                        const EmptyView(
                          title: 'لا توجد تقييمات بعد',
                          message: 'ستظهر آراء الزائرات هنا عند نشرها.',
                        )
                      else ...[
                        RatingSummary(summary: c.summary.value),
                        const SizedBox(height: 14),
                        for (final r in c.items) ReviewCard(review: r),
                        if (c.loadingMore.value) const LoadingView(),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitReviewController extends GetxController {
  SubmitReviewController(this._repo, this.booking);

  final BookingRepository _repo;
  final Booking booking;

  final rating = 0.obs;
  final comment = TextEditingController();
  final sending = false.obs;
  final error = RxnString();
  final done = false.obs;

  static const labels = [
    '',
    'لم تعجبني',
    'مقبولة',
    'جيدة',
    'رائعة',
    'تجربة استثنائية',
  ];

  Future<void> submit() async {
    if (rating.value == 0) {
      error.value = 'يرجى اختيار عدد النجوم';
      return;
    }
    if (sending.value) return;
    sending.value = true;
    error.value = null;
    try {
      final message = await _repo.review(
        booking.id,
        rating: rating.value,
        comment: comment.text.trim().isEmpty ? null : comment.text.trim(),
      );
      done.value = true;
      Get.back(result: true);
      showMessage(message ?? 'شكرًا لكِ! تم نشر تقييمكِ.');
    } on ApiException catch (e) {
      error.value = e.fieldErrors.values.firstOrNull ?? e.message;
    } finally {
      sending.value = false;
    }
  }

  @override
  void onClose() {
    comment.dispose();
    super.onClose();
  }
}

/// Figma 04.05. Opened only for bookings where the server set `can_review`.
class SubmitReviewScreen extends GetView<SubmitReviewController> {
  const SubmitReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final b = c.booking;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  const PageTitle(
                    eyebrow: 'بعد زيارتكِ',
                    title: 'كيف كانت تجربتكِ؟',
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
                  ),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.blushStrong,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'É',
                        style: TextStyle(
                          fontFamily: AppText.latin,
                          fontSize: 30,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    b.serviceName ?? '',
                    style: AppText.h3,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    [
                      if (b.staff != null) 'مع ${b.staff!.name}',
                      Fmt.dayMonth(b.startsAt),
                    ].where((e) => e.isNotEmpty).join(' · '),
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            tooltip: '$i نجوم',
                            iconSize: 36,
                            onPressed: () {
                              c.rating.value = i;
                              c.error.value = null;
                            },
                            icon: Icon(
                              i <= c.rating.value
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppColors.gold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Obx(
                    () => Text(
                      SubmitReviewController.labels[c.rating.value],
                      style: AppText.title,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: TextField(
                      controller: c.comment,
                      minLines: 4,
                      maxLines: 6,
                      maxLength: 1000,
                      style: AppText.bodyStrong,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'اكتبي رأيكِ',
                        hintText: 'ملاحظاتكِ تساعدنا على تقديم تجربة أجمل…',
                        isDense: true,
                      ),
                    ),
                  ),
                  Obx(
                    () => c.error.value == null
                        ? const SizedBox(height: 12)
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: NoticeBox(title: c.error.value!),
                          ),
                  ),
                  Obx(
                    () => PrimaryButton(
                      label: 'إرسال التقييم',
                      loading: c.sending.value,
                      loadingLabel: 'جارٍ الإرسال…',
                      onPressed: c.submit,
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
