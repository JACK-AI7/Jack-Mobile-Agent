// lib/widgets/real_glass_card.dart
//
// Jack — True Specular Glassmorphic Container
// BackdropFilter sigma 28 · Asymmetric gradient border · Ambient drop shadow
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/jack_design_tokens.dart';

class RealGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tintColor;

  const RealGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 26.0,
    this.padding = const EdgeInsets.all(18.0),
    this.onTap,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (tintColor ?? JackDesignTokens.siriCyan).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: br,
              color: tintColor != null
                  ? tintColor!.withValues(alpha: 0.06)
                  : JackDesignTokens.glassSurface,
            ),
            child: child,
          ),
        ),
      ),
    );

    // Specular gradient border overlay
    card = Stack(
      children: [
        card,
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br,
              border: Border.all(color: Colors.transparent, width: 0.9),
              gradient: JackDesignTokens.specularBorder,
            ),
          ),
        ),
      ],
    );

    // Custom painted gradient border
    card = CustomPaint(
      painter: _SpecularBorderPainter(radius: borderRadius),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: br,
              color: tintColor != null
                  ? tintColor!.withValues(alpha: 0.06)
                  : JackDesignTokens.glassSurface,
            ),
            child: child,
          ),
        ),
      ),
    );

    // Wrap in shadow container
    card = Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: card,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class _SpecularBorderPainter extends CustomPainter {
  final double radius;
  _SpecularBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0x66FFFFFF),
        Color(0x22FFFFFF),
        Color(0x05FFFFFF),
        Color(0x1400F0FF),
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularBorderPainter oldDelegate) => false;
}

/// A compact glass chip with frosted blur and specular border.
class SiriGlassChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SiriGlassChip({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _SpecularBorderPainter(radius: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
