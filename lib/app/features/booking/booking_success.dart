import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/session/place_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/booking.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../routes/app_nav.dart';

/// Check-in code. The server's `qr` format is unverified, so this accepts an
/// inline image, an image URL, or text to encode; anything that cannot be
/// encoded falls back to the plain code instead of throwing during build.
class BookingQr extends StatelessWidget {
  const BookingQr({
    super.key,
    required this.payload,
    this.fallback,
    this.size = 150,
  });

  final String payload;
  final String? fallback;
  final double size;

  static final _imageUrl = RegExp(
    r'^https?://\S+\.(png|jpe?g|webp|svg)(\?.*)?$',
    caseSensitive: false,
  );

  Widget _fallback() => SizedBox.square(
    dimension: size,
    child: Center(
      child: Text(
        fallback ?? '—',
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: AppText.h2.copyWith(fontFamily: AppText.latin),
      ),
    ),
  );

  Widget _image() {
    final p = payload.trim();
    if (p.startsWith('data:image/')) {
      final comma = p.indexOf(',');
      if (comma < 0) return _fallback();
      final header = p.substring(0, comma);
      final raw = p.substring(comma + 1);
      try {
        final bytes = header.contains(';base64')
            ? base64Decode(raw)
            : Uint8List.fromList(utf8.encode(Uri.decodeComponent(raw)));
        if (header.contains('svg')) {
          return SvgPicture.memory(bytes, width: size, height: size);
        }
        return Image.memory(
          bytes,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => _fallback(),
        );
      } on FormatException {
        return _fallback();
      }
    }
    if (_imageUrl.hasMatch(p)) {
      if (p.toLowerCase().contains('.svg')) {
        return SvgPicture.network(
          p,
          width: size,
          height: size,
          placeholderBuilder: (_) => _fallback(),
        );
      }
      return Image.network(
        p,
        width: size,
        height: size,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    final result = QrValidator.validate(
      data: p,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    if (!result.isValid || result.qrCode == null) return _fallback();
    return QrImageView.withQr(
      qr: result.qrCode!,
      size: size,
      padding: EdgeInsets.zero,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: AppColors.textPrimary,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      Semantics(label: 'رمز تسجيل الوصول', image: true, child: _image());
}

/// Figma 05.08.
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.booking});

  /// Captured when the route is created; never re-read from Get.arguments,
  /// which points at whichever route is current during later rebuilds.
  final Booking? booking;

  @override
  Widget build(BuildContext context) {
    final booking = this.booking;
    if (booking == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyView(
            icon: Icons.event_available_outlined,
            title: 'تم استلام حجزكِ',
            message: 'تجدين تفاصيله في مواعيدي.',
            actionLabel: 'مواعيدي',
            onAction: () => AppNav.toMain(tab: 2, refresh: true),
          ),
        ),
      );
    }
    final place = Get.find<PlaceService>().place.value;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppNav.toMain(tab: 0);
      },
      child: Scaffold(
        body: Stack(
          children: [
            PositionedDirectional(
              end: -80,
              top: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const Center(child: Wordmark()),
                  const SizedBox(height: 22),
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.blushStrong,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryDeep,
                        size: 30,
                      ),
                    ),
                  ),
                  const PageTitle(
                    eyebrow: 'تم الحجز بنجاح',
                    title: 'موعدكِ بانتظاركِ',
                    subtitle: 'نتطلع إلى استقبالكِ، ومنحكِ تجربة تستحقينها.',
                    center: true,
                    padding: EdgeInsets.fromLTRB(0, 12, 0, 14),
                  ),
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: booking.displayNumber),
                        );
                        showMessage('تم نسخ رقم الحجز');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardFill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('رقم الحجز', style: AppText.caption),
                            const SizedBox(width: 8),
                            Text(
                              booking.displayNumber,
                              textDirection: TextDirection.ltr,
                              style: AppText.bodyStrong.copyWith(
                                color: AppColors.primaryDeep,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy_rounded,
                              size: 15,
                              color: AppColors.primaryDeep,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (booking.qrPayload != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: EloraCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            BookingQr(
                              payload: booking.qrPayload!,
                              fallback: booking.code ?? booking.displayNumber,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أبرزي هذا الرمز عند وصولكِ',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  EloraCard(
                    child: Column(
                      children: [
                        _Line(
                          icon: Icons.calendar_month_outlined,
                          title: Fmt.dayMonth(booking.startsAt),
                          subtitle: [
                            Fmt.clock(booking.startsAt),
                            if (booking.durationMinutes != null)
                              Fmt.duration(booking.durationMinutes!),
                          ].where((e) => e.isNotEmpty).join(' · '),
                        ),
                        if (place?.address != null) ...[
                          const Divider(),
                          _Line(
                            icon: Icons.place_outlined,
                            title: 'ÉLORA',
                            subtitle: place!.address!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (booking.status == 'pending') ...[
                    const SizedBox(height: 12),
                    const NoticeBox(
                      title: 'بانتظار تأكيد الصالون',
                      message: 'سنرسل لكِ إشعارًا فور تأكيد الموعد.',
                      tone: StatusTone.warning,
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'عرض تفاصيل الموعد',
                    icon: Icons.event_available_outlined,
                    onPressed: () {
                      AppNav.toMain(tab: 2, refresh: true);
                      Get.toNamed(
                        Routes.appointment,
                        arguments: {'id': booking.id},
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: LinkButton(
                      label: 'العودة إلى الرئيسية',
                      onPressed: () => AppNav.toMain(tab: 0),
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

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title),
              Text(subtitle, style: AppText.caption),
            ],
          ),
        ),
        Icon(icon, color: AppColors.primary, size: 20),
      ],
    ),
  );
}
