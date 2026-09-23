// lib/services/notifications/jack_notification_service.dart
//
// In-app notifications & heads-up banner engine for JACK Mobile Agent.
// Dispatches visual heads-up alerts with haptic feedback when
// autonomous agents, automations, or call screenings complete.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class JackNotificationItem {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final DateTime timestamp;
  final VoidCallback? onTap;

  const JackNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_rounded,
    this.iconColor = AppColors.accentCyan,
    required this.timestamp,
    this.onTap,
  });
}

class JackNotificationService {
  JackNotificationService._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showHeadsUp({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color accentColor = AppColors.accentCyan,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        content: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF161427).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white38, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
