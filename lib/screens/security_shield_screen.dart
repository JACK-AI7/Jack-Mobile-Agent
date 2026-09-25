// lib/screens/security_shield_screen.dart
//
// Jack AI Security, Scam, Spam, Hack & DOM Phishing Shield Dashboard.
// Cyber-HUD with live security gauge, active shields, and intercepted threat logs.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/security/jack_security_shield_service.dart';
import '../theme/app_colors.dart';

class SecurityShieldScreen extends ConsumerWidget {
  const SecurityShieldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sec = ref.watch(jackSecurityProvider);
    final notifier = ref.read(jackSecurityProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF07070C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Security Shield',
          style: GoogleFonts.cormorantGaramond(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF22C55E), size: 14),
                const SizedBox(width: 6),
                Text(
                  'IMMORTAL',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP SECURITY SCORE GAUGE ──
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: sec.securityScore / 100.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${sec.securityScore}%',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'SECURE',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF22C55E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Center(
              child: Text(
                'Zero Active Vulnerabilities • All 4 Shields Armed',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
            ),

            const SizedBox(height: 24),

            // ── LIVE METRIC COUNTERS ──
            Row(
              children: [
                _metricCard('Scams Blocked', '${sec.totalScamsBlocked}', const Color(0xFFF43F5E), Icons.phone_disabled_rounded),
                const SizedBox(width: 10),
                _metricCard('Phishing Neutered', '${sec.totalPhishingNeutered}', const Color(0xFFF59E0B), Icons.link_off_rounded),
                const SizedBox(width: 10),
                _metricCard('DOM Intercepts', '${sec.totalDomAttacksPrevented}', const Color(0xFF38BDF8), Icons.security_rounded),
              ],
            ),

            const SizedBox(height: 24),

            // ── ACTIVE SHIELD TOGGLES ──
            Text(
              'Autonomous Shields',
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _shieldTile(
              title: 'Anti-Scam Telephony Shield',
              subtitle: 'Real-time AI scan for OTP coercion & imposter calls',
              icon: Icons.phone_in_talk_rounded,
              color: const Color(0xFFF43F5E),
              value: sec.antiScamCallShield,
              onChanged: notifier.toggleAntiScamCall,
            ),
            _shieldTile(
              title: 'Anti-Phishing SMS Scanner',
              subtitle: 'Quarantines fraudulent URLs and fake bank notices',
              icon: Icons.sms_failed_rounded,
              color: const Color(0xFFF59E0B),
              value: sec.antiPhishingSmsShield,
              onChanged: notifier.toggleAntiPhishingSms,
            ),
            _shieldTile(
              title: 'DOM Credential & Keystroke Guard',
              subtitle: 'Blocks automated typing in unverified webviews',
              icon: Icons.fingerprint_rounded,
              color: const Color(0xFF38BDF8),
              value: sec.domPhishingGuard,
              onChanged: notifier.toggleDomGuard,
            ),
            _shieldTile(
              title: 'Malicious Overlay Blocker',
              subtitle: 'Neutralizes hidden tap-jacking windows outside app',
              icon: Icons.layers_clear_rounded,
              color: const Color(0xFFA855F7),
              value: sec.maliciousOverlayBlocker,
              onChanged: notifier.toggleOverlayBlocker,
            ),

            const SizedBox(height: 24),

            // ── DEEP AUDIT BUTTON ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: sec.isAuditRunning
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        notifier.runSystemSecurityAudit();
                      },
                icon: sec.isAuditRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
                label: Text(
                  sec.isAuditRunning ? 'Auditing System Integrity...' : 'Run Deep Security Audit',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1B4B),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── RECENT THREAT INTERCEPT LOGS ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Intercept Logs (${sec.threatLogs.length})',
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Protected by Jack',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...sec.threatLogs.map((log) => _threatLogTile(log)),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF11101E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shieldTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11101E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF22C55E),
            activeTrackColor: const Color(0xFF22C55E).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _threatLogTile(ThreatLog log) {
    final isCritical = log.severity == ThreatSeverity.critical;
    final badgeColor = isCritical ? const Color(0xFFF43F5E) : const Color(0xFF38BDF8);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11101E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCritical ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
              color: badgeColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.category,
                      style: GoogleFonts.inter(
                        color: badgeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'BLOCKED',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF22C55E),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.description,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
