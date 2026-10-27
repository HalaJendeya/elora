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

class ServiceDetailsController extends LoadController<Service> {
  ServiceDetailsController(this._repo, this.serviceId);

  final CatalogRepository _repo;
  final int serviceId;

  @override
  Future<Service> fetch() => _repo.service(serviceId);

  void book() =>
      AuthGate.open(Routes.booking, arguments: {'serviceId': serviceId});
}

class ServiceDetailsBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as int;
    Get.lazyPut(() => ServiceDetailsController(Get.find(), id), tag: '$id');
  }
}

/// Figma 02.09 / 02.10 / 02.11 (group variant).
class ServiceDetailsScreen extends GetView<ServiceDetailsController> {
  const ServiceDetailsScreen({super.key, required this.id});

  final int id;

  @override
  String? get tag => '$id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadBuilder<Service>(
        controller: controller,
        builder: (s) => Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    automaticallyImplyLeading: false,
                    leading: const Padding(
                      padding: EdgeInsets.all(8),
                      child: BackCircleButton(),
                    ),
                    leadingWidth: 60,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _Gallery(service: s),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    sliver: SliverList.list(
                      children: [
                        if (s.categoryName != null)
                          Text(s.categoryName!, style: AppText.eyebrow),
                        Text(
                          s.name,
                          style: AppText.display.copyWith(fontSize: 27),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              Fmt.price(s.finalPrice, currency()),
                              style: AppText.price,
                            ),
                            if (s.hasDiscount) ...[
                              const SizedBox(width: 8),
                              Text(
                                Fmt.price(s.price, currency()),
                                style: AppText.caption.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (s.discountPercent != null)
                                StatusChip(
                                  label: 'خصم ${s.discountPercent}%',
                                  tone: StatusTone.accent,
                                ),
                            ],
                            const Spacer(),
                            const Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Fmt.duration(
                                s.durationMinutes,
                                label: s.durationLabel,
                              ),
                              style: AppText.caption,
                            ),
                          ],
                        ),
                        if (s.isGroup) ...[
                          const SizedBox(height: 14),
                          NoticeBox(
                            title: 'جلسة جماعية',
                            message:
                                'تتسع لـ ${s.capacity} مشاركات. يظهر عدد المقاعد المتبقية عند اختيار الوقت.',
                            tone: StatusTone.warning,
                          ),
                        ],
                        const SizedBox(height: 16),
                        EloraCard(
                          onTap: () => Get.toNamed(
                            Routes.serviceReviews,
                            arguments: {'id': s.id, 'name': s.name},
                          ),
                          child: Row(
                            children: [
                              Text(
                                s.rating.average.toStringAsFixed(1),
                                style: AppText.h2.copyWith(
                                  fontFamily: AppText.latin,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StarRow(rating: s.rating.average),
                                  Text(
                                    '${s.rating.count} تقييمًا',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'كل التقييمات',
                                style: AppText.caption.copyWith(
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_left_rounded,
                                size: 18,
                                color: AppColors.primaryDeep,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text('عن هذه التجربة', style: AppText.h2),
                        const SizedBox(height: 6),
                        Text(
                          s.description ??
                              'لم يُضف وصف لهذه الخدمة بعد. تواصلي معنا لمعرفة المزيد.',
                          style: AppText.body,
                        ),
                        if (s.attributes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final a in s.attributes)
                                StatusChip(label: a),
                            ],
                          ),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('تُقدّمها', style: AppText.h2),
                            ),
                            if (s.staff.isNotEmpty)
                              LinkButton(
                                label: 'عرض الكل',
                                color: AppColors.textSecondary,
                                onPressed: () => Get.toNamed(
                                  Routes.specialists,
                                  arguments: {
                                    'serviceId': s.id,
                                    'serviceName': s.name,
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (s.staff.isEmpty)
                          const Text(
                            'ستختار لكِ الصالون أفضل أخصائية متاحة.',
                            style: AppText.caption,
                          )
                        else
                          Wrap(
                            spacing: 18,
                            runSpacing: 12,
                            children: [
                              for (final st in s.staff)
                                GestureDetector(
                                  onTap: () => Get.toNamed(
                                    Routes.specialist,
                                    arguments: st.id,
                                  ),
                                  child: Column(
                                    children: [
                                      PersonAvatar(
                                        name: st.name,
                                        imageUrl: st.avatar,
                                        initials: st.initials,
                                        color: st.color,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(st.name, style: AppText.caption),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        if (s.related.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('خدمات مشابهة', style: AppText.h2),
                          const SizedBox(height: 10),
                          for (final r in s.related)
                            ServiceCard(
                              service: r,
                              onTap: () => Get.toNamed(
                                Routes.serviceDetails,
                                arguments: r.id,
                                preventDuplicates: false,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SummaryBar(
              caption: 'السعر',
              price: Fmt.price(s.finalPrice, currency()),
              button: PrimaryButton(
                label: s.isGroup ? 'احجزي مقعدكِ' : 'احجزي الآن',
                onPressed: controller.book,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.service});

  final Service service;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.service.images.isNotEmpty
        ? widget.service.images
        : [widget.service.image];
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => NetImage(images[i]),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
