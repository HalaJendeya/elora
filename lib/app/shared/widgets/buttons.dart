import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.showArrow = false,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool showArrow;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final bg = destructive ? AppColors.danger : AppColors.primary;
    final text = Text(
      loading ? (loadingLabel ?? label) : label,
      style: AppText.button,
      overflow: TextOverflow.ellipsis,
    );
    Widget child;
    if (loading) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: text),
          const SizedBox(width: 10),
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: AppColors.white,
            ),
          ),
        ],
      );
    } else if (showArrow) {
      child = Row(
        children: [
          Expanded(child: text),
          // Forward arrow points to the reading end (left in RTL).
          const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            textDirection: TextDirection.rtl,
          ),
        ],
      );
    } else if (icon != null) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: text),
        ],
      );
    } else {
      child = text;
    }
    return Semantics(
      button: true,
      enabled: onPressed != null && !loading,
      label: label,
      excludeSemantics: true,
      child: FilledButton(
        onPressed: loading ? () {} : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: loading ? bg.withValues(alpha: 0.7) : bg,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: child,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              label,
              style: AppText.button.copyWith(color: AppColors.primaryDeep),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Underlined text link (e.g. "إنشاء حساب").
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primaryDeep,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: AppText.caption.copyWith(
                color: color,
                decoration: TextDecoration.underline,
                decorationColor: color.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
