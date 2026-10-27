import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale. Display sizes follow Figma (Amiri / Georgia; Georgia is
/// rendered with Gelasio, an open-licensed metric-compatible equivalent). Body sizes are
/// raised from Figma's 7–11 px to a readable 11–15 px scale (see
/// docs/API_INVENTORY.md → Discrepancies).
class AppText {
  AppText._();

  static const sans = 'IBMPlexSansArabic';
  static const serif = 'Amiri';
  static const latin = 'Gelasio';

  static const wordmark = TextStyle(
    fontFamily: latin,
    fontSize: 19,
    height: 1,
    letterSpacing: 5,
    color: AppColors.textPrimary,
  );

  static const display = TextStyle(
    fontFamily: serif,
    fontSize: 30,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const h1 = TextStyle(
    fontFamily: serif,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontFamily: serif,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontFamily: serif,
    fontSize: 19,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const eyebrow = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.primaryDeep,
  );

  static const title = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    height: 1.6,
    color: AppColors.textSecondary,
  );

  static const bodyStrong = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static const price = TextStyle(
    fontFamily: sans,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryDeep,
  );
}
