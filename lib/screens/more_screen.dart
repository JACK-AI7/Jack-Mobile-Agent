// lib/screens/more_screen.dart
//
// 12. More — Help, learn and stay updated
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'More',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Everything else. Organized.',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 24),

              // Menu List Card matching Screen 12
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    _buildMoreItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help or contact us',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/chat', extra: 'Help with Jack Agent features');
                      },
                    ),
                    _buildDivider(),
                    _buildMoreItem(
                      context,
                      icon: Icons.school_outlined,
                      title: 'Learn',
                      subtitle: 'Guides and tutorials',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/autonomy');
                      },
                    ),
                    _buildDivider(),
                    _buildMoreItem(
                      context,
                      icon: Icons.auto_awesome_outlined,
                      title: 'What\'s New',
                      subtitle: 'Latest features',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Jack v1.0.0: Autonomous mobile DOM execution enabled!'),
                            backgroundColor: AppColors.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMoreItem(
                      context,
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Feedback',
                      subtitle: 'Help us improve',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/chat', extra: 'Submit feedback for Jack Agent');
                      },
                    ),
                    _buildDivider(),
                    _buildMoreItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About Jack',
                      subtitle: 'Version 1.0.0',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF131124),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text(
                              'About JACK AGENT',
                              style: GoogleFonts.cormorantGaramond(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Version: 1.0.1 (Build 2)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text('Engine: Flutter 3.12+ / Android Native', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text('AI Model: Llama 3.3 70B Versatile (Groq Sub-400ms)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text('Architecture: Local-First Dual-Speed Cognitive Engine', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Close', style: GoogleFonts.inter(color: AppColors.accentCyan)),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildMoreItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white30,
        size: 20,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.05),
      height: 1,
      indent: 60,
      endIndent: 16,
    );
  }
}
