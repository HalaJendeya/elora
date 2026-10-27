import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Tinted SVG from assets/icons.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 20, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 40,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: AppColors.white,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.borderSoft, width: 1.3),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: size * 0.5, color: color),
          ),
        ),
      ),
    );
  }
}

class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CircleIconButton(
    // Directional chevron: points right in RTL (towards the start edge).
    icon: Icons.arrow_back_ios_new_rounded,
    tooltip: 'رجوع',
    onTap: onTap ?? () => Get.back(),
  );
}

/// Wordmark header used on every inner screen: back · ÉLORA · trailing.
class EloraHeader extends StatelessWidget {
  const EloraHeader({
    super.key,
    this.showBack = true,
    this.onBack,
    this.leading,
    this.trailing,
  });

  final bool showBack;
  final VoidCallback? onBack;

  /// Shown at the start edge when [showBack] is false.
  final Widget? leading;

  /// Shown at the end edge.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: showBack ? BackCircleButton(onTap: onBack) : leading,
              ),
            ),
            const Expanded(child: Center(child: Wordmark())),
            SizedBox(
              width: 72,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.size = 19,
    this.color = AppColors.textPrimary,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      'ÉLORA',
      textDirection: TextDirection.ltr,
      style: AppText.wordmark.copyWith(fontSize: size, color: color),
      textScaler: TextScaler.noScaling,
    ),
  );
}

/// Eyebrow + serif title + optional subtitle, start-aligned.
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.center = false,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final bool center;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = center ? TextAlign.center : TextAlign.start;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow!, style: AppText.eyebrow, textAlign: textAlign),
            const SizedBox(height: 4),
          ],
          Semantics(
            header: true,
            child: Text(title, style: AppText.display, textAlign: textAlign),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppText.body, textAlign: textAlign),
          ],
        ],
      ),
    );
  }
}

/// Section heading with eyebrow, serif title and optional "view all".
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel = 'عرض الكل',
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 28, 20, 12),
  });

  final String title;
  final String? eyebrow;
  final String actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) Text(eyebrow!, style: AppText.eyebrow),
                Semantics(header: true, child: Text(title, style: AppText.h2)),
              ],
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(48, 40),
              ),
              child: Text(actionLabel, style: AppText.caption),
            ),
        ],
      ),
    );
  }
}

/// White rounded card from the design (radius 20, faint border).
class EloraCard extends StatelessWidget {
  const EloraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppColors.white,
    this.borderColor = AppColors.borderFaint,
    this.radius = 20,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor, width: 1.3),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Bottom action area that respects the home indicator and keyboard.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        border: Border(top: BorderSide(color: AppColors.divider, width: 1.3)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: child,
        ),
      ),
    );
  }
}

/// Price summary + primary action, as on the booking steps.
class SummaryBar extends StatelessWidget {
  const SummaryBar({
    super.key,
    required this.caption,
    required this.price,
    required this.button,
  });

  final String caption;
  final String price;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: AppText.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(price, style: AppText.price),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(flex: 3, child: button),
        ],
      ),
    );
  }
}
