import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Labelled field from the auth/profile design: small label on top, value
/// below, inside a 14-radius translucent white box. Errors turn the border
/// rose and print the message underneath.
class EloraTextField extends StatelessWidget {
  const EloraTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.onToggleObscure,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
    this.inputFormatters,
    this.textDirection,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final String? helper;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final Iterable<String>? autofillHints;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 4),
          decoration: BoxDecoration(
            color: hasError
                ? AppColors.blush.withValues(alpha: 0.6)
                : AppColors.fieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? AppColors.primary : AppColors.border,
              width: 1.3,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.caption.copyWith(
                        color: hasError
                            ? AppColors.primaryDeep
                            : AppColors.textSecondary,
                      ),
                    ),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      obscureText: obscure,
                      keyboardType: keyboardType,
                      textInputAction: textInputAction,
                      autofillHints: autofillHints,
                      maxLines: obscure ? 1 : maxLines,
                      minLines: minLines,
                      maxLength: maxLength,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      inputFormatters: inputFormatters,
                      textDirection: textDirection,
                      style: AppText.bodyStrong,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hint,
                        hintStyle: AppText.body.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleObscure != null)
                IconButton(
                  onPressed: onToggleObscure,
                  tooltip: obscure ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (hasError || helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4, left: 4),
            child: Text(
              hasError ? error! : helper!,
              style: AppText.caption.copyWith(
                color: hasError
                    ? AppColors.primaryDeep
                    : AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded pill chip used for filters, reasons and selections.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.primary
            : AppColors.cardFill.withValues(alpha: 0.7),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: selected
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppText.caption.copyWith(
                      fontSize: 12,
                      color: selected
                          ? AppColors.white
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill segmented control (upcoming / past).
class SegmentedPills extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? AppColors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      labels[i],
                      style: AppText.caption.copyWith(
                        fontSize: 12,
                        color: i == index
                            ? AppColors.primaryDeep
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
