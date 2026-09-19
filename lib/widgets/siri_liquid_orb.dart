// lib/widgets/siri_liquid_orb.dart
//
// Jack — Multi-Layer Animating Siri Liquid Plasma Orb
// Outer pulsing plasma blur ring · Inner frosted iris · Breathing idle anim
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/jack_design_tokens.dart';
import '../models/agent_models.dart';

class SiriLiquidOrb extends StatefulWidget {
  final AgentStatus status;
  final AnimationController animCtrl;
  final VoidCallback onTap;

  const SiriLiquidOrb({
    super.key,
    required this.status,
    required this.animCtrl,
    required this.onTap,
  });

  @override
  State<SiriLiquidOrb> createState() => _SiriLiquidOrbState();
}

class _SiriLiquidOrbState extends State<SiriLiquidOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnim = CurvedAnimation(
      parent: _breathCtrl,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  bool get _isActive =>
      widget.status == AgentStatus.listening ||
      widget.status == AgentStatus.thinking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.animCtrl, _breathAnim]),
        builder: (context, _) {
          final t = widget.animCtrl.value;
          final breath = _breathAnim.value;

          // Amplitude scaling: breathe when idle, pulse when active
          final orbScale = _isActive
              ? 1.0 + 0.09 * math.sin(t * 2 * math.pi)
              : 1.0 + 0.04 * breath;

          // Plasma colors cycle through spectrum
          final plasmaColor1 = Color.lerp(
            JackDesignTokens.siriMagenta,
            JackDesignTokens.siriPurple,
            math.sin(t * math.pi * 2).abs(),
          )!;
          final plasmaColor2 = Color.lerp(
            JackDesignTokens.siriCyan,
            JackDesignTokens.siriBlue,
            math.cos(t * math.pi * 2).abs(),
          )!;

          return Transform.scale(
            scale: orbScale,
            child: SizedBox(
              width: 128,
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Layer 1: Outer plasma blur glow ──────────────────────
                  ...List.generate(3, (i) {
                    final angle = (t * 2 * math.pi) + (i * math.pi * 2 / 3);
                    final radius = 28.0 + i * 6.0;
                    final glowColor = [
                      plasmaColor1,
                      plasmaColor2,
                      JackDesignTokens.siriAmber.withValues(alpha: 0.6),
                    ][i];
                    return Positioned(
                      left: 64 + radius * math.cos(angle) - 16,
                      top: 64 + radius * math.sin(angle) - 16,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: glowColor.withValues(
                              alpha: _isActive ? 0.9 : 0.55,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // ── Layer 2: Main sweep gradient ring ─────────────────────
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        transform: GradientRotation(t * 2 * math.pi),
                        colors: const [
                          JackDesignTokens.siriCyan,
                          JackDesignTokens.siriBlue,
                          JackDesignTokens.siriPurple,
                          JackDesignTokens.siriMagenta,
                          JackDesignTokens.siriAmber,
                          JackDesignTokens.siriCyan,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: plasmaColor1.withValues(
                              alpha: _isActive ? 0.55 : 0.28),
                          blurRadius: _isActive ? 48 : 28,
                          spreadRadius: _isActive ? 10 : 3,
                        ),
                        BoxShadow(
                          color: JackDesignTokens.siriCyan.withValues(
                              alpha: _isActive ? 0.35 : 0.12),
                          blurRadius: 70,
                        ),
                      ],
                    ),
                  ),

                  // ── Layer 3: Frosted inner iris ───────────────────────────
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A0C16).withValues(alpha: 0.75),
                        ),
                        child: Center(
                          child: _OrbIcon(status: widget.status, t: t),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrbIcon extends StatelessWidget {
  final AgentStatus status;
  final double t;

  const _OrbIcon({required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    if (status == AgentStatus.listening) {
      // Audio waveform bars
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) {
          final h = 8.0 + 16.0 * math.sin((t * 2 * math.pi) + i * 0.7).abs();
          return Container(
            width: 3,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: JackDesignTokens.siriCyan,
            ),
          );
        }),
      );
    }

    IconData icon;
    Color color;
    switch (status) {
      case AgentStatus.thinking:
        icon = Icons.psychology_rounded;
        color = JackDesignTokens.siriPurple;
        break;
      case AgentStatus.executingOS:
        icon = Icons.bolt_rounded;
        color = JackDesignTokens.siriAmber;
        break;
      case AgentStatus.complete:
        icon = Icons.check_rounded;
        color = JackDesignTokens.siriEmerald;
        break;
      default:
        icon = Icons.auto_awesome_rounded;
        color = Colors.white;
    }

    return Icon(icon, color: color, size: 30);
  }
}
