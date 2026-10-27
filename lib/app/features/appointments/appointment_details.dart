import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../routes/app_routes.dart';
import '../../shared/controllers/load_controller.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../shared/widgets/form_fields.dart';
import '../booking/booking_success.dart';
import 'appointments.dart';

class AppointmentDetailsController extends LoadController<Booking> {
  AppointmentDetailsController(
    this._repo,
    this.bookingId, {
    this.openReview = false,
  });

  final BookingRepository _repo;
  final int bookingId;
  final bool openReview;
  bool changed = false;

  @override
  bool get private => true;

  @override
  Future<Booking> fetch() => _repo.detail(bookingId);

  @override
  void onLoaded(Booking value) {
    if (openReview && value.canReview && !changed) review();
  }

  Future<void> _push(String route) async {
    final b = data.value;
    if (b == null) return;
    final result = await Get.toNamed(route, arguments: b);
    if (result == true) {
      changed = true;
      load();
    }
  }

  void reschedule() => _push(Routes.reschedule);
  void cancel() => _push(Routes.cancelBooking);
  void review() => _push(Routes.submitReview);
}

class AppointmentDetailsBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map;
    Get.lazyPut(
      () => AppointmentDetailsController(
        Get.find(),
        args['id'] as int,
        openReview: args['review'] == true,
      ),
    );
  }
}

/// Figma 06.02.
class AppointmentDetailsScreen extends GetView<AppointmentDetailsController> {
  const AppointmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.back(result: c.changed);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              EloraHeader(onBack: () => Get.back(result: c.changed)),
              Expanded(
                child: LoadBuilder<Booking>(
                  controller: c,
                  builder: (b) => RefreshIndicator(
                    onRefresh: c.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      children: [
                        Center(
                          child: StatusChip(
                            label: bookingStatusLabel(b),
                            tone: bookingTone(b.status),
                          ),
                        ),
                        const PageTitle(
                          title: 'تفاصيل الموعد',
                          center: true,
                          padding: EdgeInsets.fromLTRB(0, 8, 0, 2),
                        ),
                        Text(
                          'رقم الحجز · ${b.displayNumber}',
                          style: AppText.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (b.qrPayload != null && b.status != 'cancelled')
                          EloraCard(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'أبرزي هذا الرمز\nعند الاستقبال',
                                        style: AppText.h2,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'لإتمام تسجيل وصولكِ بسرعة',
                                        style: AppText.caption,
                                      ),
                                      if (b.code != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          b.code!,
                                          style: AppText.bodyStrong,
                                          textDirection: TextDirection.ltr,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                BookingQr(
                                  payload: b.qrPayload!,
                                  fallback: b.code ?? b.displayNumber,
                                  size: 110,
                                ),
                              ],
                            ),
                          ),
                        if (b.timeline.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          const Text('حالة الموعد', style: AppText.h2),
                          const SizedBox(height: 10),
                          _Timeline(steps: b.timeline, current: b.currentStep),
                        ],
                        const SizedBox(height: 18),
                        EloraCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              InfoRow(
                                label: 'الخدمة',
                                value: b.serviceName ?? '',
                              ),
                              const Divider(),
                              InfoRow(
                                label: 'الأخصائية',
                                value: b.staff?.name ?? 'أي أخصائية متاحة',
                              ),
                              const Divider(),
                              InfoRow(
                                label: 'التاريخ والوقت',
                                value: Fmt.dateTime(b.startsAt),
                              ),
                              if (b.durationMinutes != null) ...[
                                const Divider(),
                                InfoRow(
                                  label: 'المدة',
                                  value: Fmt.duration(b.durationMinutes!),
                                ),
                              ],
                              if (b.notes != null) ...[
                                const Divider(),
                                InfoRow(label: 'ملاحظاتكِ', value: b.notes!),
                              ],
                              // Intake answers as the server labels them.
                              for (final a in b.answers) ...[
                                const Divider(),
                                InfoRow(label: a.label, value: a.value),
                              ],
                              if (b.status == 'cancelled' &&
                                  b.cancelReason != null) ...[
                                const Divider(),
                                InfoRow(
                                  label: b.cancelledLate
                                      ? 'سبب الإلغاء (متأخر)'
                                      : 'سبب الإلغاء',
                                  value: b.cancelReason!,
                                ),
                              ],
                              if ((b.discount ?? 0) > 0) ...[
                                const Divider(),
                                InfoRow(
                                  label: 'الخصم',
                                  value:
                                      '− ${Fmt.price(b.discount, currency())}',
                                ),
                              ],
                              const Divider(),
                              InfoRow(
                                label: 'الإجمالي',
                                value: '',
                                valueWidget: Text(
                                  Fmt.price(b.finalPrice, currency()),
                                  style: AppText.price,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (b.canReview)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PrimaryButton(
                              label: 'قيّمي زيارتكِ',
                              icon: Icons.star_outline_rounded,
                              onPressed: c.review,
                            ),
                          ),
                        if (b.canReschedule)
                          SecondaryButton(
                            label: 'إعادة الجدولة',
                            icon: Icons.refresh_rounded,
                            onPressed: c.reschedule,
                          ),
                        if (b.canCancel)
                          Center(
                            child: LinkButton(
                              label: 'إلغاء الموعد',
                              icon: Icons.close_rounded,
                              onPressed: c.cancel,
                            ),
                          ),
                        if (!b.canCancel &&
                            !b.canReschedule &&
                            b.status == 'confirmed')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'لم يعد تعديل هذا الموعد متاحًا. تواصلي مع الصالون للمساعدة.',
                              style: AppText.caption,
                              textAlign: TextAlign.center,
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
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps, required this.current});

  final List<TimelineStep> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: steps[i].done
                              ? AppColors.primary
                              : AppColors.white,
                          border: Border.all(
                            color: steps[i].done || i == current
                                ? AppColors.primary
                                : AppColors.borderSoft,
                            width: i == current ? 4 : 1.3,
                          ),
                        ),
                        child: steps[i].done
                            ? const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: AppColors.white,
                              )
                            : null,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.3,
                            color: AppColors.borderSoft,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].label, style: AppText.bodyStrong),
                        if (steps[i].atLabel != null || steps[i].at != null)
                          Text(
                            steps[i].atLabel ?? Fmt.dateTime(steps[i].at),
                            style: AppText.caption,
                          ),
                        if (steps[i].note != null)
                          Text(steps[i].note!, style: AppText.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------- reschedule

class RescheduleController extends GetxController {
  RescheduleController(this._repo, this.booking);

  final BookingRepository _repo;
  final Booking booking;

  final days = <AvailabilityDay>[].obs;
  final day = Rxn<AvailabilityDay>();
  final slots = <Slot>[].obs;
  final slot = Rxn<Slot>();
  final loadingDays = true.obs;
  final loadingSlots = false.obs;
  final submitting = false.obs;
  final error = RxnString();
  final alternatives = <Slot>[].obs;
  final pickedAlternative = Rxn<Slot>();
  final unavailable = false.obs;
  int _slotsRequest = 0;

  @override
  void onInit() {
    super.onInit();
    loadDays();
  }

  Future<void> loadDays() async {
    final serviceId = booking.serviceId;
    if (serviceId == null) {
      error.value = 'تعذّر تحديد الخدمة لهذا الموعد.';
      loadingDays.value = false;
      return;
    }
    loadingDays.value = true;
    error.value = null;
    try {
      days.assignAll(
        await _repo.days(serviceId: serviceId, staffId: booking.staff?.id),
      );
      final first = days.firstWhereOrNull((d) => d.available);
      if (first != null) selectDay(first);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loadingDays.value = false;
    }
  }

  Future<void> selectDay(AvailabilityDay d) async {
    day.value = d;
    slot.value = null;
    final request = ++_slotsRequest;
    loadingSlots.value = true;
    slots.clear();
    try {
      final result = await _repo.slots(
        serviceId: booking.serviceId!,
        date: d.date,
        staffId: booking.staff?.id,
      );
      if (request == _slotsRequest) {
        slots.assignAll(
          result.slots.where((s) => s.startsAt != booking.startsAtRaw),
        );
      }
    } on ApiException catch (e) {
      if (request == _slotsRequest) error.value = e.message;
    } finally {
      if (request == _slotsRequest) loadingSlots.value = false;
    }
  }

  Future<void> submit([Slot? override]) async {
    final s = override ?? slot.value;
    if (s == null || submitting.value) return;
    submitting.value = true;
    error.value = null;
    try {
      await _repo.reschedule(
        booking.id,
        startsAt: s.startsAt,
        staffId: booking.staff?.id,
      );
      Get.back(result: true);
      showMessage('تم تحديث موعدكِ');
    } on ApiException catch (e) {
      if (e.hasCode('SLOT_UNAVAILABLE')) {
        final raw = e.details['alternatives'];
        alternatives.assignAll(
          raw is List
              ? raw
                    .whereType<Map<String, dynamic>>()
                    .map(Slot.fromJson)
                    .toList()
              : const <Slot>[],
        );
        unavailable.value = true;
      } else {
        error.value = e.fieldErrors.values.firstOrNull ?? e.message;
      }
    } finally {
      submitting.value = false;
    }
  }
}

/// Figma 06.03 / 06.04.
class RescheduleScreen extends GetView<RescheduleController> {
  const RescheduleScreen({super.key});

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
                if (c.unavailable.value) return _Unavailable();
                if (c.loadingDays.value) return const LoadingView();
                if (c.days.isEmpty && c.error.value != null) {
                  return ErrorView(
                    message: c.error.value!,
                    onRetry: c.loadDays,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    PageTitle(
                      eyebrow:
                          'الموعد الحالي · ${Fmt.dateTime(c.booking.startsAt)}',
                      title: 'إعادة جدولة الموعد',
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                    ),
                    SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: c.days.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = c.days[i];
                          final sel = c.day.value?.date == d.date;
                          return ChoiceChip(
                            selected: sel,
                            showCheckmark: false,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.white,
                            onSelected: d.available
                                ? (_) => c.selectDay(d)
                                : null,
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  d.label,
                                  style: AppText.caption.copyWith(
                                    color: sel ? Colors.white : null,
                                  ),
                                ),
                                Text(
                                  '${d.dateValue?.day ?? ''}',
                                  style: AppText.title.copyWith(
                                    color: sel ? Colors.white : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('الأوقات المتاحة', style: AppText.h2),
                    const SizedBox(height: 10),
                    if (c.loadingSlots.value)
                      const LoadingView()
                    else if (c.slots.isEmpty)
                      const Text(
                        'لا توجد أوقات متاحة في هذا اليوم.',
                        style: AppText.caption,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in c.slots)
                            PillChip(
                              label: Fmt.time12(s.time),
                              selected: c.slot.value?.startsAt == s.startsAt,
                              onTap: () => c.slot.value = s,
                            ),
                        ],
                      ),
                    if (c.slot.value != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardFill,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text('الموعد الجديد', style: AppText.caption),
                            const Spacer(),
                            Text(
                              '${Fmt.dayMonth(c.day.value?.dateValue)} · ${Fmt.time12(c.slot.value!.time)}',
                              style: AppText.bodyStrong,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (c.error.value != null) ...[
                      const SizedBox(height: 12),
                      NoticeBox(title: c.error.value!),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'تأكيد الموعد الجديد',
                      loading: c.submitting.value,
                      onPressed: c.slot.value == null ? null : () => c.submit(),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Unavailable extends GetView<RescheduleController> {
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final picked = c.pickedAlternative;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const PageTitle(
          eyebrow: 'تحديث الموعد',
          title: 'هذا الوقت لم يعد متاحًا',
          padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
        ),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.blushStrong,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '!',
              style: TextStyle(fontSize: 28, color: AppColors.primaryDeep),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'حُجز هذا الموعد قبل لحظات. اختاري أقرب البدائل.',
          style: AppText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        if (c.alternatives.isNotEmpty)
          const Text('أوقات مقترحة', style: AppText.h2),
        const SizedBox(height: 10),
        Obx(
          () => Column(
            children: [
              for (final s in c.alternatives)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EloraCard(
                    onTap: () => picked.value = s,
                    borderColor: picked.value == s
                        ? AppColors.primary
                        : AppColors.borderFaint,
                    color: picked.value == s
                        ? AppColors.blush
                        : AppColors.white,
                    child: Row(
                      children: [
                        Text(
                          '${Fmt.dayMonth(DateTime.tryParse(s.startsAt.length >= 10 ? s.startsAt.substring(0, 10) : ''))} · ${Fmt.time12(s.time)}',
                          style: AppText.bodyStrong,
                        ),
                        const Spacer(),
                        Text(
                          s.staff.isEmpty ? 'أي أخصائية' : s.staff.first.name,
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              if (c.alternatives.isNotEmpty)
                PrimaryButton(
                  label: 'اختيار الوقت البديل',
                  loading: c.submitting.value,
                  onPressed: picked.value == null
                      ? null
                      : () {
                          c.unavailable.value = false;
                          c.submit(picked.value);
                        },
                ),
              LinkButton(
                label: 'اختيار وقت آخر',
                onPressed: () {
                  c.unavailable.value = false;
                  if (c.day.value != null) c.selectDay(c.day.value!);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- cancel

class CancelBookingController extends GetxController {
  CancelBookingController(this._repo, this.booking);

  final BookingRepository _repo;
  final Booking booking;

  static const reasons = ['ظرف طارئ', 'تغيير في خططي', 'سبب آخر'];
  final reason = reasons.first.obs;
  final note = TextEditingController();
  final submitting = false.obs;
  final error = RxnString();

  Future<void> submit() async {
    if (submitting.value) return;
    submitting.value = true;
    error.value = null;
    try {
      final text = [
        reason.value,
        note.text.trim(),
      ].where((e) => e.isNotEmpty).join(' — ');
      final message = await _repo.cancel(booking.id, reason: text);
      Get.back(result: true);
      showMessage(message ?? 'تم إلغاء الموعد');
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    note.dispose();
    super.onClose();
  }
}

/// Figma 06.05. The late warning comes from the server's `cancel_is_late`.
class CancelBookingScreen extends GetView<CancelBookingController> {
  const CancelBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
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
                    eyebrow: 'إدارة الموعد',
                    title: 'إلغاء الحجز',
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
                  ),
                  Text(
                    '${c.booking.serviceName ?? ''} · ${Fmt.dateTime(c.booking.startsAt)}',
                    style: AppText.bodyStrong,
                  ),
                  const SizedBox(height: 12),
                  if (c.booking.cancelIsLate)
                    const NoticeBox(
                      title: 'تنبيه: إلغاء متأخر',
                      message: 'قد يؤثر الإلغاء الآن في درجة التزامكِ.',
                      tone: StatusTone.warning,
                    ),
                  const SizedBox(height: 16),
                  const Text('سبب الإلغاء', style: AppText.bodyStrong),
                  const SizedBox(height: 8),
                  Obx(
                    () => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in CancelBookingController.reasons)
                          PillChip(
                            label: r,
                            selected: c.reason.value == r,
                            onTap: () => c.reason.value = r,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  EloraTextField(
                    label: 'ملاحظة إضافية',
                    controller: c.note,
                    hint: 'اكتبي السبب إن رغبتِ…',
                    maxLines: 4,
                    minLines: 3,
                    maxLength: 300,
                  ),
                  Obx(
                    () => c.error.value == null
                        ? const SizedBox(height: 18)
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: NoticeBox(title: c.error.value!),
                          ),
                  ),
                  Obx(
                    () => PrimaryButton(
                      label: 'تأكيد إلغاء الموعد',
                      destructive: true,
                      loading: c.submitting.value,
                      loadingLabel: 'جارٍ الإلغاء…',
                      onPressed: c.submit,
                    ),
                  ),
                  LinkButton(
                    label: 'الاحتفاظ بالموعد',
                    color: AppColors.textSecondary,
                    onPressed: () => Get.back(),
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
