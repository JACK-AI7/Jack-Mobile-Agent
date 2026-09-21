import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/jack_auth_state.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Account and preferences',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Premium gradient banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2B6BFF), // Accent Blue
                      Color(0xFF7C3AED), // Accent Violet
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2B6BFF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF0A0A0A)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          userNameAsync.when(
                            data: (name) => Text(
                              name ?? 'Guest User',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => const SizedBox(
                              height: 20,
                              width: 100,
                              child: LinearProgressIndicator(color: Colors.white54, backgroundColor: Colors.transparent),
                            ),
                            error: (error, stackTrace) => Text(
                              'Error loading name',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Pro',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Settings list
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsItem('Account', Icons.person_outline_rounded, onTap: () {}),
                    _buildDivider(),
                    _buildSettingsItem('Security', Icons.shield_outlined, onTap: () {}),
                    _buildDivider(),
                    _buildSettingsItem('Billing', Icons.credit_card_outlined, onTap: () {}),
                    _buildDivider(),
                    _buildSettingsItem('Integrations', Icons.extension_outlined, onTap: () {}),
                    _buildDivider(),
                    _buildSettingsItem('Appearance', Icons.palette_outlined, onTap: () {}),
                    _buildDivider(),
                    _buildSettingsItem('Help & Support', Icons.help_outline_rounded, onTap: () {}),
                    _buildDivider(),
                    _buildSettingsItem(
                      'Logout',
                      Icons.logout_rounded,
                      isDestructive: true,
                      onTap: () => ref.read(authStateProvider.notifier).logout(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, {VoidCallback? onTap, bool isDestructive = false}) {
    final color = isDestructive ? AppColors.error : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive ? AppColors.error.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isDestructive ? AppColors.error : Colors.white70, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 64,
    );
  }
}
