import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../routes/app_routes.dart';
import '../../shared/controllers/load_controller.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../shared/widgets/form_fields.dart';

String waitlistStatusLabel(WaitlistEntry e) =>
    e.statusLabel ??
    switch (e.status) {
      'waiting' => 'بانتظار موعد',
      'offered' => 'موعد متاح',
      'booked' => 'تم الحجز',
      'expired' => 'انتهى العرض',
      'cancelled' => 'ملغي',
      _ => e.status,
    };

StatusTone waitlistTone(String status) => switch (status) {
  'offered' => StatusTone.accent,
  'booked' => StatusTone.success,
  'waiting' => StatusTone.warning,
  _ => StatusTone.neutral,
};

String _range(WaitlistEntry e) => [
  if (e.date != null) Fmt.dayMonth(DateTime.tryParse(e.date!)),
  if (e.fromTime != null || e.toTime != null)
    '${Fmt.time12(e.fromTime)} – ${Fmt.time12(e.toTime)}',
].join(' · ');

// ------------------------------------------------------------------ join

class WaitlistJoinController extends GetxController {
  WaitlistJoinController(this._repo, Map args)
    : serviceId = args['serviceId'] as int,
      serviceName = args['serviceName'] as String?,
      staffId = args['staffId'] as int?,
      staffName = args['staffName'] as String?,
      date = RxnString(args['date'] as String?);

  final WaitlistRepository _repo;
  final int serviceId;
  final String? serviceName;
  final int? staffId;
  final String? staffName;
  final RxnString date;
  final from = const TimeOfDay(hour: 16, minute: 0).obs;
  final to = const TimeOfDay(hour: 20, minute: 0).obs;
  final notes = TextEditingController();
  final submitting = false.obs;
  final errors = <String, String>{}.obs;
  final error = RxnString();

  static String hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> submit() async {
    if (date.value == null) {
      errors['date'] = 'يرجى اختيار التاريخ';
      return;
    }
    if (from.value.hour * 60 + from.value.minute >=
        to.value.hour * 60 + to.value.minute) {
      errors['to_time'] = 'يجب أن يكون وقت النهاية بعد وقت البداية';
      return;
    }
    if (submitting.value) return;
    submitting.value = true;
    errors.clear();
    error.value = null;
    try {
      final entry = await _repo.join(
        serviceId: serviceId,
        staffId: staffId,
        date: date.value!,
        fromTime: hhmm(from.value),
        toTime: hhmm(to.value),
        notes: notes.text,
      );
      Get.offNamed(Routes.waitlistEntry, arguments: entry.id);
      showMessage('انضممتِ إلى قائمة الانتظار. سنخبركِ فور توفر موعد.');
    } on ApiException catch (e) {
      if (e.isValidation && e.fieldErrors.isNotEmpty) {
        errors.assignAll(e.fieldErrors);
      } else {
        error.value = e.message;
      }
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    notes.dispose();
    super.onClose();
  }
}

/// Figma 07.01.
class WaitlistJoinScreen extends GetView<WaitlistJoinController> {
  const WaitlistJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    Widget field(
      String label,
      String value, {
      VoidCallback? onTap,
      String? error,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EloraCard(
        onTap: onTap,
        borderColor: error != null ? AppColors.primary : AppColors.borderSoft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.caption),
                  Text(value, style: AppText.bodyStrong),
                  if (error != null)
                    Text(
                      error,
                      style: AppText.caption.copyWith(
                        color: AppColors.primaryDeep,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.edit_calendar_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            Expanded(
              child: Obx(
                () => ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const PageTitle(
                      eyebrow: 'قائمة الانتظار الذكية',
                      title: 'انضمي إلى قائمة الانتظار',
                      subtitle: 'سنخبركِ فور توفر موعد يطابق تفضيلاتكِ.',
                      padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
                    ),
                    field('الخدمة', c.serviceName ?? ''),
                    field('الأخصائية', c.staffName ?? 'أي أخصائية متاحة'),
                    field(
                      'التاريخ',
                      c.date.value == null
                          ? 'اختاري التاريخ'
                          : Fmt.dayMonth(DateTime.tryParse(c.date.value!)),
                      error: c.errors['date'],
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 60)),
                          initialDate:
                              DateTime.tryParse(c.date.value ?? '') ?? now,
                        );
                        if (picked != null) {
                          c.date.value = Fmt.ymd(picked);
                          c.errors.remove('date');
                        }
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: field(
                            'من',
                            Fmt.time12(
                              WaitlistJoinController.hhmm(c.from.value),
                            ),
                            error: c.errors['from_time'],
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: c.from.value,
                              );
                              if (t != null) c.from.value = t;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: field(
                            'إلى',
                            Fmt.time12(WaitlistJoinController.hhmm(c.to.value)),
                            error: c.errors['to_time'],
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: c.to.value,
                              );
                              if (t != null) {
                                c.to.value = t;
                                c.errors.remove('to_time');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    EloraTextField(
                      label: 'ملاحظات',
                      controller: c.notes,
                      hint: 'أي وقت بعد الدوام…',
                      maxLength: 300,
                    ),
                    if (c.error.value != null) ...[
                      const SizedBox(height: 12),
                      NoticeBox(title: c.error.value!),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'الانضمام إلى القائمة',
                      loading: c.submitting.value,
                      onPressed: c.submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ list

class WaitlistController extends GetxController {
  WaitlistController(this._repo, this._session);

  final WaitlistRepository _repo;
  final SessionService _session;
  final tab = 0.obs;
  final active = <WaitlistEntry>[].obs;
  final history = <WaitlistEntry>[].obs;
  final loading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final epoch = _session.epoch;
    loading.value = true;
    error.value = null;
    try {
      final list = await _repo.list(active: tab.value == 0);
      if (!_session.isCurrent(epoch)) return;
      (tab.value == 0 ? active : history).assignAll(list);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  void switchTab(int i) {
    tab.value = i;
    load();
  }

  Future<void> open(WaitlistEntry e) async {
    await Get.toNamed(Routes.waitlistEntry, arguments: e.id);
    load();
  }
}

/// Figma 07.02.
class WaitlistScreen extends GetView<WaitlistController> {
  const WaitlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            const PageTitle(
              eyebrow: 'طلباتكِ الحالية',
              title: 'قائمة الانتظار',
              padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(
                () => SegmentedPills(
                  labels: [
                    'النشطة${c.active.isEmpty ? '' : ' · ${c.active.length}'}',
                    'السابقة',
                  ],
                  index: c.tab.value,
                  onChanged: c.switchTab,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final list = c.tab.value == 0 ? c.active : c.history;
                if (c.loading.value && list.isEmpty) {
                  return const SingleChildScrollView(child: SkeletonList());
                }
                if (c.error.value != null && list.isEmpty) {
                  return ErrorView(message: c.error.value!, onRetry: c.load);
                }
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'لا توجد طلبات',
                    message:
                        'عندما يكون اليوم ممتلئًا، انضمي إلى قائمة الانتظار من شاشة الحجز.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: c.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      for (final e in list)
                        EloraCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () => c.open(e),
                          color: e.isOffered
                              ? AppColors.blush
                              : AppColors.white,
                          borderColor: e.isOffered
                              ? AppColors.blushStrong
                              : AppColors.borderFaint,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    e.displayNumber,
                                    style: AppText.caption,
                                    textDirection: TextDirection.ltr,
                                  ),
                                  const Spacer(),
                                  StatusChip(
                                    label: waitlistStatusLabel(e),
                                    tone: waitlistTone(e.status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(e.serviceName ?? '', style: AppText.title),
                              Text(_range(e), style: AppText.caption),
                              if (e.isOffered &&
                                  e.offer?.secondsLeft != null) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: _Countdown(
                                    seconds: e.offer!.secondsLeft!,
                                    style: AppText.price,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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

/// Ticks locally from a server `seconds_left`; the server decides expiry.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.seconds, required this.style, this.onDone});

  final int seconds;
  final TextStyle style;
  final VoidCallback? onDone;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late DateTime _end;
  Timer? _timer;
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant _Countdown old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) _reset();
  }

  void _reset() {
    _timer?.cancel();
    _end = DateTime.now().add(Duration(seconds: widget.seconds));
    _left = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _end.difference(DateTime.now()).inSeconds;
      setState(() => _left = left < 0 ? 0 : left);
      if (left <= 0) {
        _timer?.cancel();
        widget.onDone?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: _left % 60 == 0,
    label: 'الوقت المتبقي ${_left ~/ 60} دقيقة',
    excludeSemantics: true,
    child: Text(
      Fmt.countdown(_left),
      style: widget.style,
      textDirection: TextDirection.ltr,
    ),
  );
}

// ------------------------------------------------------------------ entry

enum OfferOutcome { none, expired, taken }

class WaitlistEntryController extends LoadController<WaitlistEntry> {
  WaitlistEntryController(this._repo, this.entryId);

  final WaitlistRepository _repo;
  final int entryId;
  final claiming = false.obs;
  final leaving = false.obs;
  final outcome = OfferOutcome.none.obs;
  final actionError = RxnString();

  @override
  bool get private => true;

  @override
  Future<WaitlistEntry> fetch() => _repo.detail(entryId);

  /// Countdown hit zero locally: ask the server for the real state.
  void onCountdownDone() => load();

  /// Refreshes the offer first, then lets the server decide.
  Future<void> claim() async {
    if (claiming.value) return;
    claiming.value = true;
    actionError.value = null;
    try {
      final fresh = await _repo.detail(entryId);
      data.value = fresh;
      if (!fresh.claimable) {
        outcome.value = fresh.status == 'expired'
            ? OfferOutcome.expired
            : OfferOutcome.taken;
        return;
      }
      final bookingId = await _repo.claim(entryId);
      if (bookingId != null) {
        Get.offNamed(Routes.appointment, arguments: {'id': bookingId});
      } else {
        await load();
      }
      showMessage('تم حجز الموعد بنجاح');
    } on ApiException catch (e) {
      if (e.hasCode('SLOT_TAKEN')) {
        outcome.value = OfferOutcome.taken;
        load();
      } else if (e.hasCode('OFFER_EXPIRED') || e.hasCode('EXPIRED')) {
        outcome.value = OfferOutcome.expired;
        load();
      } else {
        actionError.value = e.message;
      }
    } finally {
      claiming.value = false;
    }
  }

  Future<void> leave() async {
    final ok = await showConfirmSheet(
      title: 'مغادرة قائمة الانتظار؟',
      message: 'لن نرسل لكِ عروضًا جديدة لهذا الطلب بعد المغادرة.',
      confirmLabel: 'نعم، غادري القائمة',
    );
    if (!ok || leaving.value) return;
    leaving.value = true;
    try {
      await _repo.leave(entryId);
      Get.back(result: true);
      showMessage('غادرتِ قائمة الانتظار');
    } on ApiException catch (e) {
      actionError.value = e.message;
    } finally {
      leaving.value = false;
    }
  }
}

/// Figma 07.03 / 07.04 / 07.05 / 07.06 (states of one screen).
class WaitlistEntryScreen extends GetView<WaitlistEntryController> {
  const WaitlistEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            Expanded(
              child: LoadBuilder<WaitlistEntry>(
                controller: c,
                builder: (e) => Obx(() {
                  final outcome = c.outcome.value;
                  return RefreshIndicator(
                    onRefresh: c.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        if (outcome != OfferOutcome.none)
                          ..._outcome(outcome)
                        else if (e.claimable)
                          ..._offer(e)
                        else
                          ..._details(e),
                        if (c.actionError.value != null) ...[
                          const SizedBox(height: 12),
                          NoticeBox(title: c.actionError.value!),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _details(WaitlistEntry e) => [
    PageTitle(
      eyebrow: 'طلب رقم ${e.displayNumber}',
      title: 'تفاصيل الانتظار',
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
    ),
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.cardFill, Color(0xFFF6F0E8)],
        ),
      ),
      child: Column(
        children: [
          StatusChip(
            label: waitlistStatusLabel(e),
            tone: waitlistTone(e.status),
          ),
          const SizedBox(height: 10),
          Text(
            e.isWaiting ? 'نبحث لكِ عن الموعد الأنسب' : waitlistStatusLabel(e),
            style: AppText.h2,
            textAlign: TextAlign.center,
          ),
          if (e.isWaiting)
            const Text(
              'سنرسل إشعارًا فور توفر وقت ضمن نطاقكِ.',
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    ),
    const SizedBox(height: 12),
    EloraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          InfoRow(label: 'الخدمة', value: e.serviceName ?? ''),
          const Divider(),
          InfoRow(label: 'الأخصائية', value: e.staff?.name ?? 'أي أخصائية'),
          const Divider(),
          InfoRow(
            label: 'التاريخ',
            value: e.date == null
                ? ''
                : Fmt.dayMonth(DateTime.tryParse(e.date!)),
          ),
          const Divider(),
          InfoRow(
            label: 'الوقت',
            value: '${Fmt.time12(e.fromTime)} – ${Fmt.time12(e.toTime)}',
          ),
          if (e.notes != null) ...[
            const Divider(),
            InfoRow(label: 'ملاحظات', value: e.notes!),
          ],
        ],
      ),
    ),
    const SizedBox(height: 16),
    if (e.status == 'booked' && e.bookingId != null)
      PrimaryButton(
        label: 'عرض الموعد',
        onPressed: () =>
            Get.toNamed(Routes.appointment, arguments: {'id': e.bookingId}),
      ),
    if (e.isActive)
      Center(
        child: Obx(
          () => controller.leaving.value
              ? const LoadingView()
              : LinkButton(
                  label: 'مغادرة قائمة الانتظار',
                  onPressed: controller.leave,
                ),
        ),
      ),
  ];

  List<Widget> _offer(WaitlistEntry e) {
    final offer = e.offer;
    return [
      const PageTitle(
        eyebrow: 'وجدنا موعدًا لكِ',
        title: 'موعدكِ أصبح متاحًا',
        padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
      ),
      if (offer?.secondsLeft != null)
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blushStrong, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('احجزي خلال', style: AppText.caption),
                _Countdown(
                  seconds: offer!.secondsLeft!,
                  style: const TextStyle(
                    fontFamily: AppText.latin,
                    fontSize: 30,
                    color: AppColors.primaryDeep,
                  ),
                  onDone: controller.onCountdownDone,
                ),
                const Text('دقائق', style: AppText.caption),
              ],
            ),
          ),
        ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              e.date == null ? '' : Fmt.dayMonth(DateTime.tryParse(e.date!)),
              style: AppText.caption,
            ),
            Text(Fmt.time12(offer?.time), style: AppText.h1),
            Text(
              [
                e.serviceName,
                offer?.staffName ?? e.staff?.name,
              ].whereType<String>().join(' · '),
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Obx(
        () => PrimaryButton(
          label: 'احجزي الموعد الآن',
          loading: controller.claiming.value,
          loadingLabel: 'جارٍ التحقق من العرض…',
          onPressed: controller.claim,
        ),
      ),
      Center(
        child: LinkButton(
          label: 'ليس هذا الوقت',
          color: AppColors.textSecondary,
          onPressed: () => Get.back(),
        ),
      ),
    ];
  }

  List<Widget> _outcome(OfferOutcome o) => [
    const PageTitle(
      eyebrow: 'تحديث العرض',
      title: 'حالة الموعد',
      padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
    ),
    EloraCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o == OfferOutcome.expired
                      ? 'انتهت مهلة العرض'
                      : 'حُجز الموعد للتو',
                  style: AppText.h2,
                ),
                Text(
                  o == OfferOutcome.expired
                      ? 'أبقيناكِ في قائمة الانتظار وسنخبركِ عند توفر موعد آخر.'
                      : 'سبقكِ شخص آخر. ما زال طلبكِ نشطًا.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.cardFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              o == OfferOutcome.expired
                  ? Icons.hourglass_bottom_rounded
                  : Icons.close_rounded,
              color: AppColors.primaryDeep,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    SecondaryButton(
      label: 'العودة إلى طلبي',
      onPressed: () {
        controller.outcome.value = OfferOutcome.none;
        controller.load();
      },
    ),
  ];
}
