import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Pill button used on the welcome screen. Outlined variant can sit on the
/// dark photo ([onDark]) or on the cream background.
class WelcomeButton extends StatelessWidget {
  const WelcomeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.onDark = false,
    this.showArrow = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool onDark;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
    );

    if (isOutlined) {
      final fg = onDark ? AppColors.white : AppColors.primary;
      return OutlinedButton(
        onPressed: onPressed,
        style: style.copyWith(
          foregroundColor: WidgetStatePropertyAll(fg),
          side: WidgetStatePropertyAll(
            BorderSide(color: onDark ? Colors.white70 : AppColors.primary),
          ),
        ),
        child: Text(label, style: AppText.button.copyWith(color: fg)),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppText.button),
          if (showArrow) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ],
      ),
    );
  }
}
