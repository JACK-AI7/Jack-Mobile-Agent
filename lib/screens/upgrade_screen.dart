// lib/screens/upgrade_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _isYearly = false;

  String get _price => _isYearly ? '\$12.80' : '\$16';
  String get _period => _isYearly ? '/ month · billed \$153.60/yr' : '/ month';

  static const _features = [
    'Unlimited automations',
    'Advanced tools & models',
    'Priority processing',
    'Custom agents',
    'Early access to new features',
    'Persistent memory',
    'Voice commands',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upgrade', style: AppTypography.sectionHeading(size: 22)),
            Text('Unlock more power with Jack Pro.', style: AppTypography.caption()),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Billing toggle ─────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleOption('Monthly', !_isYearly, () => setState(() => _isYearly = false)),
                    _ToggleOption('Yearly', _isYearly, () => setState(() => _isYearly = true),
                        badge: 'Save 20%'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Pro plan card ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accentCyan, AppColors.accentViolet],
                ),
              ),
              padding: const EdgeInsets.all(1.5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.5),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0E0E28), Color(0xFF080820)],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentCyan, AppColors.accentViolet],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('PRO',
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black)),
                        ),
                        const Spacer(),
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: RichText(
                        key: ValueKey(_price),
                        text: TextSpan(children: [
                          TextSpan(
                            text: _price,
                            style: AppTypography.kpi(size: 42),
                          ),
                          TextSpan(
                            text: ' $_period',
                            style: AppTypography.caption(size: 13),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentCyan.withOpacity(0.15),
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: AppColors.accentCyan, size: 12),
                              ),
                              const SizedBox(width: 10),
                              Text(f, style: AppTypography.body(size: 14, color: AppColors.textPrimary)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, duration: 400.ms),

            const SizedBox(height: 20),

            // ── CTA ────────────────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upgrade flow coming soon!',
                        style: AppTypography.body(size: 14, color: Colors.white)),
                    backgroundColor: AppColors.surfaceElevated,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.accentCyan, AppColors.accentViolet],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Upgrade to Pro', style: AppTypography.button(size: 16, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text('Secure payment. Cancel anytime.',
                    style: AppTypography.caption(size: 12, color: AppColors.textTertiary)),
              ],
            ),

            const SizedBox(height: 32),

            // ── Free comparison ────────────────────────────────────────────
            Text('Compare plans', style: AppTypography.bodySemiBold(size: 15)),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _CompareRow('Feature', 'Free', 'Pro', isHeader: true),
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  _CompareRow('Daily tasks', '5', 'Unlimited'),
                  _CompareRow('Automations', '2', 'Unlimited'),
                  _CompareRow('Custom agents', '—', '✓'),
                  _CompareRow('AI models', 'Basic', 'Advanced'),
                  _CompareRow('Memory', '—', '✓'),
                  _CompareRow('Priority speed', '—', '✓'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _ToggleOption(this.label, this.selected, this.onTap, {this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentCyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(label,
                style: AppTypography.caption(
                    size: 13, color: selected ? AppColors.accentCyan : AppColors.textSecondary)),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge!,
                    style: AppTypography.caption(size: 9, color: AppColors.warning)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String feature;
  final String free;
  final String pro;
  final bool isHeader;

  const _CompareRow(this.feature, this.free, this.pro, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(feature,
                style: isHeader
                    ? AppTypography.caption(size: 11, color: AppColors.textTertiary)
                    : AppTypography.body(size: 13, color: AppColors.textPrimary)),
          ),
          Expanded(
            child: Text(free,
                textAlign: TextAlign.center,
                style: AppTypography.caption(
                    size: isHeader ? 11 : 13,
                    color: isHeader ? AppColors.textTertiary : AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(pro,
                textAlign: TextAlign.center,
                style: AppTypography.caption(
                    size: isHeader ? 11 : 13,
                    color: isHeader ? AppColors.accentCyan : AppColors.accentCyan)),
          ),
        ],
      ),
    );
  }
}
