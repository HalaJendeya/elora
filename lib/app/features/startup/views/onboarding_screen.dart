import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_text.dart';
import '../../../routes/app_routes.dart';
import '../widgets/welcome_button.dart';

/// Welcome screen (Figma 01.02): register, sign in, or browse as guest.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201914),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/onboarding-img.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00201914),
                  Color(0x33201914),
                  Color(0xE6201914),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Semantics(
                                label: 'ÉLORA',
                                child: Image.asset(
                                  'assets/images/Wordmark-light.png',
                                  width: 110,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 48),
                            Text(
                              'أهلًا بكِ في عالم ÉLORA',
                              style: AppText.caption.copyWith(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'مساحتكِ الخاصة\nللجمال والسكينة',
                              style: AppText.display.copyWith(
                                color: Colors.white,
                                fontSize: 36,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'تجارب عناية استثنائية، صُممت حولكِ ولأجلكِ.',
                              style: AppText.body.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 28),
                            WelcomeButton(
                              label: 'إنشاء حساب',
                              showArrow: true,
                              onPressed: () => Get.toNamed(Routes.register),
                            ),
                            const SizedBox(height: 12),
                            WelcomeButton(
                              label: 'تسجيل الدخول',
                              isOutlined: true,
                              onDark: true,
                              onPressed: () => Get.toNamed(Routes.login),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: () => Get.offAllNamed(Routes.main),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  minimumSize: const Size(48, 44),
                                ),
                                child: Text(
                                  'تصفّحي كزائرة',
                                  style: AppText.caption.copyWith(
                                    color: Colors.white70,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
