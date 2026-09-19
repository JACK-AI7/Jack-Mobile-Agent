// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    // ── Avatar ────────────────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.accentCyan, AppColors.accentViolet],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text('Jack Agent', style: AppTypography.bodySemiBold(size: 20, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('jack@jackagent.ai', style: AppTypography.caption(size: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Always learning. Always working.',
                        style: AppTypography.caption(size: 11, color: AppColors.accentCyan),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Stats ─────────────────────────────────────────────────
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          _Stat('148', 'Tasks Done'),
                          Container(width: 1, height: 32, color: AppColors.surfaceBorder),
                          _Stat('8', 'Agents'),
                          Container(width: 1, height: 32, color: AppColors.surfaceBorder),
                          _Stat('38.5h', 'Saved'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                _Section(title: 'Account', items: [
                  _SectionItem(Icons.manage_accounts_rounded, 'Account', 'Manage your account', AppColors.accentCyan),
                  _SectionItem(Icons.security_rounded, 'Permissions', 'Control what Jack can do', AppColors.accentViolet),
                  _SectionItem(Icons.psychology_rounded, 'Memory', 'Manage what Jack remembers', AppColors.accentBlue),
                ]),
                _Section(title: 'Preferences', items: [
                  _SectionItem(Icons.palette_rounded, 'Appearance', 'Theme, language, voice', AppColors.accentPink),
                  _SectionItem(Icons.notifications_rounded, 'Notifications', 'Alerts & push settings', AppColors.warning),
                  _SectionItem(Icons.link_rounded, 'Connected Accounts', 'Google, GitHub, Slack', AppColors.accentTeal),
                ]),
                _Section(title: 'Billing & Privacy', items: [
                  _SectionItem(Icons.workspace_premium_rounded, 'Usage & Billing', 'Pro tier · quota', AppColors.warning,
                      onTap: () => context.push('/upgrade')),
                  _SectionItem(Icons.shield_rounded, 'Security', 'Privacy & data controls', AppColors.success),
                  _SectionItem(Icons.info_rounded, 'About Jack', 'Version 1.0.0', AppColors.textSecondary),
                ]),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text('Sign Out', style: AppTypography.body(size: 15, color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.kpi(size: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(size: 11)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_SectionItem> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: AppTypography.label(color: AppColors.textTertiary)),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: items.asMap().entries.map((e) {
                final isLast = e.key == items.length - 1;
                return Column(
                  children: [
                    GestureDetector(
                      onTap: e.value.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: e.value.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(e.value.icon, color: e.value.color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.value.title, style: AppTypography.bodyMedium(size: 14)),
                                  Text(e.value.subtitle, style: AppTypography.caption(size: 11)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 58, color: AppColors.surfaceBorder),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _SectionItem(this.icon, this.title, this.subtitle, this.color, {this.onTap});
}
