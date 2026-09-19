// lib/theme/siri_gemini_theme.dart
//
// Jack — Chromatic Siri × Gemini Unified Theme System
// Spectral edge glows · Liquid neon gradients · OLED void backdrop
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class SiriGeminiTheme {
  SiriGeminiTheme._();

  // ── Siri Chromatic Spectral Spectrum ──────────────────────────────────────
  static const Color siriCyan    = Color(0xFF00F0FF);
  static const Color siriBlue    = Color(0xFF0A84FF);
  static const Color siriPurple  = Color(0xFFBF5AF2);
  static const Color siriMagenta = Color(0xFFFF2D55);
  static const Color siriAmber   = Color(0xFFFF9F0A);
  static const Color siriGreen   = Color(0xFF30D158);

  // ── Deep OLED Glass Bases ─────────────────────────────────────────────────
  static const Color voidBlack      = Color(0xFF050508);
  static const Color glassSurface   = Color(0x18FFFFFF);
  static const Color glassHighlight = Color(0x35FFFFFF);
  static const Color glassBorder    = Color(0x22FFFFFF);
  static const Color cardDark       = Color(0xFF0D0E18);

  // ── Siri Aura Gradient (4-stop chromatic sweep) ───────────────────────────
  static const LinearGradient siriAuraGradient = LinearGradient(
    colors: [siriCyan, siriBlue, siriPurple, siriMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Extended 6-stop for mic / aura rings ─────────────────────────────────
  static const LinearGradient siriMicGradient = LinearGradient(
    colors: [
      Color(0xFF00F0FF), // Cyan
      Color(0xFF0A84FF), // Blue
      Color(0xFFBF5AF2), // Violet
      Color(0xFFFF2D55), // Magenta
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Gemini pill backdrop ─────────────────────────────────────────────────
  static const LinearGradient geminiPillGradient = LinearGradient(
    colors: [Color(0x331E1E2E), Color(0x4D2A2B3D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Ambient light pod gradients ──────────────────────────────────────────
  static const List<Color> ambientColors = [
    siriCyan, siriBlue, siriPurple, siriMagenta, siriAmber,
  ];
}
