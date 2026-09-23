// lib/screens/upgrade_screen.dart
//
// 11. Upgrade — Upgrade to Pro for more power
// Pixel-to-pixel match of Screen 11:
// Header serif "Upgrade" + subtitle.
// Segmented billing toggle: [Monthly] [Yearly  Save 20%] — Yearly active (sky-blue).
// Purple-glowing Pro card: ∞ Pro badge, 5 feature checkmarks, $16/month price,
// billing note, full-width periwinkle CTA "Upgrade to Pro →" button.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  // Start on Yearly (active in reference image)
  bool _isYearly = true;

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
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // ── Header ────────────────────────────────────────────────────
              Text(
                'Upgrade',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock more power with Jack Pro.',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 28),

              // ── Billing Toggle: [Monthly] [Yearly  Save 20%] ─────────────
              // Matches reference: dark pill container, active = sky-blue bg
              Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF131221),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Monthly pill
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isYearly = false);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: !_isYearly
                                ? const Color(0xFF38BDF8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Monthly',
                                  style: GoogleFonts.inter(
                                    color: !_isYearly
                                        ? Colors.black
                                        : Colors.white70,
                                    fontSize: 13.5,
                                    fontWeight: !_isYearly
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Yearly pill with "Save 20%" badge
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isYearly = true);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _isYearly
                                ? const Color(0xFF38BDF8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Yearly',
                                      style: GoogleFonts.inter(
                                        color: _isYearly
                                            ? Colors.black
                                            : Colors.white70,
                                        fontSize: 13.5,
                                        fontWeight: _isYearly
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    // "Save 20%" badge — green when inactive,
                                    // dark when active (matching reference)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _isYearly
                                            ? Colors.black.withValues(alpha: 0.20)
                                            : const Color(0xFF22C55E)
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Save 20%',
                                        style: GoogleFonts.inter(
                                          color: _isYearly
                                              ? Colors.black
                                              : const Color(0xFF22C55E),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Pro Card — purple border glow matching Screen 11 ──────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF100E20),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF6B46C1).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B46C1).withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF6B46C1).withValues(alpha: 0.10),
                      blurRadius: 80,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ∞ Pro badge header
                    Row(
                      children: [
                        const Icon(
                          Icons.all_inclusive_rounded,
                          color: AppColors.accentCyan,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pro',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Feature checklist — 5 items matching reference
                    _buildFeatureItem('Unlimited automations'),
                    const SizedBox(height: 12),
                    _buildFeatureItem('Advanced tools & models'),
                    const SizedBox(height: 12),
                    _buildFeatureItem('Priority processing'),
                    const SizedBox(height: 12),
                    _buildFeatureItem('Custom agents'),
                    const SizedBox(height: 12),
                    _buildFeatureItem('Early access to new features'),

                    const SizedBox(height: 28),

                    // Price: $16 / month  (Yearly) or $19 / month (Monthly)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isYearly ? '\$16' : '\$19',
                            key: ValueKey(_isYearly),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ month',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _isYearly
                            ? 'Billed yearly at \$192'
                            : 'Billed monthly',
                        key: ValueKey('billing_$_isYearly'),
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 12.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // CTA: "Upgrade to Pro →" — periwinkle/lavender fill
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Payment gateway launching soon! Your subscription will be activated.'),
                              backgroundColor: AppColors.surfaceElevated,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC7BFFF),
                          foregroundColor: const Color(0xFF0F0E1E),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Upgrade to Pro',
                                style: GoogleFonts.inter(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F0E1E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Color(0xFF0F0E1E),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Fine print
              Center(
                child: Text(
                  'Cancel anytime. No commitment.',
                  style: GoogleFonts.inter(
                    color: Colors.white24,
                    fontSize: 11.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_rounded,
          color: AppColors.accentCyan,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
