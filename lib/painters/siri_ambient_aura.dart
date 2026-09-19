// lib/painters/siri_ambient_aura.dart
//
// Jack — Chromatic Edge Glow Painter (iOS Siri Perimeter Aura)
// Animated sweep gradient around the screen perimeter with blur bloom
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/siri_gemini_theme.dart';

class SiriAmbientAuraPainter extends CustomPainter {
  final double animationProgress;

  const SiriAmbientAuraPainter({required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final sweepGradient = SweepGradient(
      center: Alignment.bottomCenter,
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(animationProgress * 2 * math.pi),
      colors: const [
        SiriGeminiTheme.siriCyan,
        SiriGeminiTheme.siriBlue,
        SiriGeminiTheme.siriPurple,
        SiriGeminiTheme.siriMagenta,
        SiriGeminiTheme.siriAmber,
        SiriGeminiTheme.siriCyan,
      ],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(38)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SiriAmbientAuraPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Siri Chromatic Ripple Painter — Multi-layer audio-reactive rings
// wavePhase: 0.0–1.0 (animation timeline)
// amplitude: 0.0–1.0 (normalized mic level)
// ─────────────────────────────────────────────────────────────────────────────
class SiriRipplePainter extends CustomPainter {
  final double wavePhase;
  final double amplitude;

  const SiriRipplePainter({
    required this.wavePhase,
    required this.amplitude,
  });

  static const _colors = [
    Color(0xFF00F0FF), // Electric Cyan
    Color(0xFFBF5AF2), // Iridescent Purple
    Color(0xFFFF2D55), // Vibrant Magenta
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    const rippleCount = 3;

    for (int i = 0; i < rippleCount; i++) {
      final ringProgress = (wavePhase + (i / rippleCount)) % 1.0;

      const baseRadius = 24.0;
      final dynamicExpansion = (maxRadius - baseRadius) * ringProgress;
      final currentRadius =
          baseRadius + dynamicExpansion + (amplitude * 14.0 * (1 - ringProgress));

      final opacity =
          ((1.0 - ringProgress) * (0.35 + (amplitude * 0.45))).clamp(0.0, 1.0);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + (amplitude * 3.5 * (1.0 - ringProgress))
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, 6.0 + (amplitude * 8.0))
        ..color = _colors[i % _colors.length].withValues(alpha: opacity);

      // Organic wobble along perimeter
      final path = Path();
      const steps = 36;
      for (int step = 0; step <= steps; step++) {
        final angle = (step / steps) * 2 * math.pi;
        final distortion =
            math.sin(angle * 3 + (wavePhase * 2 * math.pi)) * (amplitude * 3.5);
        final r = currentRadius + distortion;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);

        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SiriRipplePainter oldDelegate) =>
      oldDelegate.wavePhase != wavePhase || oldDelegate.amplitude != amplitude;
}
