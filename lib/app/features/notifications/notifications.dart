import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/session/session_service.dart';
import '../../core/session/unread_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account_repository.dart';
import '../../routes/deep_links.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../routes/app_nav.dart';

class NotificationsController extends GetxController {
  NotificationsController(this._repo, this._session);

  final NotificationRepository _repo;
  final SessionService _session;
  final items = <AppNotification>[].obs;
  final unread = 0.obs;
  final loading = true.obs;
  final error = RxnString();
  final markingAll = false.obs;
  final loadingMore = false.obs;
  int _page = 1;
  bool _hasMore = false;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final epoch = _session.epoch;
    error.value = null;
    try {
      final (list, count, more) = await _repo.listPage();
      if (!_session.isCurrent(epoch)) return;
      items.assignAll(list);
      _page = 1;
      _hasMore = more;
      unread.value = count;
      Get.find<UnreadService>().set(count);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || loadingMore.value || loading.value) return;
    final epoch = _session.epoch;
    loadingMore.value = true;
    try {
      final (list, _, more) = await _repo.listPage(page: _page + 1);
      if (!_session.isCurrent(epoch)) return;
      final known = items.map((n) => n.id).toSet();
      items.addAll(list.where((n) => !known.contains(n.id)));
      _page++;
      _hasMore = more;
    } on ApiException {
      // Scrolling again retries.
    } finally {
      loadingMore.value = false;
    }
  }

  Future<void> readAll() async {
    if (markingAll.value || unread.value == 0) return;
    markingAll.value = true;
    try {
      final left = await _repo.readAll();
      unread.value = left;
      Get.find<UnreadService>().set(left);
      await load();
    } on ApiException catch (e) {
      showMessage(e.message, error: true);
    } finally {
      markingAll.value = false;
    }
  }

  /// Opens the in-app destination only if it is on the allowlist.
  void open(AppNotification n) {
    final dest = DeepLinks.resolve(n.url);
    if (dest == null) return;
    AppNav.open(dest);
  }
}

IconData _iconFor(AppNotification n) {
  final key = '${n.type ?? ''} ${n.url ?? ''}';
  if (key.contains('queue')) return Icons.schedule_rounded;
  if (key.contains('waitlist')) return Icons.auto_awesome_outlined;
  if (key.contains('cancel')) return Icons.event_busy_outlined;
  if (key.contains('remind')) return Icons.calendar_month_outlined;
  if (key.contains('booking')) return Icons.check_rounded;
  return Icons.notifications_none_rounded;
}

/// Figma 10.01.
class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            EloraHeader(
              trailing: Obx(
                () => c.unread.value == 0
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: c.markingAll.value ? null : c.readAll,
                        child: Text(
                          'قراءة الكل',
                          style: AppText.caption.copyWith(
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (c.loading.value) return const LoadingView();
                if (c.error.value != null && c.items.isEmpty) {
                  return ErrorView(message: c.error.value!, onRetry: c.load);
                }
                final fresh = c.items.where((n) => !n.read).toList();
                final older = c.items.where((n) => n.read).toList();
                return RefreshIndicator(
                  onRefresh: c.load,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.extentAfter < 300) c.loadMore();
                      return false;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        PageTitle(
                          eyebrow: 'ابقي على اطلاع',
                          title: 'الإشعارات',
                          subtitle: c.unread.value > 0
                              ? 'لديكِ ${c.unread.value} إشعارات جديدة'
                              : null,
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                        ),
                        if (c.items.isEmpty)
                          const EmptyView(
                            icon: Icons.notifications_none_rounded,
                            title: 'لا توجد إشعارات',
                            message:
                                'ستصلكِ هنا تأكيدات الحجز وعروض قائمة الانتظار وتنبيهات الدور.',
                          ),
                        if (fresh.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text('جديدة', style: AppText.h3),
                              const Spacer(),
                              StatusChip(
                                label: '${fresh.length} جديدة',
                                tone: StatusTone.accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final n in fresh)
                            _Tile(n: n, onTap: () => c.open(n)),
                        ],
                        if (older.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('سابقًا', style: AppText.h3),
                          const SizedBox(height: 10),
                          for (final n in older)
                            _Tile(n: n, onTap: () => c.open(n)),
                        ],
                        if (c.loadingMore.value) const LoadingView(),
                      ],
                    ),
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

class _Tile extends StatelessWidget {
  const _Tile({required this.n, required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final linkable = DeepLinks.resolve(n.url) != null;
    return EloraCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: linkable ? onTap : null,
      color: n.read ? AppColors.white : AppColors.blush,
      borderColor: n.read ? AppColors.borderFaint : AppColors.blushStrong,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: n.read ? AppColors.cardFill : AppColors.blushStrong,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(n),
                  size: 19,
                  color: AppColors.primaryDeep,
                ),
              ),
              if (!n.read)
                const PositionedDirectional(
                  top: -3,
                  end: -3,
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(n.title, style: AppText.title)),
                    Text(
                      n.createdLabel ?? Fmt.clock(n.createdAt),
                      style: AppText.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                if (n.body != null) Text(n.body!, style: AppText.caption),
                if (linkable)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LinkButton(label: 'عرض التفاصيل', onPressed: onTap),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
