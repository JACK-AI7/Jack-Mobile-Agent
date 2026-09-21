import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class AutonomyScreen extends ConsumerStatefulWidget {
  const AutonomyScreen({super.key});

  @override
  ConsumerState<AutonomyScreen> createState() => _AutonomyScreenState();
}

class _AutonomyScreenState extends ConsumerState<AutonomyScreen> {
  final Map<String, bool> _settings = {
    'Auto-Approve Expenditures': false,
    'Unrestricted API Access': false,
    'Autonomous Data Deletion': false,
    'Global System Controls': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.4, -0.6),
            radius: 1.2,
            colors: [Color(0xFF12082A), Color(0xFF05050F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent Autonomy',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define parameters for your agents.',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Circular progress
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: const Color(0xFF2B6BFF).withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: const Color(0xFF9B2BFF).withValues(alpha: 0.1),
                            blurRadius: 40,
                            spreadRadius: 5,
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
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: 0.44, // 44%
                          strokeWidth: 8,
                          backgroundColor: Color(0xFF151515),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '44%',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Autonomy Score',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSwitchItem(
                      'Auto-Approve Expenditures',
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF00FF88),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchItem(
                      'Unrestricted API Access',
                      Icons.api_rounded,
                      const Color(0xFF2B6BFF),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchItem(
                      'Autonomous Data Deletion',
                      Icons.delete_sweep_rounded,
                      const Color(0xFFE01E5A),
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchItem(
                      'Global System Controls',
                      Icons.settings_system_daydream_rounded,
                      const Color(0xFF9B2BFF),
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

  Widget _buildSwitchItem(String title, IconData icon, Color iconColor) {
    final value = _settings[title] ?? false;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {
              setState(() {
                _settings[title] = val;
              });
            },
            activeTrackColor: AppColors.accentCyan.withValues(alpha: 0.5),
            activeThumbColor: AppColors.accentCyan,
            inactiveTrackColor: Colors.white10,
            inactiveThumbColor: Colors.white38,
          ),
        ],
      ),
    );
  }
}
