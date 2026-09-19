import 'package:flutter/material.dart';
import 'dart:math' as math;

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
          'Build how your agent works',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
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
