import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class BuilderScreen extends StatelessWidget {
  const BuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Build your own Jack agent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2B6BFF).withValues(alpha: 0.3),
                            const Color(0xFF9B2BFF).withValues(alpha: 0.1),
                            const Color(0xFF0A0A0A),
                          ],
                          stops: const [0.1, 0.5, 1.0],
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: const Size(320, 320),
                      painter: WebLinesPainter(),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF151515),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B6BFF).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    ..._buildRadialIcons(),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Configure Agent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select nodes to configure tools, automations, and behavior.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B6BFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Configuration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRadialIcons() {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.build, 'label': 'Tools'},
      {'icon': Icons.precision_manufacturing, 'label': 'Automations'},
      {'icon': Icons.memory, 'label': 'Memory'},
      {'icon': Icons.integration_instructions, 'label': 'Integrations'},
      {'icon': Icons.face, 'label': 'Personality'},
      {'icon': Icons.menu_book, 'label': 'Knowledge'},
      {'icon': Icons.storage, 'label': 'Data'},
      {'icon': Icons.psychology, 'label': 'Skills'},
    ];

    final double radius = 130.0;
    final List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      final double angle = (i * 2 * math.pi) / items.length - math.pi / 2;
      final double x = radius * math.cos(angle);
      final double y = radius * math.sin(angle);

      widgets.add(
        Transform.translate(
          offset: Offset(x, y),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2B6BFF).withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  items[i]['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                items[i]['label'] as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}

class WebLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2B6BFF).withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final int nodeCount = 8;
    final double radius = 130.0;

    for (int i = 0; i < nodeCount; i++) {
      final double angle = (i * 2 * math.pi) / nodeCount - math.pi / 2;
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);
    }
    
    // Draw connecting web around
    final webPaint = Paint()
      ..color = const Color(0xFF9B2BFF).withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < nodeCount; i++) {
      final double angle = (i * 2 * math.pi) / nodeCount - math.pi / 2;
      final double x = center.dx + radius * 0.6 * math.cos(angle);
      final double y = center.dy + radius * 0.6 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, webPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
