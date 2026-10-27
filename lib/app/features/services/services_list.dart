import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/catalog.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../shared/widgets/form_fields.dart';

class ServicesController extends GetxController {
  ServicesController(this._repo);

  final CatalogRepository _repo;
  static const perPage = 15;

  final search = TextEditingController();
  final scroll = ScrollController();
  final _term = ''.obs;
  Worker? _debounce;

  final query = const ServiceQuery().obs;
  final items = <Service>[].obs;
  final categories = <Category>[].obs;
  final staff = <Staff>[].obs;
  final total = 0.obs;
  final loading = true.obs;
  final loadingMore = false.obs;
  final error = RxnString();
  final pageError = RxnString();
  int _page = 1;
  int _lastPage = 1;
  int _request = 0;

  bool get hasMore => _page < _lastPage;

  @override
  void onInit() {
    super.onInit();
    _debounce = debounce<String>(_term, (value) {
      query.value = query.value.copyWith(q: value);
      refreshList();
    }, time: const Duration(milliseconds: 400));
    scroll.addListener(() {
      if (scroll.position.pixels > scroll.position.maxScrollExtent - 300) {
        loadMore();
      }
    });
    _loadFilters();
    refreshList();
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([_repo.categories(), _repo.staff()]);
      categories.assignAll(results[0] as List<Category>);
      staff.assignAll(results[1] as List<Staff>);
    } on ApiException {
      // Filters are optional; the list still works without them.
    }
  }

  void onSearchChanged(String value) => _term.value = value;

  void clearSearch() {
    search.clear();
    _term.value = '';
    query.value = query.value.copyWith(q: '');
    refreshList();
  }

  void applyCategory(int? id) {
    query.value = query.value.copyWith(categoryId: () => id);
    refreshList();
  }

  void applyFilters(ServiceQuery value) {
    query.value = value.copyWith(
      q: query.value.q ?? '',
      categoryId: () => query.value.categoryId,
    );
    refreshList();
  }

  void resetFilters() {
    search.clear();
    _term.value = '';
    query.value = const ServiceQuery();
    refreshList();
  }

  Future<void> refreshList() async {
    final request = ++_request;
    error.value = null;
    pageError.value = null;
    loading.value = true;
    try {
      final page = await _repo.services(query.value, page: 1, perPage: perPage);
      if (request != _request) return; // a newer query superseded this one
      items.assignAll(page.items);
      total.value = page.meta.total;
      _page = page.meta.page;
      _lastPage = page.meta.lastPage;
    } on ApiException catch (e) {
      if (request == _request) error.value = e.message;
    } finally {
      if (request == _request) loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (loading.value ||
        loadingMore.value ||
        !hasMore ||
        pageError.value != null) {
      return;
    }
    final request = _request;
    loadingMore.value = true;
    try {
      final page = await _repo.services(
        query.value,
        page: _page + 1,
        perPage: perPage,
      );
      if (request != _request) return;
      items.addAll(page.items);
      _page = page.meta.page;
      _lastPage = page.meta.lastPage;
    } on ApiException catch (e) {
      if (request == _request) pageError.value = e.message;
    } finally {
      loadingMore.value = false;
    }
  }

  void retryMore() {
    pageError.value = null;
    loadMore();
  }

  @override
  void onClose() {
    _debounce?.dispose();
    search.dispose();
    scroll.dispose();
    super.onClose();
  }
}

class ServicesView extends GetView<ServicesController> {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const EloraHeader(showBack: false),
          const PageTitle(
            eyebrow: 'اكتشفي ما يناسبكِ',
            title: 'خدماتنا',
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsetsDirectional.only(
                      start: 14,
                      end: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderSoft,
                        width: 1.3,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: c.search,
                            onChanged: c.onSearchChanged,
                            textInputAction: TextInputAction.search,
                            style: AppText.bodyStrong,
                            decoration: InputDecoration(
                              hintText: 'ابحثي عن خدمة…',
                              hintStyle: AppText.body,
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        Obx(
                          () => c.query.value.q?.isNotEmpty == true
                              ? IconButton(
                                  tooltip: 'مسح البحث',
                                  onPressed: c.clearSearch,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  final count = c.query.value.advancedCount;
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    backgroundColor: AppColors.textPrimary,
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => showServiceFilters(c),
                        child: const SizedBox.square(
                          dimension: 48,
                          child: Icon(
                            Icons.tune_rounded,
                            color: AppColors.white,
                            semanticLabel: 'تصفية',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: Obx(() {
              final selected = c.query.value.categoryId;
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  PillChip(
                    label: 'الكل',
                    selected: selected == null,
                    onTap: () => c.applyCategory(null),
                  ),
                  for (final cat in c.categories) ...[
                    const SizedBox(width: 8),
                    PillChip(
                      label: cat.shortName,
                      selected: selected == cat.id,
                      onTap: () => c.applyCategory(cat.id),
                    ),
                  ],
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      c.loading.value ? '' : '${c.total.value} خدمة',
                      style: AppText.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _sortLabel(c.query.value),
                      style: AppText.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.loading.value) {
                return const SingleChildScrollView(
                  child: SkeletonList(count: 4, height: 110),
                );
              }
              if (c.error.value != null) {
                return ErrorView(
                  message: c.error.value!,
                  onRetry: c.refreshList,
                );
              }
              if (c.items.isEmpty) {
                return SingleChildScrollView(
                  child: EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'لم نجد خدمات مطابقة',
                    message: 'جرّبي كلمات أخرى أو أزيلي بعض الفلاتر.',
                    actionLabel: 'مسح الفلاتر',
                    onAction: c.resetFilters,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: c.refreshList,
                child: ListView.builder(
                  controller: c.scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: c.items.length + 1,
                  itemBuilder: (context, i) {
                    if (i < c.items.length) {
                      final s = c.items[i];
                      return ServiceCard(
                        service: s,
                        onTap: () =>
                            Get.toNamed(Routes.serviceDetails, arguments: s.id),
                      );
                    }
                    return Obx(() {
                      if (c.loadingMore.value) return const LoadingView();
                      if (c.pageError.value != null) {
                        return Center(
                          child: LinkButton(
                            label: 'تعذّر تحميل المزيد — إعادة المحاولة',
                            onPressed: c.retryMore,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          c.hasMore ? '' : 'وصلتِ إلى نهاية القائمة',
                          style: AppText.caption,
                          textAlign: TextAlign.center,
                        ),
                      );
                    });
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  static String _sortLabel(ServiceQuery q) => switch (q.sort) {
    'price' => q.order == 'desc' ? 'الأعلى سعرًا' : 'الأقل سعرًا',
    'duration' => 'الأقصر مدة',
    'popular' => 'الأكثر طلبًا',
    'rating' => 'الأعلى تقييمًا',
    'name' => 'الاسم',
    _ => 'الترتيب الافتراضي',
  };
}

/// Advanced filter sheet (Figma 02.06 / 02.07). Edits a local copy and only
/// applies on confirm.
Future<void> showServiceFilters(ServicesController c) {
  final draft = c.query.value.obs;
  const durations = [30, 45, 60, 90, 120];
  const sorts = [
    ('order', null, 'افتراضي'),
    ('popular', null, 'الأكثر طلبًا'),
    ('price', 'asc', 'الأقل سعرًا'),
    ('price', 'desc', 'الأعلى سعرًا'),
    ('duration', 'asc', 'الأقصر مدة'),
    ('rating', 'desc', 'الأعلى تقييمًا'),
  ];
  Widget label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: AppText.bodyStrong),
  );
  return Get.bottomSheet(
    SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Get.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Obx(() {
            final q = draft.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('تصفية الخدمات', style: AppText.h2),
                    ),
                    LinkButton(
                      label: 'إعادة ضبط',
                      color: AppColors.textSecondary,
                      onPressed: () => draft.value = ServiceQuery(
                        q: q.q,
                        categoryId: q.categoryId,
                      ),
                    ),
                  ],
                ),
                if (c.staff.isNotEmpty) ...[
                  label('الأخصائية'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PillChip(
                        label: 'الكل',
                        selected: q.staffId == null,
                        onTap: () =>
                            draft.value = q.copyWith(staffId: () => null),
                      ),
                      for (final s in c.staff)
                        PillChip(
                          label: s.name,
                          selected: q.staffId == s.id,
                          onTap: () =>
                              draft.value = q.copyWith(staffId: () => s.id),
                        ),
                    ],
                  ),
                ],
                label('المدة القصوى'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillChip(
                      label: 'أي مدة',
                      selected: q.maxDuration == null,
                      onTap: () =>
                          draft.value = q.copyWith(maxDuration: () => null),
                    ),
                    for (final d in durations)
                      PillChip(
                        label: '$d دقيقة',
                        selected: q.maxDuration == d,
                        onTap: () =>
                            draft.value = q.copyWith(maxDuration: () => d),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: q.featured,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'الخدمات المميزة فقط',
                    style: AppText.bodyStrong,
                  ),
                  onChanged: (v) => draft.value = q.copyWith(featured: v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: q.group,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'الجلسات الجماعية',
                    style: AppText.bodyStrong,
                  ),
                  onChanged: (v) => draft.value = q.copyWith(group: v),
                ),
                label('الترتيب'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (sort, order, text) in sorts)
                      PillChip(
                        label: text,
                        selected:
                            (q.sort ?? 'order') == sort &&
                            (sort != 'price' || q.order == order),
                        onTap: () => draft.value = q.copyWith(
                          sort: () => sort == 'order' ? null : sort,
                          order: () => order,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'تطبيق الفلاتر',
                  onPressed: () {
                    c.applyFilters(draft.value);
                    Get.back();
                  },
                ),
              ],
            );
          }),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  );
}
