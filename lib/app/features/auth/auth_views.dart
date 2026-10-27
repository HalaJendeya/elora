import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/display.dart';
import '../../shared/widgets/elora_scaffold.dart';
import '../../shared/widgets/form_fields.dart';
import 'auth_controllers.dart';

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            EloraHeader(onBack: () => Get.back()),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PageTitle(
                        eyebrow: eyebrow,
                        title: title,
                        subtitle: subtitle,
                        center: true,
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
                      ),
                      ...children,
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

Widget _formError(RxnString error) => Obx(
  () => error.value == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NoticeBox(title: error.value!),
        ),
);

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return _AuthLayout(
      eyebrow: 'مرحبًا بعودتكِ',
      title: 'تسجيل الدخول',
      subtitle: 'أدخلي بياناتكِ للعودة إلى مساحتكِ الخاصة.',
      children: [
        _formError(c.formError),
        Obx(
          () => EloraTextField(
            label: 'البريد الإلكتروني',
            controller: c.email,
            error: c.error('email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            textDirection: TextDirection.ltr,
            onChanged: (_) => c.clearError('email'),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => EloraTextField(
            label: 'كلمة المرور',
            controller: c.password,
            error: c.error('password'),
            obscure: c.obscure.value,
            onToggleObscure: c.obscure.toggle,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) => c.clearError('password'),
            onSubmitted: (_) => c.submit(),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => PrimaryButton(
            label: 'تسجيل الدخول',
            loadingLabel: 'جارٍ تسجيل الدخول…',
            loading: c.loading.value,
            showArrow: true,
            onPressed: c.submit,
          ),
        ),
        const SizedBox(height: 12),
        _SwitchRow(
          prompt: 'ليس لديكِ حساب؟',
          action: 'أنشئي حسابًا',
          onTap: c.goToRegister,
        ),
      ],
    );
  }
}

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return _AuthLayout(
      eyebrow: 'بداية جميلة',
      title: 'أنشئي حسابكِ',
      subtitle: 'لحجز مواعيدكِ وإدارة تجاربكِ الخاصة.',
      children: [
        _formError(c.formError),
        Obx(
          () => EloraTextField(
            label: 'الاسم الكامل',
            controller: c.name,
            error: c.error('name'),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) => c.clearError('name'),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => EloraTextField(
            label: 'البريد الإلكتروني',
            controller: c.email,
            error: c.error('email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            textDirection: TextDirection.ltr,
            onChanged: (_) => c.clearError('email'),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => EloraTextField(
            label: 'رقم الهاتف',
            controller: c.phone,
            error: c.error('phone'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            textDirection: TextDirection.ltr,
            onChanged: (_) => c.clearError('phone'),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => EloraTextField(
            label: 'كلمة المرور',
            controller: c.password,
            error: c.error('password'),
            obscure: c.obscure.value,
            onToggleObscure: c.obscure.toggle,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => c.clearError('password'),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => EloraTextField(
            label: 'تأكيد كلمة المرور',
            controller: c.confirm,
            error: c.error('password_confirmation'),
            obscure: c.obscureConfirm.value,
            onToggleObscure: c.obscureConfirm.toggle,
            textInputAction: TextInputAction.done,
            onChanged: (_) => c.clearError('password_confirmation'),
            onSubmitted: (_) => c.submit(),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => PrimaryButton(
            label: 'إنشاء حساب',
            loadingLabel: 'جارٍ إنشاء الحساب…',
            loading: c.loading.value,
            onPressed: c.submit,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'بإنشاء حساب، أنتِ توافقين على الشروط وسياسة الخصوصية.',
          style: AppText.caption.copyWith(fontSize: 10.5),
          textAlign: TextAlign.center,
        ),
        _SwitchRow(
          prompt: 'لديكِ حساب بالفعل؟',
          action: 'تسجيل الدخول',
          onTap: c.goToLogin,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
        ),
        LinkButton(label: action, onPressed: onTap),
      ],
    );
  }
}
