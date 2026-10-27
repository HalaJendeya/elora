import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/booking.dart';
import '../../data/models/place.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/catalog_widgets.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../shared/widgets/form_fields.dart';
import 'booking_controller.dart';

class BookingFlowScreen extends GetView<BookingFlowController> {
  const BookingFlowScreen({super.key});

  static const _titles = [
    ('اختاري أخصائيتكِ', 'اختاري من تفضلين، أو دعي لنا مهمة إيجاد أقرب موعد.'),
    ('اختاري التاريخ والوقت', 'المواعيد المتاحة بتوقيت الصالون.'),
    ('تفاصيلكِ', 'ساعدينا في جعل تجربتكِ أكثر راحة وخصوصية.'),
    ('راجعي موعدكِ', 'خطوة أخيرة، تأكدي من التفاصيل قبل التأكيد.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final step = c.step.value;
      return PopScope(
        canPop: step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) c.back();
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: c.loading.value
                ? const LoadingView()
                : c.error.value != null
                ? Column(
                    children: [
                      const EloraHeader(),
                      Expanded(
                        child: ErrorView(
                          message: c.error.value!,
                          onRetry: c.retrySetup,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      EloraHeader(
                        onBack: () {
                          if (!c.back()) Get.back();
                        },
                        trailing: Text(
                          '${step + 1}/${BookingFlowController.steps}',
                          style: AppText.caption,
                        ),
                      ),
                      _Progress(step: step),
                      Expanded(
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            PageTitle(
                              eyebrow:
                                  'الخطوة ${step + 1} من ${BookingFlowController.steps}',
                              title: _titles[step].$1,
                              subtitle: _titles[step].$2,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                18,
                              ),
                            ),
                            switch (step) {
                              0 => const _StaffStep(),
                              1 => const _DateTimeStep(),
                              2 => const _DetailsStep(),
                              _ => const _ReviewStep(),
                            },
                          ],
                        ),
                      ),
                      _Bar(step: step),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'الخطوة ${step + 1} من 4',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < BookingFlowController.steps; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.primary : AppColors.cardFill,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Bar extends GetView<BookingFlowController> {
  const _Bar({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = controller.draft.value;
      final slot = d.slot;
      final caption = [
        d.service?.name ?? '',
        if (slot != null && d.day != null)
          '${Fmt.dayMonth(d.day!.dateValue)} · ${Fmt.time12(slot.time)}',
      ].where((e) => e.isNotEmpty).join(' · ');
      final last = step == BookingFlowController.steps - 1;
      return SummaryBar(
        caption: caption,
        price: Fmt.price(d.total, currency()),
        button: PrimaryButton(
          label: last ? 'تأكيد الموعد' : 'متابعة',
          loadingLabel: 'جارٍ التأكيد…',
          loading: controller.submitting.value,
          showArrow: true,
          onPressed: controller.canContinue ? controller.next : null,
        ),
      );
    });
  }
}

// ---------------------------------------------------------------- step 1

class _StaffStep extends GetView<BookingFlowController> {
  const _StaffStep();

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final d = c.draft.value;
        return Column(
          children: [
            _ChoiceCard(
              selected: d.anyStaff,
              onTap: () => c.selectStaff(null),
              leading: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.cardFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'É',
                  style: TextStyle(
                    fontFamily: AppText.latin,
                    fontSize: 24,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
              title: 'أي أخصائية متاحة',
              subtitle: 'سنختار لكِ أفضل موعد متاح',
              highlighted: true,
            ),
            if (c.staff.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('أو اختاري أخصائية', style: AppText.caption),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
            for (final s in c.staff)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceCard(
                  selected: d.staff?.id == s.id,
                  onTap: () => c.selectStaff(s.ref),
                  leading: PersonAvatar(
                    name: s.name,
                    imageUrl: s.avatar,
                    initials: s.initials,
                    color: s.color,
                    size: 56,
                  ),
                  title: s.name,
                  subtitle: s.title,
                  trailing: s.rating.count > 0
                      ? RatingLabel(average: s.rating.average)
                      : null,
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.highlighted = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: EloraCard(
        onTap: onTap,
        color: selected || highlighted
            ? const Color(0x29E9C9C3)
            : AppColors.white,
        borderColor: selected ? AppColors.primary : AppColors.borderFaint,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title),
                  if (subtitle != null) Text(subtitle!, style: AppText.caption),
                  if (trailing != null) ...[
                    const SizedBox(height: 4),
                    trailing!,
                  ],
                ],
              ),
            ),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.3),
        width: 1.3,
      ),
    ),
    alignment: Alignment.center,
    child: selected
        ? Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

// ---------------------------------------------------------------- step 2

class _DateTimeStep extends GetView<BookingFlowController> {
  const _DateTimeStep();

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      if (c.daysLoading.value && c.days.isEmpty) return const LoadingView();
      if (c.daysError.value != null) {
        return ErrorView(message: c.daysError.value!, onRetry: c.loadDays);
      }
      if (c.days.isEmpty) {
        return const EmptyView(
          title: 'لا توجد أيام متاحة',
          message: 'جرّبي أخصائية أخرى أو عودي لاحقًا.',
        );
      }
      final selected = c.draft.value.day;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              Fmt.monthYear(selected?.dateValue ?? c.days.first.dateValue),
              style: AppText.h2,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: c.days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final day = c.days[i];
                final isSel = selected?.date == day.date;
                return _DayCard(
                  day: day,
                  selected: isSel,
                  onTap: () => c.selectDay(day),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _Slots(),
        ],
      );
    });
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final AvailabilityDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = day.dateValue;
    final fg = selected
        ? AppColors.white
        : (day.available ? AppColors.textPrimary : AppColors.textSecondary);
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${day.label} ${date?.day ?? ''}، ${day.available ? '${day.slotsCount} موعدًا' : 'غير متاح'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 62,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderFaint,
            ),
          ),
          child: Opacity(
            opacity: day.available || selected ? 1 : 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.label,
                  style: AppText.caption.copyWith(fontSize: 10, color: fg),
                ),
                Text(
                  '${date?.day ?? ''}',
                  style: TextStyle(
                    fontFamily: AppText.latin,
                    fontSize: 22,
                    color: fg,
                    height: 1.3,
                  ),
                ),
                Text(
                  !day.open
                      ? 'مغلق'
                      : day.slotsCount == 0
                      ? 'ممتلئ'
                      : '${day.slotsCount} موعدًا',
                  style: AppText.caption.copyWith(fontSize: 9.5, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slots extends GetView<BookingFlowController> {
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      if (c.slotsLoading.value) return const LoadingView();
      if (c.slotsError.value != null) {
        return ErrorView(message: c.slotsError.value!, onRetry: c.loadSlots);
      }
      if (c.slots.isEmpty) {
        final day = c.draft.value.day;
        return EmptyView(
          icon: Icons.event_busy_outlined,
          title: day != null && !day.open
              ? 'الصالون مغلق في هذا اليوم'
              : 'لا توجد مواعيد متاحة',
          message: c.canJoinWaitlist.value
              ? 'انضمي إلى قائمة الانتظار وسنخبركِ فور توفر موعد.'
              : 'جرّبي يومًا آخر.',
          actionLabel: c.canJoinWaitlist.value ? 'انضمي لقائمة الانتظار' : null,
          onAction: c.canJoinWaitlist.value ? c.joinWaitlist : null,
        );
      }
      final groups = <(String, List<Slot>)>[
        ('صباحًا', c.slots.where((s) => s.hour < 12).toList()),
        (
          'بعد الظهر',
          c.slots.where((s) => s.hour >= 12 && s.hour < 17).toList(),
        ),
        ('مساءً', c.slots.where((s) => s.hour >= 17).toList()),
      ].where((g) => g.$2.isNotEmpty);
      final selected = c.draft.value.slot?.startsAt;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (label, list) in groups) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(label, style: AppText.h3),
                  const SizedBox(width: 10),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, box) {
                  final cols = box.maxWidth > 420 ? 4 : 3;
                  final w = (box.maxWidth - (cols - 1) * 8) / cols;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in list)
                        SizedBox(
                          width: w,
                          child: _SlotChip(
                            slot: s,
                            selected: s.startsAt == selected,
                            showSeats: c.draft.value.service?.isGroup ?? false,
                            onTap: () => c.selectSlot(s),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
    this.showSeats = false,
  });

  final Slot slot;
  final bool showSeats;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderSoft,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Fmt.time12(slot.time),
                  style: AppText.bodyStrong.copyWith(
                    color: selected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
                if (showSeats && slot.seatsLeft != null)
                  Text(
                    '${slot.seatsLeft} مقاعد',
                    style: AppText.caption.copyWith(
                      fontSize: 9.5,
                      color: selected
                          ? Colors.white70
                          : AppColors.textSecondary,
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

// ---------------------------------------------------------------- step 3

class _DetailsStep extends GetView<BookingFlowController> {
  const _DetailsStep();

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EloraTextField(
            label: 'ملاحظات للأخصائية (اختياري)',
            controller: c.notes,
            hint: 'أخبري الأخصائية بما تفضلينه…',
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
          ),
          for (final f in c.intakeFields) ...[
            const SizedBox(height: 12),
            _IntakeQuestion(field: f),
          ],
          const SizedBox(height: 16),
          const _CouponBox(),
          const SizedBox(height: 16),
          Text('طريقة الدفع', style: AppText.h3),
          const SizedBox(height: 8),
          const _PaymentOption(
            title: 'الدفع في الصالون نقدًا',
            subtitle: 'لن يتم تحصيل أي مبلغ الآن',
            icon: Icons.payments_outlined,
            selected: true,
          ),
          const SizedBox(height: 8),
          const _PaymentOption(
            title: 'الدفع الإلكتروني',
            subtitle: 'غير متاح حاليًا',
            icon: Icons.credit_card_outlined,
            selected: false,
            enabled: false,
          ),
          const SizedBox(height: 16),
          Obx(() {
            final r = c.rules;
            final accepted = c.draft.value.policyAccepted;
            return NoticeBox(
              title: 'سياسة الحجز',
              message:
                  'يمكنكِ الإلغاء أو تغيير الموعد مجانًا حتى ${r.cancelBeforeHours} ساعة قبل الموعد. '
                  'الإلغاء المتأخر قد يؤثر على درجة التزامكِ.',
              // Own Material so the tile ink is not hidden by the box colour.
              child: Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  value: accepted,
                  onChanged: (v) => c.togglePolicy(v ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: const Text(
                    'قرأت السياسة وأوافق عليها',
                    style: AppText.bodyStrong,
                  ),
                ),
              ),
            );
          }),
          Obx(() {
            final missing = c.draft.value.missingRequired(c.intakeFields);
            if (missing.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'يرجى الإجابة عن: ${missing.map((f) => f.label).join('، ')}',
                style: AppText.caption.copyWith(color: AppColors.primaryDeep),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _IntakeQuestion extends GetView<BookingFlowController> {
  const _IntakeQuestion({required this.field});

  final IntakeField field;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final label = field.required ? '${field.label} *' : field.label;
    if (field.isSelect || field.isBoolean) {
      final options = field.isBoolean ? const ['نعم', 'لا'] : field.options;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardFill.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.bodyStrong),
            const SizedBox(height: 10),
            Obx(() {
              final current = c.draft.value.answers[field.key];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in options)
                    PillChip(
                      label: o,
                      selected: field.isBoolean
                          ? current == (o == 'نعم')
                          : current == o,
                      onTap: () => c.setAnswer(
                        field.key,
                        field.isBoolean ? o == 'نعم' : o,
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      );
    }
    return EloraTextField(
      label: label,
      controller: c.answerControllers[field.key]!,
      keyboardType: field.isNumber ? TextInputType.number : null,
      maxLines: field.isMultiline ? 4 : 1,
      onChanged: (v) => c.setAnswer(field.key, v),
    );
  }
}

class _CouponBox extends GetView<BookingFlowController> {
  const _CouponBox();

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final state = c.couponState.value;
      final coupon = c.draft.value.coupon;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: state == CouponState.invalid
                    ? AppColors.primary
                    : AppColors.borderSoft,
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c.couponInput,
                    enabled: state != CouponState.valid,
                    textCapitalization: TextCapitalization.characters,
                    textDirection: TextDirection.ltr,
                    style: AppText.bodyStrong,
                    onSubmitted: (_) => c.applyCoupon(),
                    decoration: InputDecoration(
                      hintText: 'أدخلي رمز القسيمة',
                      hintStyle: AppText.body,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (state == CouponState.valid)
                  TextButton(
                    onPressed: c.removeCoupon,
                    child: const Text('إزالة'),
                  )
                else
                  FilledButton(
                    onPressed: state == CouponState.checking
                        ? null
                        : c.applyCoupon,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 38),
                      backgroundColor: AppColors.blushStrong,
                      foregroundColor: AppColors.primaryDeep,
                    ),
                    child: state == CouponState.checking
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : Text(
                            'تطبيق',
                            style: AppText.caption.copyWith(
                              color: AppColors.primaryDeep,
                            ),
                          ),
                  ),
              ],
            ),
          ),
          if (state == CouponState.valid && coupon != null) ...[
            const SizedBox(height: 8),
            NoticeBox(
              tone: StatusTone.success,
              title: '✓ تم تطبيق القسيمة',
              message: coupon.finalPrice != null
                  ? '${Fmt.price(c.draft.value.basePrice, currency())} ← ${Fmt.price(coupon.finalPrice, currency())}'
                  : c.couponMessage.value,
            ),
          ],
          if (state == CouponState.invalid) ...[
            const SizedBox(height: 8),
            NoticeBox(
              title: '× الرمز غير صالح',
              message: c.couponMessage.value ?? 'راجعي الرمز وحاولي مرة أخرى.',
            ),
          ],
        ],
      );
    });
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: EloraCard(
        borderColor: selected ? AppColors.primary : AppColors.borderFaint,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryDeep, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- step 4

class _ReviewStep extends GetView<BookingFlowController> {
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final d = c.draft.value;
      final p = c.place.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (c.submitError.value != null) ...[
              _SlotProblem(),
              const SizedBox(height: 14),
            ],
            EloraCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'APPOINTMENT',
                        style: AppText.caption.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const Spacer(),
                      const Wordmark(size: 17),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(),
                  InfoRow(label: 'الخدمة', value: d.service?.name ?? ''),
                  InfoRow(label: 'الأخصائية', value: d.staffLabel ?? ''),
                  InfoRow(
                    label: 'التاريخ',
                    value: Fmt.dayMonth(d.day?.dateValue),
                  ),
                  InfoRow(label: 'الوقت', value: Fmt.time12(d.slot?.time)),
                  InfoRow(
                    label: 'المدة',
                    value: Fmt.duration(
                      d.service?.durationMinutes ?? 0,
                      label: d.service?.durationLabel,
                    ),
                  ),
                  InfoRow(
                    label: 'السعر',
                    value: Fmt.price(d.basePrice, currency()),
                  ),
                  if (d.coupon != null)
                    InfoRow(
                      label: 'القسيمة',
                      value: '${d.coupon!.code ?? ''} ✓',
                    ),
                  InfoRow(label: 'الدفع', value: 'نقدًا في الصالون'),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Text('الإجمالي', style: AppText.h2),
                        const Spacer(),
                        Text(
                          Fmt.price(d.total, currency()),
                          style: AppText.price.copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (p?.address != null) ...[
              const SizedBox(height: 10),
              EloraCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ÉLORA · ${p!.address}',
                        style: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            NoticeBox(
              title: 'سياسة الإلغاء',
              message:
                  'يمكنكِ إلغاء أو تعديل الموعد مجانًا حتى ${c.rules.cancelBeforeHours} ساعة قبل موعدكِ.',
            ),
          ],
        ),
      );
    });
  }
}

/// SLOT_UNAVAILABLE (Figma 06.04 pattern): server alternatives or re-pick.
class _SlotProblem extends GetView<BookingFlowController> {
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final alts = c.alternatives;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoticeBox(
            title: alts.isEmpty
                ? (c.submitError.value ?? '')
                : 'هذا الوقت لم يعد متاحًا',
            message: alts.isEmpty
                ? null
                : 'حُجز هذا الموعد قبل لحظات. اختاري أقرب البدائل:',
          ),
          for (final s in alts)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: EloraCard(
                onTap: () => c.useAlternative(s),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      '${Fmt.dayMonth(DateTime.tryParse(s.startsAt.length >= 10 ? s.startsAt.substring(0, 10) : ''))} · ${Fmt.time12(s.time)}',
                      style: AppText.bodyStrong,
                    ),
                    const Spacer(),
                    Text(
                      s.staff.isEmpty ? 'أي أخصائية' : s.staff.first.name,
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ),
          if (alts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SecondaryButton(
                label: 'اختيار وقت آخر',
                onPressed: c.pickAnotherTime,
              ),
            ),
        ],
      );
    });
  }
}
