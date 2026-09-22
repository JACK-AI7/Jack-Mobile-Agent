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
      'icon': Icons.build_rounded,
      'color': const Color(0xFF00C8FF),
    },
    {
      'label': 'Automations',
      'icon': Icons.settings_suggest_rounded,
      'color': const Color(0xFF9B2BFF),
    },
    {
      'label': 'Memory',
      'icon': Icons.memory_rounded,
      'color': const Color(0xFFFF2B6B),
    },
    {
      'label': 'Integrations',
      'icon': Icons.all_inclusive_rounded,
      'color': const Color(0xFF2B6BFF),
    },
    {
      'label': 'Personality',
      'icon': Icons.face_rounded,
      'color': const Color(0xFF7A40F2),
    },
    {
      'label': 'Knowledge',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFFF62A5),
    },
    {
      'label': 'Data',
      'icon': Icons.storage_rounded,
      'color': const Color(0xFF00E5A3),
    },
    {
      'label': 'Skills',
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF8054FF),
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
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    node['icon'] as IconData,
                    color: node['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Configure ${node['label']}',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Customize ${node['label']} parameters, autonomy weighting, and model permissions for Jack.',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: Colors.white70,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Text(
                'Build how your\nagent works',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
            ),

            // Constellation Radial Wheel
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 330,
                  height: 330,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial background glow
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00FF88).withValues(alpha: 0.12),
                              const Color(0xFF2B6BFF).withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Connecting neon lines from center hub
                      CustomPaint(
                        size: const Size(320, 320),
                        painter: _ConstellationPainter(
                          pulseValue: _pulseController.value,
                          nodeCount: _nodes.length,
                          radius: 125.0,
                        ),
                      ),

                      // Center glowing Starburst Core
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FF88)
                                      .withValues(alpha: 0.35 + _pulseController.value * 0.25),
                                  blurRadius: 24 + _pulseController.value * 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF00FF88),
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),

                      // 8 Circular Orbiting Nodes
                      ..._buildNodes(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNodes() {
    const double radius = 125.0;
    final widgets = <Widget>[];

    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      // Angle offset so node 0 is exactly at top (angle = -pi/2)
      final double angle = (i * 2 * math.pi) / _nodes.length - math.pi / 2;
      final double x = radius * math.cos(angle);
      final double y = radius * math.sin(angle);

      widgets.add(
        Transform.translate(
          offset: Offset(x, y),
          child: GestureDetector(
            onTap: () => _onNodeTapped(node),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (node['color'] as Color),
                        (node['color'] as Color).withValues(alpha: 0.78),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (node['color'] as Color).withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    node['icon'] as IconData,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  node['label'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10.5,
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
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.22 + pulseValue * 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodeCount; i++) {
      final double angle = (i * 2 * math.pi) / nodeCount - math.pi / 2;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) => true;
}
