// lib/screens/splash_screen.dart
//
// 01. Splash / Welcome — Clean entry with brand identity
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/jack_orb.dart';
import '../services/jack_permission_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final orbSize = (screenWidth * 0.68).clamp(220.0, 275.0);

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Top Left Brand Typography ─────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JACK',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      height: 1.02,
                    ),
                  ),
                  Text(
                    'AGENT',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      height: 1.02,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'THINK\nAUTOMATE\nGET THINGS DONE',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8E8E9E),
                      letterSpacing: 2.4,
                      height: 1.6,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),

              const Spacer(),

              // ── Center Jack Orb ───────────────────────────────────────
              Center(
                child: JackOrb(
                  size: orbSize,
                  state: OrbState.idle,
                ),
              ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.92, 0.92)),

              const Spacer(),

              // ── Bottom White Button: "Get Started ->" ─────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () async {
                    final status = await JackPermissionService.checkAll();
                    if (!status.allGranted && context.mounted) {
                      JackPermissionService.showPermissionSheet(
                        context,
                        onComplete: () {
                          if (context.mounted) context.go('/home');
                        },
                      );
                    } else if (context.mounted) {
                      context.go('/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
