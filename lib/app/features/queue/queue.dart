import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/auth_guard.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../routes/app_nav.dart';

/// Polls only while the owning route is alive and the app is in the
/// foreground; never starts a poll while one is in flight.
mixin ForegroundPolling on GetxController implements WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _inFlight = false;
  bool _foreground = true;

  Duration get pollInterval => const Duration(seconds: 20);
  Future<void> poll();

  void startPolling() {
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  void _schedule() {
    _pollTimer?.cancel();
    if (!_foreground || isClosed) return;
    _pollTimer = Timer.periodic(pollInterval, (_) => runPoll());
  }

  Future<void> runPoll() async {
    if (_inFlight || !_foreground || isClosed) return;
    _inFlight = true;
    try {
      await poll();
    } finally {
      _inFlight = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fg = state == AppLifecycleState.resumed;
    if (fg == _foreground) return;
    _foreground = fg;
    if (fg) {
      runPoll();
      _schedule();
    } else {
      _pollTimer?.cancel();
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

class QueueBoardController extends GetxController
    with WidgetsBindingObserver, ForegroundPolling {
  QueueBoardController(this._repo, this._session);

  final QueueRepository _repo;
  final SessionService _session;
  final board = Rxn<QueueBoard>();
  final ticket = Rxn<QueueTicket>();
  final loading = true.obs;
  final error = RxnString();
  final taking = false.obs;

  @override
  void onInit() {
    super.onInit();
    runPoll().whenComplete(() => loading.value = false);
    startPolling();
  }

  @override
  Future<void> poll() async {
    final epoch = _session.epoch;
    try {
      board.value = await _repo.board();
      error.value = null;
      if (_session.isSignedIn) {
        final t = await _repo.myTicket();
        if (_session.isCurrent(epoch)) ticket.value = t;
      } else {
        ticket.value = null;
      }
    } on ApiException catch (e) {
      error.value = e.message;
    }
  }

  Future<void> take() async {
    if (!_session.isSignedIn) {
      await AuthGate.showSheet(const PendingDestination(Routes.queue));
      return;
    }
    if (taking.value) return;
    taking.value = true;
    try {
      ticket.value = await _repo.take();
      Get.toNamed(Routes.queueTicket);
    } on ApiException catch (e) {
      showMessage(e.message, error: true);
      runPoll();
    } finally {
      taking.value = false;
    }
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}

/// Figma 08.01 (open) / 08.03 (closed).
class QueueBoardScreen extends GetView<QueueBoardController> {
  const QueueBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final b = c.board.value;
      if (c.loading.value && b == null) {
        return const Scaffold(body: LoadingView());
      }
      if (b == null) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const EloraHeader(),
                Expanded(
                  child: ErrorView(
                    message: c.error.value ?? '',
                    onRetry: c.runPoll,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (b.isClosed) return const _Closed();
      return _Open(board: b);
    });
  }
}

class _Closed extends StatelessWidget {
  const _Closed();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const EloraHeader(),
          const PageTitle(
            eyebrow: 'الدور الحي',
            title: 'الدور غير متاح الآن',
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const EmptyView(
                    title: 'سنعود لاستقبالكِ قريبًا',
                    message:
                        'الدور الحي مغلق حاليًا. تحققي من ساعات العمل أو احجزي مسبقًا.',
                  ),
                  PrimaryButton(
                    label: 'عرض المواعيد المتاحة',
                    onPressed: () => AppNav.toMain(tab: 1),
                  ),
                  LinkButton(
                    label: 'عرض ساعات العمل',
                    onPressed: () => Get.toNamed(Routes.salon),
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

class _Open extends GetView<QueueBoardController> {
  const _Open({required this.board});

  final QueueBoard board;

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFF5EDE6);
    return Scaffold(
      backgroundColor: const Color(0xFF3E2A2A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.1,
            colors: [Color(0xFF6B3E45), Color(0xFF3A2828)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'رجوع',
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: light,
                        size: 18,
                      ),
                    ),
                    const Wordmark(color: light),
                    const Spacer(),
                    StatusChip(
                      label: board.accepting ? 'يستقبل الآن' : 'مفتوح',
                      tone: StatusTone.success,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.runPoll,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 50),
                      Text(
                        'الدور الحالي',
                        style: AppText.caption.copyWith(
                          color: light.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'نخدم الآن',
                        style: AppText.display.copyWith(color: light),
                        textAlign: TextAlign.center,
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          board.nowServing.isEmpty
                              ? '—'
                              : board.nowServing.join(' · '),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontFamily: AppText.latin,
                            fontSize: 56,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: light.withValues(alpha: 0.2)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              value: '${board.waitingCount}',
                              label: 'في الانتظار',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: light.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: _Stat(
                              value: board.estimatedWaitMinutes == null
                                  ? '—'
                                  : '${board.estimatedWaitMinutes}',
                              label: 'دقيقة انتظار تقريبًا',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Obx(() {
                        final t = controller.ticket.value;
                        if (t != null) {
                          return PrimaryButton(
                            label: 'رقمي: ${t.label}',
                            showArrow: true,
                            onPressed: () => Get.toNamed(Routes.queueTicket),
                          );
                        }
                        return Column(
                          children: [
                            Text(
                              'خذي رقمًا وسنرسل لكِ تنبيهًا عندما يقترب دوركِ.',
                              style: AppText.caption.copyWith(
                                color: light.withValues(alpha: 0.75),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'خذي رقمًا',
                              showArrow: true,
                              loading: controller.taking.value,
                              onPressed: board.accepting
                                  ? controller.take
                                  : null,
                            ),
                            if (!board.accepting)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'لا يُستقبل أرقام جديدة حاليًا.',
                                  style: AppText.caption.copyWith(color: light),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 30),
                      Text(
                        'يتحدّث تلقائيًا',
                        style: AppText.caption.copyWith(
                          color: light.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppText.h1.copyWith(color: Colors.white)),
      Text(
        label,
        style: AppText.caption.copyWith(color: const Color(0xB3F5EDE6)),
      ),
    ],
  );
}

// ------------------------------------------------------------- my ticket

class QueueTicketController extends GetxController
    with WidgetsBindingObserver, ForegroundPolling {
  QueueTicketController(this._repo, this._session);

  final QueueRepository _repo;
  final SessionService _session;
  final ticket = Rxn<QueueTicket>();
  final board = Rxn<QueueBoard>();
  final loading = true.obs;
  final error = RxnString();
  final cancelling = false.obs;

  @override
  Duration get pollInterval => const Duration(seconds: 15);

  @override
  void onInit() {
    super.onInit();
    runPoll().whenComplete(() => loading.value = false);
    startPolling();
  }

  @override
  Future<void> poll() async {
    final epoch = _session.epoch;
    try {
      final results = await Future.wait([_repo.myTicket(), _repo.board()]);
      if (!_session.isCurrent(epoch)) return;
      ticket.value = results[0] as QueueTicket?;
      board.value = results[1] as QueueBoard;
      error.value = null;
    } on ApiException catch (e) {
      error.value = e.message;
    }
  }

  Future<void> cancel() async {
    final t = ticket.value;
    if (t == null) return;
    final ok = await showConfirmSheet(
      title: 'إلغاء رقمكِ؟',
      message: 'ستفقدين موقعكِ الحالي في الدور ولن تتمكني من استعادته.',
      confirmLabel: 'نعم، ألغِ رقمي',
    );
    if (!ok || cancelling.value) return;
    cancelling.value = true;
    try {
      await _repo.cancel(t.id);
      ticket.value = null;
      showMessage('تم إلغاء رقمكِ');
      Get.back();
    } on ApiException catch (e) {
      showMessage(e.message, error: true);
      runPoll();
    } finally {
      cancelling.value = false;
    }
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}

/// Figma 08.02 / 08.04.
class QueueTicketScreen extends GetView<QueueTicketController> {
  const QueueTicketScreen({super.key});

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
                final t = c.ticket.value;
                if (t == null) {
                  if (c.error.value != null) {
                    return ErrorView(
                      message: c.error.value!,
                      onRetry: c.runPoll,
                    );
                  }
                  return EmptyView(
                    icon: Icons.confirmation_number_outlined,
                    title: 'ليس لديكِ رقم اليوم',
                    message:
                        'خذي رقمًا من لوحة الدور عندما يكون الصالون مفتوحًا.',
                    actionLabel: 'لوحة الدور',
                    onAction: () => Get.offNamed(Routes.queue),
                  );
                }
                final b = c.board.value;
                return RefreshIndicator(
                  onRefresh: c.runPoll,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      PageTitle(
                        eyebrow: 'دوركِ محفوظ',
                        title: t.isCalled
                            ? 'حان دوركِ الآن'
                            : 'سنخبركِ عندما يقترب',
                        center: true,
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                      ),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.cardFill,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.blushStrong),
                        ),
                        child: Column(
                          children: [
                            const Text('رقمكِ', style: AppText.eyebrow),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                t.label,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontFamily: AppText.latin,
                                  fontSize: 54,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (t.ahead != null)
                              Text(
                                t.ahead == 0
                                    ? 'أنتِ التالية'
                                    : '${t.ahead} أشخاص قبلكِ',
                                style: AppText.h3,
                              ),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  'الوقت المتوقع',
                                  style: AppText.caption,
                                ),
                                const Spacer(),
                                Text(
                                  t.estimatedWaitMinutes == null
                                      ? '—'
                                      : 'حوالي ${t.estimatedWaitMinutes} دقيقة',
                                  style: AppText.bodyStrong.copyWith(
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ],
                            ),
                            if (b != null && b.nowServing.isNotEmpty)
                              Row(
                                children: [
                                  const Text(
                                    'الدور الحالي',
                                    style: AppText.caption,
                                  ),
                                  const Spacer(),
                                  Text(
                                    b.nowServing.first,
                                    style: AppText.caption,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const NoticeBox(
                        title: 'التنبيهات',
                        message:
                            'تتحدّث هذه الشاشة تلقائيًا، وسنرسل لكِ إشعارًا عندما يقترب دوركِ.',
                        tone: StatusTone.warning,
                      ),
                      const SizedBox(height: 12),
                      if (t.canCancel && !t.isCalled)
                        Center(
                          child: c.cancelling.value
                              ? const LoadingView()
                              : LinkButton(
                                  label: 'إلغاء رقمي',
                                  onPressed: c.cancel,
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
