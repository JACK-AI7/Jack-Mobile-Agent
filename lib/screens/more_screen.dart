// lib/screens/more_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';
import '../widgets/jack_orb.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('More', style: AppTypography.sectionHeading(size: 22)),
            Text('Everything else. Organized.', style: AppTypography.caption()),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MoreItem(
                  icon: Icons.help_outline_rounded,
                  color: AppColors.accentCyan,
                  title: 'Help & Support',
                  subtitle: 'Get help or contact us',
                  onTap: () => _showHelp(context),
                ),
                const Divider(height: 1, indent: 58, color: AppColors.surfaceBorder),
                _MoreItem(
                  icon: Icons.school_outlined,
                  color: AppColors.accentViolet,
                  title: 'Learn',
                  subtitle: 'Guides and tutorials',
                  onTap: () => _showLearn(context),
                ),
                const Divider(height: 1, indent: 58, color: AppColors.surfaceBorder),
                _MoreItem(
                  icon: Icons.new_releases_outlined,
                  color: AppColors.accentPink,
                  title: "What's New",
                  subtitle: 'Latest features',
                  badge: 'NEW',
                  onTap: () => _showWhatsNew(context),
                ),
                const Divider(height: 1, indent: 58, color: AppColors.surfaceBorder),
                _MoreItem(
                  icon: Icons.feedback_outlined,
                  color: AppColors.accentTeal,
                  title: 'Feedback',
                  subtitle: 'Help us improve',
                  onTap: () => _showFeedback(context),
                ),
                const Divider(height: 1, indent: 58, color: AppColors.surfaceBorder),
                _MoreItem(
                  icon: Icons.info_outlined,
                  color: AppColors.accentIndigo,
                  title: 'About Jack',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick links ─────────────────────────────────────────────────
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MoreItem(
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.warning,
                  title: 'Upgrade to Pro',
                  subtitle: 'Unlock unlimited power',
                  onTap: () => context.push('/upgrade'),
                ),
                const Divider(height: 1, indent: 58, color: AppColors.surfaceBorder),
                _MoreItem(
                  icon: Icons.build_rounded,
                  color: AppColors.accentBlue,
                  title: 'Integrations & Tools',
                  subtitle: 'Connect apps and APIs',
                  onTap: () => context.push('/tools'),
                ),
                const Divider(height: 1, indent: 58, color: AppColors.surfaceBorder),
                _MoreItem(
                  icon: Icons.schedule_rounded,
                  color: AppColors.accentPurple,
                  title: 'Automations',
                  subtitle: 'Set it and forget it',
                  onTap: () => context.push('/automations'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Legal ──────────────────────────────────────────────────────
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              _Legal('Terms'),
              _Legal('Privacy'),
              _Legal('Licenses'),
              _Legal('Security'),
              _Legal('Data Controls'),
            ],
          ),

          const SizedBox(height: 32),

          // ── Footer brand ───────────────────────────────────────────────
          Column(
            children: [
              const JackOrb(size: 44, state: OrbState.idle),
              const SizedBox(height: 8),
              Text('JACK AGENT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentCyan,
                    letterSpacing: 3,
                  )),
              const SizedBox(height: 4),
              Text('Version 1.0.0', style: AppTypography.caption(size: 11)),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) => _sheet(context, 'Help & Support', [
        'Email: support@jackagent.ai',
        'Documentation: docs.jackagent.ai',
        'Community Discord',
        'Status: All systems operational',
      ]);

  void _showLearn(BuildContext context) => _sheet(context, 'Learn', [
        'Getting Started with Jack',
        'Setting up Automations',
        'Building Custom Agents',
        'Using Voice Commands',
      ]);

  void _showWhatsNew(BuildContext context) => _sheet(context, "What's New in v1.0.0", [
        '✨ AI-powered task execution',
        '✨ Agent Builder with visual workflow',
        '✨ Voice commands & TTS',
        '✨ 12 new screen redesign',
        '✨ Groq ultra-fast AI integration',
      ]);

  void _showFeedback(BuildContext context) => _sheet(context, 'Feedback', [
        '🐛 Report a bug',
        '💡 Request a feature',
        '⭐ Rate the app',
        '💬 General feedback',
      ]);

  void _showAbout(BuildContext context) => _sheet(context, 'About Jack', [
        'Version: 1.0.0 (build 2)',
        'AI Model: Llama 3.3 70B via Groq',
        'Framework: Flutter',
        'Made with ❤️ for the future',
      ]);

  void _sheet(BuildContext context, String title, List<String> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sectionHeading()),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(item,
                        style: AppTypography.body(size: 14, color: AppColors.textPrimary)),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const _MoreItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTypography.bodyMedium(size: 14)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentPink, AppColors.accentViolet],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge!,
                              style: GoogleFonts.inter(
                                  fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: AppTypography.caption(size: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Legal extends StatelessWidget {
  final String text;
  const _Legal(this.text);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(text, style: AppTypography.caption(size: 11, color: AppColors.textTertiary)),
    );
  }
}
