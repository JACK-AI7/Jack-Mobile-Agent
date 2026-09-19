// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/jack_orb.dart';

/// The JACK AGENT splash/welcome screen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background Radial Glow (Cyan & Purple) ──────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.22),
                  radius: 0.95,
                  colors: [
                    AppColors.accentCyan.withValues(alpha: 0.16),
                    AppColors.accentViolet.withValues(alpha: 0.12),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Secondary subtle ambient glow in bottom-right corner
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentViolet.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ────────────────────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28.0,
                          vertical: 24.0,
                        ),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),

                            // ── Centered Large JackOrb (size 160) ─────────
                            const JackOrb(
                              size: 160,
                              state: OrbState.idle,
                            )
                                .animate()
                                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                                .scale(
                                  begin: const Offset(0.85, 0.85),
                                  end: const Offset(1.0, 1.0),
                                  duration: 800.ms,
                                  curve: Curves.easeOutBack,
                                ),

                            const SizedBox(height: 36),

                            // ── Title 'JACK' (Cormorant Garamond 48px) ────
                            Text(
                              'JACK',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 6.0,
                                height: 1.1,
                              ),
                            )
                                .animate()
                                .fadeIn(
                                  delay: 200.ms,
                                  duration: 600.ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOut,
                                ),

                            const SizedBox(height: 6),

                            // ── Subtitle 'AGENT' (Caps Inter) ─────────────
                            Text(
                              'AGENT',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentCyan,
                                letterSpacing: 8.0,
                              ),
                            )
                                .animate()
                                .fadeIn(
                                  delay: 350.ms,
                                  duration: 600.ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOut,
                                ),

                            const SizedBox(height: 36),

                            // ── Taglines: THINK, AUTOMATE, GET THINGS DONE ─
                            _buildTaglines()
                                .animate()
                                .fadeIn(
                                  delay: 500.ms,
                                  duration: 700.ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(
                                  begin: 0.15,
                                  end: 0,
                                  duration: 700.ms,
                                  curve: Curves.easeOut,
                                ),

                            const Spacer(flex: 3),

                            // ── Bottom Section: Button & Subtext ──────────
                            _buildBottomSection(context)
                                .animate()
                                .fadeIn(
                                  delay: 650.ms,
                                  duration: 700.ms,
                                  curve: Curves.easeOut,
                                )
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 700.ms,
                                  curve: Curves.easeOut,
                                ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Stacked styled taglines: THINK, AUTOMATE, GET THINGS DONE
  Widget _buildTaglines() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'THINK',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 4.0,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentCyan,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AUTOMATE',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 4.0,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentViolet,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'GET THINGS DONE',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 4.0,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Bottom pill button ('Get Started →') and secondary subtext
  Widget _buildBottomSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.accentCyan,
                AppColors.accentViolet,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.accentViolet.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => context.go('/home'),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your AI agent. A brighter you.',
          textAlign: TextAlign.center,
          style: AppTypography.caption(
            size: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
