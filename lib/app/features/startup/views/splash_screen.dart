import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Oversized faint monogram in the lower start corner (Figma 01.01).
          PositionedDirectional(
            end: -10,
            bottom: -60,
            child: ExcludeSemantics(
              child: Text(
                'É',
                style: TextStyle(
                  fontFamily: AppText.latin,
                  fontSize: 300,
                  height: 1,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                textScaler: TextScaler.noScaling,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Semantics(
                label: 'ÉLORA',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/Wordmark.png', width: 200),
                    const SizedBox(height: 22),
                    Container(width: 36, height: 1.3, color: AppColors.primary),
                    const SizedBox(height: 14),
                    const Text(
                      'The art of feeling beautiful',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: AppText.latin,
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
