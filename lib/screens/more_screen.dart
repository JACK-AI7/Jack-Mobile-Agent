// lib/screens/more_screen.dart
//
// 12. More — Help, learn and stay updated
// Pixel-to-pixel match of Screen 12:
// Header serif "More" + subtitle "Everything else. Organized."
// Single dark glass card with 5 rows: Help & Support, Learn, What's New,
// Feedback, About Jack (Version 1.0.0) — each with circle icon, title,
// subtitle, chevron.
// Bottom nav bar with "More" (... dots) as 5th active tab.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ── Header ─────────────────────────────────────────────────
              Text(
                'More',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Everything else. Organized.',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 28),

              // ── Menu card matching Screen 12 exactly ───────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF11101E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildMoreItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help or contact us',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/chat',
                            extra: 'I need help with Jack Agent features');
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
                      title: "What's New",
                      subtitle: 'Latest features',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showWhatsNew(context);
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
                        context.push('/chat',
                            extra: 'I want to submit feedback for Jack Agent');
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
                        _showAboutDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom nav bar — More is the active 5th tab (... icon)
      bottomNavigationBar: GlassNavBar(
        currentIndex: 4, // Profile slot repurposed as "More" when isMoreActive
        isMoreActive: true,
        exploreLabel: 'Tools',
        onTap: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/tools');
              break;
            case 2:
              context.go('/agent-builder');
              break;
            case 3:
              context.go('/tasks');
              break;
            case 4:
              // Already on More
              break;
          }
        },
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
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              // Circle icon container matching reference image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white30,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.05),
      height: 1,
      indent: 72,
      endIndent: 18,
    );
  }

  void _showWhatsNew(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "What's New in v1.0.0",
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildWhatsNewItem('🤖', 'Autonomous mobile DOM execution'),
            const SizedBox(height: 12),
            _buildWhatsNewItem('⚡', 'Groq Llama 3.3 70B — sub-400ms responses'),
            const SizedBox(height: 12),
            _buildWhatsNewItem('🔗', 'MCP tool connections (Google, GitHub, Notion)'),
            const SizedBox(height: 12),
            _buildWhatsNewItem('📚', 'Library agents with custom capabilities'),
            const SizedBox(height: 12),
            _buildWhatsNewItem('🎯', 'Real-time task tracking with live status'),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsNewItem(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131124),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            Text('Version: 1.0.0 (Build 1)',
                style:
                    GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Engine: Flutter 3.x / Android Native',
                style:
                    GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text('AI: Llama 3.3 70B via Groq (<400ms)',
                style:
                    GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
                'Architecture: Local-First Dual-Speed Cognitive Engine',
                style:
                    GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.inter(color: AppColors.accentCyan)),
          ),
        ],
      ),
    );
  }
}
