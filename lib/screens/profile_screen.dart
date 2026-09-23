// lib/screens/profile_screen.dart
//
// 10. Profile — Settings and preferences
// Pixel-to-pixel match: JackOrb avatar, Jack Agent + Pro badge, email,
// tagline, then 5 settings menu rows: Account, Permissions, Memory,
// Appearance, Security — each with icon, title, subtitle, chevron.
// GlassNavBar at bottom with Profile (index 4) active.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jack_auth_state.dart';
import '../services/jack_permission_service.dart';
import '../services/api/direct_groq_service.dart';
import '../providers/tasks_provider.dart';
import '../providers/automations_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/jack_orb.dart';
import '../widgets/glass_nav_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showApiKeyDialog(BuildContext context) async {
    final groq = DirectGroqService();
    final currentKey = await groq.getApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131124),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'AI Model Configuration',
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
            Text(
              'Enter your Groq API Key (gsk_...) to enable high-speed Llama 3.3 70B reasoning.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'gsk_...',
                hintStyle: GoogleFonts.inter(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E1C35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              await groq.saveApiKey(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Groq API Key saved successfully!'),
                    backgroundColor: AppColors.surfaceElevated,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save Key',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);
    final displayName = userNameAsync.when(
      data: (name) =>
          (name != null && name.trim().isNotEmpty) ? name.trim() : 'Easin',
      loading: () => 'Easin',
      error: (err, stack) => 'Easin',
    );

    final tasksAsync = ref.watch(tasksProvider);
    final automationsAsync = ref.watch(automationsProvider);

    final completedTaskCount = tasksAsync.maybeWhen(
      data: (tasks) =>
          tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').length,
      orElse: () => null,
    );
    final automationCount = automationsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => null,
    );
    final activeAutomationCount = automationsAsync.maybeWhen(
      data: (list) => list.where((a) => a.isActive).length,
      orElse: () => null,
    );

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
      body: Stack(
        children: [
          // Subtle radial glow matching reference dark purple background
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.5),
                  radius: 0.85,
                  colors: [
                    Color(0xFF130B28),
                    Color(0xFF07070A),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // ── Page header: "Profile" serif
                  Text(
                    'Profile',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── User card: JackOrb + name + email + tagline ──────────
                  _buildUserCard(displayName),

                  const SizedBox(height: 20),

                  // ── Live stats row ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Tasks Done',
                          completedTaskCount != null
                              ? '$completedTaskCount'
                              : '5',
                          AppColors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Active',
                          activeAutomationCount != null
                              ? '$activeAutomationCount'
                              : '2',
                          const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Agents',
                          automationCount != null ? '$automationCount' : '3',
                          const Color(0xFF00FF88),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Main settings menu matching Screen 10 exactly ─────────
                  // 5 items: Account, Permissions, Memory, Appearance, Security
                  _buildMenuSection([
                    _buildMenuItem(
                      context: context,
                      icon: Icons.person_outline_rounded,
                      title: 'Account',
                      subtitle: 'Manage your account',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/upgrade');
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      title: 'Permissions',
                      subtitle: 'Control what Jack can do',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        JackPermissionService.showPermissionSheet(context);
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.psychology_outlined,
                      title: 'Memory',
                      subtitle: 'Manage what Jack remembers',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/autonomy');
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Theme, language, voice',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showApiKeyDialog(context);
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.shield_outlined,
                      title: 'Security',
                      subtitle: 'Privacy & data controls',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        JackPermissionService.showPermissionSheet(context);
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Sign out button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 18),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom nav bar — Profile is index 4 (active)
      bottomNavigationBar: GlassNavBar(
        currentIndex: 4,
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
              // Already on Profile
              break;
          }
        },
      ),
    );
  }

  Widget _buildUserCard(String displayName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF11101E).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // JackOrb avatar — matches reference exactly (pause icon + gradient glow)
              const JackOrb(size: 58, state: OrbState.idle),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Pro badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Jack Agent',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF38BDF8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Pro',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${displayName.toLowerCase()}@jack.ai',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Always learning. Always working.',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

  Widget _buildStatCard(String label, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF11101E).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF11101E).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon box matching reference: subtle bg rounded square
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white70, size: 19),
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
                color: Colors.white24,
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
      color: Colors.white.withValues(alpha: 0.06),
      height: 1,
      indent: 68,
      endIndent: 16,
    );
  }
}
