// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background       = Color(0xFF05050F);
  static const Color backgroundDeep   = Color(0xFF020209);
  static const Color surface          = Color(0xFF0D0D1E);
  static const Color surfaceElevated  = Color(0xFF141428);
  static const Color surfaceCard      = Color(0xFF0F0F22);
  static const Color surfaceBorder    = Color(0xFF1E1E38);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFFEFEFF5);
  static const Color textSecondary    = Color(0xFF8A8AA8);
  static const Color textTertiary     = Color(0xFF4A4A6A);
  static const Color textAccent       = Color(0xFF00D4FF);

  // ── Accent palette ─────────────────────────────────────────────────────────
  static const Color accentCyan       = Color(0xFF00D4FF);
  static const Color accentBlue       = Color(0xFF3B82F6);
  static const Color accentViolet     = Color(0xFF7C3AED);
  static const Color accentPurple     = Color(0xFF9B59B6);
  static const Color accentPink       = Color(0xFFEC4899);
  static const Color accentTeal       = Color(0xFF06B6D4);
  static const Color accentIndigo     = Color(0xFF6366F1);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success          = Color(0xFF10B981);
  static const Color warning          = Color(0xFFF59E0B);
  static const Color error            = Color(0xFFEF4444);
  static const Color info             = Color(0xFF3B82F6);

  // ── Orb gradient stops ─────────────────────────────────────────────────────
  static const List<Color> orbGradient = [
    Color(0xFF00D4FF),
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  static const List<Color> orbGradientShift = [
    Color(0xFF3B82F6),
    Color(0xFF7C3AED),
    Color(0xFF00D4FF),
    Color(0xFFEC4899),
  ];

  // ── Navigation ─────────────────────────────────────────────────────────────
  static const Color navBackground    = Color(0xFF080814);
  static const Color navBorder        = Color(0xFF1A1A30);
  static const Color navActive        = Color(0xFF00D4FF);
  static const Color navInactive      = Color(0xFF3A3A5C);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentViolet],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10102A), Color(0xFF0A0A1E)],
  );

  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x4000D4FF), Color(0x007C3AED)],
  );
}
