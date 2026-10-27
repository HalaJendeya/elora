import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/session/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/catalog.dart';
import '../../data/models/place.dart';
import 'display.dart';
import 'elora_scaffold.dart';

/// Maps the backend's category `icon` keys to glyphs.
IconData categoryIcon(String? key) {
  switch (key) {
    case 'scissors':
    case 'hair':
      return Icons.content_cut_rounded;
    case 'brush':
    case 'makeup':
    case 'palette':
      return Icons.brush_outlined;
    case 'nail':
    case 'nails':
    case 'hand':
      return Icons.back_hand_outlined;
    case 'face':
    case 'skin':
      return Icons.face_retouching_natural_outlined;
    case 'sparkles':
      return Icons.auto_awesome_outlined;
    default:
      return Icons.spa_outlined;
  }
}

String currency() => Get.find<PlaceService>().currency;

/// Service row card (Figma 02.03).
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EloraCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppText.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        Fmt.duration(
                          service.durationMinutes,
                          label: service.durationLabel,
                        ),
                        style: AppText.caption,
                      ),
                    ),
                    if (service.isGroup) ...[
                      const SizedBox(width: 8),
                      const StatusChip(
                        label: 'جلسة جماعية',
                        tone: StatusTone.accent,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      Fmt.price(service.finalPrice, currency()),
                      style: AppText.price.copyWith(fontSize: 16),
                    ),
                    if (service.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        Fmt.price(service.price, currency()),
                        style: AppText.caption.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (service.rating.count > 0)
                      RatingLabel(average: service.rating.average),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            height: 84,
            child: NetImage(service.thumb ?? service.image, radius: 16),
          ),
        ],
      ),
    );
  }
}

/// Tall image card from the home "featured" carousel.
class FeaturedServiceCard extends StatelessWidget {
  const FeaturedServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.width = 220,
  });

  final Service service;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: service.name,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetImage(service.image ?? service.thumb),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerEnd,
                      end: AlignmentDirectional.centerStart,
                      colors: [Color(0x00251C18), Color(0xAD251C18)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.categoryName ?? 'طقوس ÉLORA',
                        style: AppText.caption.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service.name,
                        style: AppText.display.copyWith(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '${Fmt.duration(service.durationMinutes, label: service.durationLabel)} · ${Fmt.price(service.finalPrice, currency())}',
                        style: AppText.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (service.rating.count > 0)
                  PositionedDirectional(
                    top: 16,
                    end: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: RatingLabel(average: service.rating.average),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Specialist list row (Figma 03.01).
class StaffCard extends StatelessWidget {
  const StaffCard({super.key, required this.staff, required this.onTap});

  final Staff staff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EloraCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          PersonAvatar(
            name: staff.name,
            imageUrl: staff.avatar,
            initials: staff.initials,
            color: staff.color,
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name, style: AppText.title),
                if (staff.title != null)
                  Text(
                    staff.title!,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                RatingLabel(
                  average: staff.rating.average,
                  count: staff.rating.count,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// Weekly hours table (salon & specialist).
class HoursTable extends StatelessWidget {
  const HoursTable({super.key, required this.days, this.closedLabel = 'مغلق'});

  final List<OpeningDay> days;
  final String closedLabel;

  @override
  Widget build(BuildContext context) {
    return EloraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(days[i].label, style: AppText.bodyStrong),
                  const Spacer(),
                  Text(
                    days[i].open && days[i].ranges.isNotEmpty
                        ? days[i].ranges.join('  ·  ')
                        : closedLabel,
                    textDirection: TextDirection.ltr,
                    style: days[i].open
                        ? AppText.bodyStrong
                        : AppText.caption.copyWith(
                            color: AppColors.primaryDeep,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Review card with optional salon reply (Figma 04.03).
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return EloraCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName ?? 'زائرة',
                  style: AppText.bodyStrong,
                ),
              ),
              StarRow(rating: review.rating),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 6),
            Text(review.comment!, style: AppText.body),
          ],
          if (review.createdLabel != null || review.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              review.createdLabel ?? Fmt.dayMonth(review.createdAt),
              style: AppText.caption.copyWith(fontSize: 10.5),
            ),
          ],
          if (review.reply != null) ...[
            const SizedBox(height: 12),
            NoticeBox(title: 'ردّ ÉLORA', message: review.reply),
          ],
        ],
      ),
    );
  }
}

/// Rating summary with 5→1 distribution bars.
class RatingSummary extends StatelessWidget {
  const RatingSummary({super.key, required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.distribution.values.fold<int>(0, (a, b) => a + b);
    return EloraCard(
      child: Row(
        children: [
          Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: AppText.h1.copyWith(
                  fontFamily: AppText.latin,
                  fontSize: 30,
                ),
              ),
              StarRow(rating: summary.average),
              const SizedBox(height: 2),
              Text('${summary.total} تقييمًا', style: AppText.caption),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: Text(
                            '$star',
                            style: AppText.caption.copyWith(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              value: total == 0
                                  ? 0
                                  : (summary.distribution[star] ?? 0) / total,
                              backgroundColor: AppColors.cardFill,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
