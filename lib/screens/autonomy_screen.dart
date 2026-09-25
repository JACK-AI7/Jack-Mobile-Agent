// lib/screens/autonomy_screen.dart
//
// 03. Agent Autonomy — Your agent's capability overview
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/jack_permission_service.dart';
import '../widgets/glass_nav_bar.dart';

class AutonomyScreen extends ConsumerStatefulWidget {
  const AutonomyScreen({super.key});

  @override
  ConsumerState<AutonomyScreen> createState() => _AutonomyScreenState();
}

class _AutonomyScreenState extends ConsumerState<AutonomyScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    'Overview',
    'Plugins',
    'Skills',
    'Memory',
    'Settings',
  ];

  int _autonomyScore = 58;

  @override
  void initState() {
    super.initState();
    _calculateRealScore();
  }

  Future<void> _calculateRealScore() async {
    try {
      final perms = await JackPermissionService.checkAll();
      int score = 25;
      if (perms.accessibility) score += 15;
      if (perms.overlay) score += 10;
      if (perms.microphone) score += 10;
      if (perms.phone) score += 10;
      if (perms.notification) score += 10;
      if (perms.contacts) score += 5;
      if (perms.sms) score += 5;
      if (perms.camera) score += 5;
      if (perms.battery) score += 5;
      if (mounted) {
        setState(() => _autonomyScore = score.clamp(25, 100));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'JACK AGENT',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Colors.white70,
          ),
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: 1, // Autonomy under explore/agent capabilities
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/library');
          if (index == 2) context.go('/agent-builder');
          if (index == 3) context.go('/tasks');
          if (index == 4) context.go('/profile');
        },
      ),
      body: Stack(
        children: [
          // ── Ambient Aurora Background Glow ─────────────────────────────
          Positioned(
            left: -40,
            bottom: 120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: 100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF84CC16).withValues(alpha: 0.16),
                    blurRadius: 90,
                    spreadRadius: 20,
                  ),
                  BoxShadow(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.12),
                    blurRadius: 100,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // ── Title: Centered "Agent Autonomy" (wrapping gracefully)
                SizedBox(
                  width: 200,
                  child: Text(
                    'Agent Autonomy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Subtitle: "Build how your agent works"
                Text(
                  'Build how your agent works',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Horizontal Tabs with sleek underline on active ────────
                SizedBox(
                  height: 38,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_tabs.length, (i) {
                        final active = _selectedTab == i;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTab = i);
                              if (i == 1) context.push('/tools');
                              if (i == 4) context.push('/profile');
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _tabs[i],
                                  style: GoogleFonts.inter(
                                    color: active ? Colors.white : Colors.white54,
                                    fontSize: 13,
                                    fontWeight:
                                        active ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 26,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? const Color(0xFFC084FC)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFC084FC)
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Dotted Circular Gauge (48% Autonomy score) ────────────
                Center(
                  child: SizedBox(
                    width: 230,
                    height: 230,
                    child: CustomPaint(
                      painter: _DottedGaugePainter(
                        percentage: _autonomyScore / 100.0,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_autonomyScore%',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 46,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Autonomy\nscore',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Informational Card: "Jack is learning and getting..." ─
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141320).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Circular icon badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF222035),
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Colors.white70,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Jack is learning and getting\nmore capable every day.',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white38,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular dotted gauge seen in reference Screen 03
class _DottedGaugePainter extends CustomPainter {
  final double percentage;

  _DottedGaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    const totalDots = 44;
    final activeDots = (totalDots * percentage).round();

    for (int i = 0; i < totalDots; i++) {
      // Start from 12 o'clock (-pi/2) clockwise
      final angle = -pi / 2 + (i * 2 * pi) / totalDots;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      final isLit = i < activeDots;

      if (isLit) {
        // Gradient from cyan on left to violet on right
        final t = i / activeDots;
        final color = Color.lerp(
          const Color(0xFF00E5FF), // Cyan
          const Color(0xFFA855F7), // Violet
          t,
        )!;

        // Glow pass
        final glow = Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(Offset(x, y), 3.2, glow);

        // Core dot
        final core = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 2.6, core);
      } else {
        // Unlit dim white dots
        final dim = Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 2.2, dim);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
