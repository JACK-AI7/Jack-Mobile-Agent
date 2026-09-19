// lib/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // ── Display — Cormorant Garamond Serif ─────────────────────────────────────
  static TextStyle display({
    double size = 48,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.1,
        letterSpacing: letterSpacing,
      );

  static TextStyle displaySemiBold({double size = 40, Color color = AppColors.textPrimary}) =>
      display(size: size, weight: FontWeight.w600, color: color);

  static TextStyle heading({
    double size = 32,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.15,
        letterSpacing: -0.3,
      );

  static TextStyle sectionHeading({
    double size = 24,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.2,
      );

  // ── Body — Inter Sans-Serif ────────────────────────────────────────────────
  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textSecondary,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.5,
      );

  static TextStyle bodyMedium({double size = 15, Color color = AppColors.textPrimary}) =>
      body(size: size, weight: FontWeight.w500, color: color);

  static TextStyle bodySemiBold({double size = 15, Color color = AppColors.textPrimary}) =>
      body(size: size, weight: FontWeight.w600, color: color);

  static TextStyle caption({
    double size = 12,
    Color color = AppColors.textTertiary,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle label({
    double size = 11,
    Color color = AppColors.textSecondary,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.8,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle navLabel({bool active = false}) =>
      GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: active ? AppColors.navActive : AppColors.navInactive,
        letterSpacing: 0.3,
      );

  static TextStyle kpi({
    double size = 36,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w300,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: -1.0,
      );

  static TextStyle button({
    double size = 15,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.1,
      );
}
