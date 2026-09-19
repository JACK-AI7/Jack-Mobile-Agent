// lib/widgets/siri_glass_card.dart
//
// Jack — High-Fidelity Apple Glass Morphic Container (backward-compat wrapper)
// SiriGlassChip has been moved to real_glass_card.dart — re-exported here.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/siri_gemini_theme.dart';
export 'real_glass_card.dart' show SiriGlassChip;

class SiriGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final LinearGradient? borderGradient;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const SiriGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.borderGradient,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? SiriGeminiTheme.glassSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              width: 1.2,
              color: borderColor ?? Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
