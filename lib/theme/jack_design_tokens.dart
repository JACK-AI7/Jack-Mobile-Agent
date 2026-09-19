// lib/theme/jack_design_tokens.dart
//
// Jack — Tier-One Design Token System
// Apple Intelligence × Google Gemini × OLED Obsidian
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class JackDesignTokens {
  JackDesignTokens._();

  // ── OLED Backgrounds ──────────────────────────────────────────────────────
  static const Color oledBase      = Color(0xFF04060A);
  static const Color glassSurface  = Color(0x1A141A28);
  static const Color glassHighlight= Color(0x40FFFFFF);
  static const Color glassShadow   = Color(0x0A000000);
  static const Color cardDark      = Color(0xFF080C14);

  // ── Siri Spectral Palette ─────────────────────────────────────────────────
  static const Color siriCyan    = Color(0xFF00F0FF);
  static const Color siriBlue    = Color(0xFF0A84FF);
  static const Color siriPurple  = Color(0xFFBF5AF2);
  static const Color siriMagenta = Color(0xFFFF2D55);
  static const Color siriAmber   = Color(0xFFFF9F0A);
  static const Color siriEmerald = Color(0xFF30D158);

  // ── Specular Border Gradient ──────────────────────────────────────────────
  static const LinearGradient specularBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x66FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
      Color(0x1400F0FF),
    ],
    stops: [0.0, 0.35, 0.75, 1.0],
  );

  // ── Chromatic Iris Gradient ───────────────────────────────────────────────
  static const LinearGradient chromaticIris = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [siriCyan, siriBlue, siriPurple, siriMagenta],
  );

  // ── Ambient Pod Gradients ─────────────────────────────────────────────────
  static const SweepGradient orbPlasmaGradient = SweepGradient(
    colors: [siriCyan, siriBlue, siriPurple, siriMagenta, siriAmber, siriCyan],
  );


  // ── Typography Tokens ─────────────────────────────────────────────────────
  static const TextStyle highEmphasis = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.45,
  );

  static const TextStyle telemetryLabel = TextStyle(
    color: Color(0x73FFFFFF),
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle telemetryValue = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
