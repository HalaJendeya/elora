import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'buttons.dart';
import 'elora_scaffold.dart';

Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) return null;
  final v = int.tryParse(clean, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

/// Network image with brand placeholder (blush gradient + É).
class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = 0,
  });

  final String? url;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.cardFill, AppColors.blushStrong],
        ),
      ),
      child: Center(
        child: Text(
          'É',
          style: TextStyle(
            fontFamily: AppText.latin,
            fontSize: 28,
            color: AppColors.primaryDeep.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
    final child = url == null
        ? placeholder
        : Image.network(
            url!,
            fit: fit,
            // Server uploads send no CORS headers; on web fall back to an
            // <img> element. No effect on mobile.
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (_, _, _) => placeholder,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
          );
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}

/// Avatar with server photo or initials on the staff colour.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.initials,
    this.color,
    this.size = 56,
    this.online = false,
  });

  final String name;
  final String? imageUrl;
  final String? initials;
  final String? color;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final letter = (initials?.isNotEmpty ?? false)
        ? initials!
        : (name.trim().isEmpty
              ? 'É'
              : String.fromCharCode(name.trim().runes.first));
    final tone = parseHexColor(color) ?? AppColors.primary;
    return Semantics(
      label: name,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.cardFill, tone.withValues(alpha: 0.22)],
                  ),
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadow, blurRadius: 8),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                        errorBuilder: (_, _, _) => _letter(letter),
                      )
                    : _letter(letter),
              ),
            ),
            if (online)
              PositionedDirectional(
                end: size * 0.04,
                bottom: size * 0.04,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _letter(String letter) => Center(
    child: Text(
      letter,
      style: TextStyle(
        fontFamily: AppText.serif,
        fontSize: size * 0.4,
        color: AppColors.primaryDeep,
        height: 1,
      ),
    ),
  );
}

class RatingLabel extends StatelessWidget {
  const RatingLabel({
    super.key,
    required this.average,
    this.count,
    this.size = 12,
  });

  final double average;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'التقييم ${average.toStringAsFixed(1)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon('star', size: size),
          const SizedBox(width: 3),
          Text(
            count == null
                ? average.toStringAsFixed(1)
                : '${average.toStringAsFixed(1)} ($count)',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 12});

  final num rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          i <= rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppColors.gold,
        ),
    ],
  );
}

/// Small status pill ("مؤكد", "مفتوح الآن" …).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = switch (tone) {
      StatusTone.success => (
        AppColors.sageTint,
        AppColors.sageText,
        AppColors.sage,
      ),
      StatusTone.accent => (
        AppColors.blush,
        AppColors.primaryDeep,
        AppColors.primary,
      ),
      StatusTone.warning => (
        AppColors.cardFill,
        const Color(0xFF8A6A3D),
        AppColors.gold,
      ),
      StatusTone.neutral => (
        AppColors.cardFill,
        AppColors.textSecondary,
        AppColors.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.caption.copyWith(fontSize: 10.5, color: fg),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { success, accent, warning, neutral }

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

/// Skeleton blocks used for list loading states (design 02.08 / 07.06).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3, this.height = 88});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++)
        Container(
          height: height,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.cardFill.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
    ],
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.cardFill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: AppColors.primaryDeep, size: 26)
                : const Text(
                    'É',
                    style: TextStyle(
                      fontFamily: AppText.latin,
                      fontSize: 26,
                      color: AppColors.primaryDeep,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.h3, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: AppText.body, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 180,
              child: PrimaryButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyView(
    icon: Icons.wifi_tethering_error_rounded,
    title: 'تعذّر التحميل',
    message: message,
    actionLabel: onRetry == null ? null : 'إعادة المحاولة',
    onAction: onRetry,
  );
}

/// Inline notice box with a coloured start border (policies, warnings).
class NoticeBox extends StatelessWidget {
  const NoticeBox({
    super.key,
    required this.title,
    this.message,
    this.tone = StatusTone.accent,
    this.child,
  });

  final String title;
  final String? message;
  final StatusTone tone;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final (bg, edge, fg) = switch (tone) {
      StatusTone.success => (
        AppColors.sageTint,
        AppColors.sage,
        AppColors.sageText,
      ),
      StatusTone.warning => (
        AppColors.cardFill,
        AppColors.gold,
        const Color(0xFF8A6A3D),
      ),
      _ => (AppColors.blush, AppColors.primary, AppColors.primaryDeep),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: BorderDirectional(end: BorderSide(color: edge, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.bodyStrong.copyWith(color: fg)),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: AppText.caption),
          ],
          ?child,
        ],
      ),
    );
  }
}

/// Confirmation bottom sheet (leave waitlist, cancel ticket, logout).
Future<bool> showConfirmSheet({
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'تراجع',
  IconData icon = Icons.close_rounded,
  bool destructive = true,
}) async {
  final result = await Get.bottomSheet<bool>(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.blush,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryDeep),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.h2, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message, style: AppText.body, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: confirmLabel,
              destructive: destructive,
              onPressed: () => Get.back(result: true),
            ),
            const SizedBox(height: 4),
            LinkButton(
              label: cancelLabel,
              onPressed: () => Get.back(result: false),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  );
  return result ?? false;
}

void showMessage(String message, {bool error = false}) {
  final context = Get.context;
  if (context == null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.textPrimary,
      ),
    );
}

/// Row inside a details card: label at start, value at end.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child:
                  valueWidget ??
                  Text(
                    value,
                    style: AppText.bodyStrong,
                    textAlign: TextAlign.end,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
