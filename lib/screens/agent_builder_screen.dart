// lib/screens/agent_builder_screen.dart
//
// 04. Agent Builder — Customize tools, skills, memory etc.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  final List<Map<String, dynamic>> _nodes = [
    {
      'label': 'Tools',
      'icon': Icons.folder_open_rounded,
      'color': const Color(0xFF00E5FF),
      'secondaryColor': const Color(0xFF0284C7),
    },
    {
      'label': 'Automations',
      'icon': Icons.settings_suggest_rounded,
      'color': const Color(0xFF8B5CF6),
      'secondaryColor': const Color(0xFF00E5FF),
    },
    {
      'label': 'Memory',
      'icon': Icons.settings_rounded,
      'color': const Color(0xFFF43F5E),
      'secondaryColor': const Color(0xFFEC4899),
    },
    {
      'label': 'Integrations',
      'icon': Icons.all_inclusive_rounded,
      'color': const Color(0xFF3B82F6),
      'secondaryColor': const Color(0xFF6366F1),
    },
    {
      'label': 'Personality',
      'icon': Icons.person_rounded,
      'color': const Color(0xFF7C3AED),
      'secondaryColor': const Color(0xFF9333EA),
    },
    {
      'label': 'Knowledge',
      'icon': Icons.find_in_page_rounded,
      'color': const Color(0xFFF59E0B),
      'secondaryColor': const Color(0xFF84CC16),
    },
    {
      'label': 'Data',
      'icon': Icons.dns_rounded,
      'color': const Color(0xFF10B981),
      'secondaryColor': const Color(0xFF059669),
    },
    {
      'label': 'Skills',
      'icon': Icons.business_center_rounded,
      'color': const Color(0xFFA855F7),
      'secondaryColor': const Color(0xFFEC4899),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onNodeTapped(Map<String, dynamic> node) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (node['color'] as Color).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    node['icon'] as IconData,
                    color: node['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node['label'] as String,
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Configure agent ${node['label'].toString().toLowerCase()}',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Customize how Jack uses ${node['label']} to automate actions, browse data, and follow your workflows.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${node['label']} configuration updated'),
                      backgroundColor: AppColors.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: node['color'] as Color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Settings',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        currentIndex: 2, // Agent Builder is center tab
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/library');
          if (index == 2) context.go('/agent-builder');
          if (index == 3) context.go('/tasks');
          if (index == 4) context.go('/profile');
        },
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── Centered Title: "Build how your\nagent works"
            Text(
              'Build how your\nagent works',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                height: 1.15,
                letterSpacing: -0.3,
              ),
            ),

            // ── Constellation Radial Wheel ────────────────────────────────
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 330,
                  height: 330,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial background ambient glow
                      Container(
                        width: 290,
                        height: 290,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF2DD4BF).withValues(alpha: 0.16),
                              const Color(0xFF00E5FF).withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // Connecting rays from center starburst to orbiting nodes
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(320, 320),
                            painter: _ConstellationPainter(
                              pulseValue: _pulseController.value,
                              nodeCount: _nodes.length,
                              radius: 122.0,
                            ),
                          );
                        },
                      ),

                      // 8 Orbiting Mini Luminous Orbs
                      ..._buildNodes(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNodes() {
    const double radius = 122.0;
    final widgets = <Widget>[];

    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      // Angle offset so node 0 is exactly at top (angle = -pi/2)
      final double angle = (i * 2 * math.pi) / _nodes.length - math.pi / 2;
      final double x = radius * math.cos(angle);
      final double y = radius * math.sin(angle);

      final color1 = node['color'] as Color;
      final color2 = node['secondaryColor'] as Color;

      widgets.add(
        Transform.translate(
          offset: Offset(x, y),
          child: GestureDetector(
            onTap: () => _onNodeTapped(node),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini 3D Luminous Orb
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      radius: 0.9,
                      colors: [
                        color1,
                        color2.withValues(alpha: 0.85),
                        const Color(0xFF0A0A18),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color1.withValues(alpha: 0.55),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      node['icon'] as IconData,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  node['label'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

/// Custom painter for the central 8-pointed starburst flare and radiating beams
class _ConstellationPainter extends CustomPainter {
  final double pulseValue;
  final int nodeCount;
  final double radius;

  const _ConstellationPainter({
    required this.pulseValue,
    required this.nodeCount,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── 1. Draw 8 Radiating Light Beams to Orbiting Nodes ─────────────────
    final beamPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.28 + pulseValue * 0.16)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowBeamPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.20 + pulseValue * 0.12)
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodeCount; i++) {
      final double angle = (i * 2 * math.pi) / nodeCount - math.pi / 2;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      final target = Offset(x, y);

      canvas.drawLine(center, target, glowBeamPaint);
      canvas.drawLine(center, target, beamPaint);
    }

    // ── 2. Draw 8-Pointed Flared Starburst Center Hub ─────────────────────
    final starGlow = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.40 + pulseValue * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(center, 22.0 + pulseValue * 4.0, starGlow);

    final path = Path();
    const int points = 8;
    final double innerRadius = 8.0 + pulseValue * 2.0;
    final double outerRadius = 26.0 + pulseValue * 4.0;

    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final starPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFA7F3D0),
          const Color(0xFF2DD4BF).withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawPath(path, starPaint);
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
