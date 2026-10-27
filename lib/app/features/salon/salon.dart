import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/session/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/catalog.dart';
import '../../data/models/place.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../routes/app_routes.dart';
import '../../shared/controllers/load_controller.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';

class SalonController extends LoadController<Place> {
  SalonController(this._place);

  final PlaceService _place;

  @override
  Future<Place> fetch() => _place.load(force: true);
}

/// Figma 01.07 — hours, booking policy, contact.
class SalonScreen extends GetView<SalonController> {
  const SalonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            Expanded(
              child: LoadBuilder<Place>(
                controller: controller,
                builder: (p) {
                  final rules = p.booking;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: p.logo != null
                              ? NetImage(p.logo, fit: BoxFit.contain)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'معلومات الصالون',
                        style: AppText.eyebrow,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Center(child: Wordmark(size: 24)),
                      const SizedBox(height: 10),
                      Center(
                        child: StatusChip(
                          label: p.openNow ? 'مفتوح الآن' : 'مغلق الآن',
                          tone: p.openNow
                              ? StatusTone.success
                              : StatusTone.accent,
                        ),
                      ),
                      if (p.description != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          p.description!,
                          style: AppText.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Divider(),
                      ),
                      const _Heading(
                        eyebrow: 'خططي لزيارتكِ',
                        title: 'ساعات العمل',
                        icon: Icons.schedule_rounded,
                      ),
                      HoursTable(days: p.openingHours),
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: LinkButton(
                          label: 'أفضل وقت للزيارة',
                          icon: Icons.insights_outlined,
                          onPressed: () => Get.toNamed(Routes.busyHours),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _Heading(
                        eyebrow: 'قبل موعدكِ',
                        title: 'سياسة المواعيد',
                        icon: Icons.event_note_outlined,
                      ),
                      NoticeBox(
                        title: 'قواعد الحجز',
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            children: [
                              _Rule('نافذة الحجز', '${rules.windowDays} يومًا'),
                              _Rule(
                                'أقل مهلة للحجز',
                                '${rules.minNoticeMinutes} دقيقة',
                              ),
                              _Rule(
                                'الإلغاء المجاني قبل',
                                '${rules.cancelBeforeHours} ساعة',
                              ),
                              if (rules.maxActiveBookings != null)
                                _Rule(
                                  'أقصى حجوزات نشطة',
                                  '${rules.maxActiveBookings}',
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (p.address != null || p.phone != null) ...[
                        const SizedBox(height: 22),
                        const _Heading(
                          eyebrow: 'تواصلي معنا',
                          title: 'العنوان والتواصل',
                          icon: Icons.place_outlined,
                        ),
                        EloraCard(
                          child: Column(
                            children: [
                              if (p.address != null)
                                InfoRow(label: 'العنوان', value: p.address!),
                              if (p.phone != null)
                                InfoRow(
                                  label: 'الهاتف',
                                  value: p.phone!,
                                  valueWidget: Text(
                                    p.phone!,
                                    textDirection: TextDirection.ltr,
                                    style: AppText.bodyStrong,
                                  ),
                                ),
                              if (p.whatsapp != null)
                                InfoRow(
                                  label: 'واتساب',
                                  value: p.whatsapp!,
                                  valueWidget: Text(
                                    p.whatsapp!,
                                    textDirection: TextDirection.ltr,
                                    style: AppText.bodyStrong,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: AppText.eyebrow),
              Text(title, style: AppText.h2),
            ],
          ),
        ),
        Icon(icon, color: AppColors.primary, size: 20),
      ],
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppText.caption)),
        Text(value, style: AppText.bodyStrong.copyWith(fontSize: 12)),
      ],
    ),
  );
}

class BusyHoursController extends LoadController<BusyHours> {
  BusyHoursController(this._repo);

  final CatalogRepository _repo;

  @override
  Future<BusyHours> fetch() => _repo.busyHours();
}

/// Figma 03.05 / 03.06 — heat map + recommended times.
class BusyHoursScreen extends GetView<BusyHoursController> {
  const BusyHoursScreen({super.key});

  static Color levelColor(double? level) {
    if (level == null) return AppColors.borderFaint;
    return Color.lerp(
      AppColors.cardFill,
      AppColors.primary,
      level.clamp(0, 1),
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EloraHeader(),
            Expanded(
              child: LoadBuilder<BusyHours>(
                controller: controller,
                builder: (b) => RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      const PageTitle(
                        eyebrow: 'اختاري وقتًا أهدأ',
                        title: 'أفضل وقت للزيارة',
                        padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
                      ),
                      _NowCard(hours: b),
                      const SizedBox(height: 16),
                      if (b.isEmpty)
                        const EmptyView(
                          title: 'لا تتوفر بيانات بعد',
                          message: 'ستظهر أوقات الازدحام بعد أول الزيارات.',
                        )
                      else ...[
                        _Legend(),
                        const SizedBox(height: 8),
                        EloraCard(
                          padding: const EdgeInsets.all(12),
                          child: _HeatMap(hours: b),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (b.bestTimes.isNotEmpty)
                        EloraCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('أوقات ننصح بها', style: AppText.h2),
                              for (final t in b.bestTimes) ...[
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(t.label, style: AppText.bodyStrong),
                                      const Spacer(),
                                      Text(
                                        t.time,
                                        textDirection: TextDirection.ltr,
                                        style: AppText.bodyStrong.copyWith(
                                          color: AppColors.primaryDeep,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              const Text(
                                'هذه الأوقات توصيات مبنية على الازدحام وليست ضمانًا لتوفر موعد.',
                                style: AppText.caption,
                              ),
                            ],
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

class _NowCard extends StatelessWidget {
  const _NowCard({required this.hours});

  final BusyHours hours;

  @override
  Widget build(BuildContext context) {
    final level = hours.nowLevel;
    final title = !hours.nowOpen
        ? 'الصالون خارج ساعات العمل'
        : level == null || level < 0.34
        ? 'ازدحام منخفض'
        : level < 0.67
        ? 'ازدحام متوسط'
        : 'ازدحام مرتفع';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFEFEDE6), Color(0xFFF6F2EC)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h2),
                if (hours.nowOpen)
                  const Text(
                    'وقت مناسب لزيارة هادئة دون انتظار طويل.',
                    style: AppText.caption,
                  ),
              ],
            ),
          ),
          StatusChip(
            label:
                hours.nowLabel ?? (hours.nowOpen ? 'مفتوح الآن' : 'مغلق الآن'),
            tone: hours.nowOpen ? StatusTone.success : StatusTone.accent,
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('هادئ', style: AppText.caption),
      const SizedBox(width: 6),
      for (final l in [0.0, 0.33, 0.66, 1.0])
        Container(
          width: 14,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: BusyHoursScreen.levelColor(l),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      const SizedBox(width: 6),
      const Text('أكثر ازدحامًا', style: AppText.caption),
    ],
  );
}

class _HeatMap extends StatelessWidget {
  const _HeatMap({required this.hours});

  final BusyHours hours;

  @override
  Widget build(BuildContext context) {
    final columns = hours.grid.isEmpty ? 0 : hours.grid.first.hours.length;
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 62),
            for (var i = 0; i < columns; i++)
              Expanded(
                child: Text(
                  '${hours.grid.first.hours[i].hour}',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(fontSize: 9.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final day in hours.grid)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Semantics(
              label: day.closed ? '${day.label}: مغلق' : day.label,
              child: Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(
                      day.label,
                      style: AppText.caption.copyWith(fontSize: 11),
                    ),
                  ),
                  for (final h in day.hours)
                    Expanded(
                      child: Container(
                        height: 22,
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: h.open
                              ? BusyHoursScreen.levelColor(h.level)
                              : const Color(0x0D7D716A),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
