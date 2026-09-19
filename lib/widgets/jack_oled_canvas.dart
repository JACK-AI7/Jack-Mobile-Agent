// lib/widgets/jack_oled_canvas.dart
//
// Jack — OLED Ambient Mesh Canvas
// 3 hardware-accelerated blurred radial pods (Cyan top-left, Magenta bottom-right,
// Purple center-right) using ImageFilter.blur sigma 110.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/jack_design_tokens.dart';

class JackOledCanvas extends StatelessWidget {
  const JackOledCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Base OLED black
            Container(color: JackDesignTokens.oledBase),

            // Pod 1 — Cyan (top-left) alpha 0.16
            Positioned(
              top: -100,
              left: -100,
              child: _BlurPod(
                color: JackDesignTokens.siriCyan.withValues(alpha: 0.16),
                size: 320,
              ),
            ),

            // Pod 2 — Magenta (bottom-right) alpha 0.18
            Positioned(
              bottom: -80,
              right: -80,
              child: _BlurPod(
                color: JackDesignTokens.siriMagenta.withValues(alpha: 0.18),
                size: 360,
              ),
            ),

            // Pod 3 — Purple (center-right) alpha 0.12
            Positioned(
              top: 220,
              right: -60,
              child: _BlurPod(
                color: JackDesignTokens.siriPurple.withValues(alpha: 0.12),
                size: 240,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurPod extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurPod({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
