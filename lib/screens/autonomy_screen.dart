import 'package:flutter/material.dart';

class AutonomyScreen extends StatelessWidget {
  const AutonomyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Agent Autonomy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Build how your agent works',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF2B6BFF).withValues(alpha: 0.15),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF9B2BFF).withValues(alpha: 0.15),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const SweepGradient(
                        colors: [
                          Color(0xFF00FF88),
                          Color(0xFF2B6BFF),
                          Color(0xFF9B2BFF),
                          Color(0xFF00FF88),
                        ],
                        stops: [0.0, 0.33, 0.66, 1.0],
                      ).createShader(rect);
                    },
                    child: const SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: 0.48,
                        strokeWidth: 12,
                        backgroundColor: Color(0xFF151515),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '48%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Autonomy score',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF2B6BFF), size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Jack is learning and getting more capable every day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
