// lib/widgets/animations/loading_dev_indicators.dart
//
// High-fidelity animations inspired by https://loading.dev/
// Pure Flutter custom painters with 60fps hardware acceleration:
// 1. LoadingDevDualRing: Opposing rotating dual neon arcs
// 2. LoadingDevRipple: Expanding concentric glowing pulses
// 3. LoadingDevEclipse: Orbiting celestial ring with comet glow
// 4. LoadingDevRoller: 8-particle staggered orbital trail
// 5. LoadingDevThinking: Premium AI reasoning indicator with glowing state
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
export 'lattice_loader.dart';
export 'voice_pill.dart';
export 'thought_line.dart';
export 'prompt_bar.dart';
export 'animated_beam.dart';

/// 1. Dual Ring Loader (https://loading.dev/css/#dual-ring)
class LoadingDevDualRing extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color? secondaryColor;
  final double strokeWidth;
  final Duration duration;

  const LoadingDevDualRing({
    super.key,
    this.size = 36.0,
    this.primaryColor = const Color(0xFF00E5FF), // Cyan
    this.secondaryColor = const Color(0xFF7C3AED), // Violet
    this.strokeWidth = 3.0,
    this.duration = const Duration(milliseconds: 1100),
  });

  @override
  State<LoadingDevDualRing> createState() => _LoadingDevDualRingState();
}

class _LoadingDevDualRingState extends State<LoadingDevDualRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DualRingPainter(
            rotation: _ctrl.value * 2 * math.pi,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor ?? widget.primaryColor,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _DualRingPainter extends CustomPainter {
  final double rotation;
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;

  _DualRingPainter({
    required this.rotation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Arc 1 - Primary Neon
    final paint1 = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Arc 2 - Secondary Violet / Glow
    final paint2 = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Arc 1: span of 110 degrees
    const sweep = 1.9; // radians (~110 deg)
    canvas.drawArc(rect, rotation, sweep, false, paint1);

    // Arc 2: opposite side with pi offset
    canvas.drawArc(rect, rotation + math.pi, sweep, false, paint2);
  }

  @override
  bool shouldRepaint(_DualRingPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;
}

/// 2. Ripple Loader (https://loading.dev/css/#ripple)
class LoadingDevRipple extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final Duration duration;

  const LoadingDevRipple({
    super.key,
    this.size = 48.0,
    this.color = const Color(0xFF00E5FF),
    this.strokeWidth = 2.5,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<LoadingDevRipple> createState() => _LoadingDevRippleState();
}

class _LoadingDevRippleState extends State<LoadingDevRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RipplePainter(
            progress: _ctrl.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RipplePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    void drawRing(double ringProgress) {
      if (ringProgress < 0.0) return;
      final curProgress = ringProgress % 1.0;
      final radius = maxRadius * Curves.easeOutQuad.transform(curProgress);
      final alpha = (1.0 - curProgress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (1.0 - curProgress * 0.5);

      canvas.drawCircle(center, radius, paint);
    }

    // Two staggered concentric ripples (0.0 and 0.5 offset)
    drawRing(progress);
    drawRing(progress + 0.5);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// 3. Eclipse Loader (https://loading.dev/css/#eclipse)
class LoadingDevEclipse extends StatefulWidget {
  final double size;
  final Color baseColor;
  final Color glowColor;
  final Duration duration;

  const LoadingDevEclipse({
    super.key,
    this.size = 36.0,
    this.baseColor = const Color(0xFF1E1B4B),
    this.glowColor = const Color(0xFF00E5FF),
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<LoadingDevEclipse> createState() => _LoadingDevEclipseState();
}

class _LoadingDevEclipseState extends State<LoadingDevEclipse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _EclipsePainter(
            rotation: _ctrl.value * 2 * math.pi,
            baseColor: widget.baseColor,
            glowColor: widget.glowColor,
          ),
        );
      },
    );
  }
}

class _EclipsePainter extends CustomPainter {
  final double rotation;
  final Color baseColor;
  final Color glowColor;

  _EclipsePainter({
    required this.rotation,
    required this.baseColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Outer faint track
    final trackPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, trackPaint);

    // Orbiting luminous comet
    final cometPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, rotation, 1.2, false, cometPaint);

    // Satellite glowing bead at arc head
    final headAngle = rotation + 1.2;
    final beadPos = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );

    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(beadPos, 3.5, glowPaint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(beadPos, 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(_EclipsePainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

/// 4. Roller Loader (https://loading.dev/css/#roller)
class LoadingDevRoller extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const LoadingDevRoller({
    super.key,
    this.size = 40.0,
    this.color = const Color(0xFF00E5FF),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<LoadingDevRoller> createState() => _LoadingDevRollerState();
}

class _LoadingDevRollerState extends State<LoadingDevRoller>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RollerPainter(
            progress: _ctrl.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RollerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RollerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    const count = 7;
    for (int i = 0; i < count; i++) {
      // Stagger each dot
      final dotProgress = (progress - (i * 0.045)) % 1.0;
      final speedFactor = Curves.easeInOutCubic.transform(dotProgress);
      final angle = speedFactor * 2 * math.pi - math.pi / 2;

      final dotPos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final alpha = (1.0 - (i * 0.12)).clamp(0.2, 1.0);
      final dotPaint = Paint()..color = color.withValues(alpha: alpha);
      final dotRadius = (size.width * 0.065) * (1.0 - i * 0.08);

      canvas.drawCircle(dotPos, dotRadius.clamp(1.5, 4.0), dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RollerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// 5. High-Tech AI Thinking Indicator for Chat & Autonomous Tasks
class LoadingDevThinkingIndicator extends StatefulWidget {
  final String statusText;
  final bool compact;

  const LoadingDevThinkingIndicator({
    super.key,
    this.statusText = 'Thinking...',
    this.compact = false,
  });

  @override
  State<LoadingDevThinkingIndicator> createState() =>
      _LoadingDevThinkingIndicatorState();
}

class _LoadingDevThinkingIndicatorState
    extends State<LoadingDevThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingDevDualRing(
            size: 18,
            strokeWidth: 2,
            primaryColor: Color(0xFF00E5FF),
            secondaryColor: Color(0xFF7C3AED),
          ),
          const SizedBox(width: 8),
          Text(
            widget.statusText,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF100E22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingDevDualRing(
            size: 24,
            strokeWidth: 2.5,
            primaryColor: Color(0xFF00E5FF),
            secondaryColor: Color(0xFF7C3AED),
          ),
          const SizedBox(width: 14),
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (context, _) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: const [
                      Color(0xFF00E5FF),
                      Colors.white,
                      Color(0xFF7C3AED),
                      Color(0xFF00E5FF),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                    transform: _GradientTranslate(_shimmerCtrl.value),
                  ).createShader(bounds);
                },
                child: Text(
                  widget.statusText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GradientTranslate extends GradientTransform {
  final double percent;
  const _GradientTranslate(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}
