// lib/design/jack_colors.dart
//
// Authoritative Color Tokens for JACK Agent
// Derived directly from the obsidian and luminous neon reference specification.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class JackColors {
  JackColors._();

  // ── Background & Canvas ─────────────────────────────────────────────────────
  static const Color background = Color(0xFF07070A);
  static const Color backgroundDeep = Color(0xFF04040A);
  static const Color ambientPurple = Color(0xFF140C2C);
  static const Color ambientGlowCenter = Color(0xFF1D123D);

  // ── Glass Surfaces & Cards ──────────────────────────────────────────────────
  static const Color surfaceGlass = Color(0xFF11101E);
  static const Color surfaceCard = Color(0xFF141320);
  static const Color surfaceElevated = Color(0xFF1B192A);
  static const Color surfaceBorder = Color(0x1FFFFFFF);
  static const Color surfaceBorderSubtle = Color(0x12FFFFFF);

  // ── Typography ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // ~70% white
  static const Color textTertiary = Color(0x66FFFFFF);  // ~40% white
  static const Color textMuted = Color(0x40FFFFFF);     // ~25% white

  // ── Neon Accents ────────────────────────────────────────────────────────────
  static const Color cyan = Color(0xFF00E5FF);
  static const Color electricBlue = Color(0xFF2B6BFF);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color deepPurple = Color(0xFF6B46C1);
  static const Color emerald = Color(0xFF00FF88);
  static const Color pink = Color(0xFFFF3377);
  static const Color amber = Color(0xFFFFB800);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color coral = Color(0xFFFF62A5);

  // ── Semantic Status ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00FF88);
  static const Color running = Color(0xFF00E5FF);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF3366);

  // ── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, violet],
  );

  static const RadialGradient backgroundAtmosphere = RadialGradient(
    center: Alignment(0.0, -0.4),
    radius: 1.15,
    colors: [ambientPurple, background, backgroundDeep],
    stops: [0.0, 0.58, 1.0],
  );
}
