// lib/services/jack_permission_service.dart
//
// Manages device permissions for JACK Mobile Agent:
// - Accessibility Service (Screen DOM automation, auto-click, gestures)
// - Overlay Window (Floating Orb bubble over other apps)
// - Microphone (Voice speech-to-text)
// - Notifications Listener (Reading notifications)
// - Phone & Contacts (Direct calling and contact resolution)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class JackPermissionStatus {
  final bool accessibility;
  final bool overlay;
  final bool microphone;
  final bool notification;
  final bool contacts;

  const JackPermissionStatus({
    required this.accessibility,
    required this.overlay,
    required this.microphone,
    required this.notification,
    required this.contacts,
  });

  bool get allGranted =>
      accessibility && overlay && microphone && notification;
}

class JackPermissionService {
  static const MethodChannel _overlayChannel =
      MethodChannel('com.syncra.syncra/overlay');
  static const MethodChannel _controllerChannel =
      MethodChannel('com.jack.agent/controller');

  static Future<JackPermissionStatus> checkAll() async {
    bool a11y = false;
    bool overlay = false;
    bool mic = false;
    bool notif = false;
    bool contacts = false;

    try {
      final res = await _controllerChannel.invokeMethod<bool>('isAccessibilityActive');
      a11y = res ?? false;
    } catch (_) {}

    try {
      final res = await _overlayChannel.invokeMethod<bool>('hasPermission');
      overlay = res ?? false;
    } catch (_) {}

    try {
      mic = await Permission.microphone.isGranted;
    } catch (_) {}

    try {
      notif = await Permission.notification.isGranted;
    } catch (_) {}

    try {
      contacts = await Permission.contacts.isGranted;
    } catch (_) {}

    return JackPermissionStatus(
      accessibility: a11y,
      overlay: overlay,
      microphone: mic,
      notification: notif,
      contacts: contacts,
    );
  }

  static Future<void> requestAll(BuildContext context) async {
    try {
      await _overlayChannel.invokeMethod('requestPermission');
    } catch (_) {}
    try {
      await Permission.microphone.request();
    } catch (_) {}
    try {
      await Permission.notification.request();
    } catch (_) {}
    try {
      await Permission.contacts.request();
    } catch (_) {}
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _controllerChannel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  static void showPermissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _JackPermissionSheetContent(),
    );
  }
}

class _JackPermissionSheetContent extends StatefulWidget {
  const _JackPermissionSheetContent();

  @override
  State<_JackPermissionSheetContent> createState() =>
      _JackPermissionSheetContentState();
}

class _JackPermissionSheetContentState
    extends State<_JackPermissionSheetContent> {
  JackPermissionStatus _status = const JackPermissionStatus(
    accessibility: false,
    overlay: false,
    microphone: false,
    notification: false,
    contacts: false,
  );

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await JackPermissionService.checkAll();
    if (mounted) {
      setState(() {
        _status = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Device & DOM Permissions',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grant permissions for Jack to automate actions, listen via voice, and control apps.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildItem(
            icon: Icons.accessibility_new_rounded,
            color: const Color(0xFF00FF88),
            title: 'Accessibility Service (DOM Automation)',
            subtitle: 'Enables Jack to click, scroll, and type in apps',
            granted: _status.accessibility,
            onAction: () async {
              await JackPermissionService.openAccessibilitySettings();
              await Future.delayed(const Duration(seconds: 2));
              _refresh();
            },
          ),
          const SizedBox(height: 12),
          _buildItem(
            icon: Icons.picture_in_picture_rounded,
            color: AppColors.accentCyan,
            title: 'Draw Over Other Apps (Floating Orb)',
            subtitle: 'Allows Jack to show floating bubble on any screen',
            granted: _status.overlay,
            onAction: () async {
              await JackPermissionService.requestAll(context);
              await Future.delayed(const Duration(seconds: 1));
              _refresh();
            },
          ),
          const SizedBox(height: 12),
          _buildItem(
            icon: Icons.mic_rounded,
            color: AppColors.accentPink,
            title: 'Microphone (Voice Listening)',
            subtitle: 'Allows real-time voice conversations with Jack',
            granted: _status.microphone,
            onAction: () async {
              await Permission.microphone.request();
              _refresh();
            },
          ),
          const SizedBox(height: 12),
          _buildItem(
            icon: Icons.notifications_active_rounded,
            color: AppColors.accentViolet,
            title: 'Notification Access',
            subtitle: 'Enables Jack to read and announce alerts',
            granted: _status.notification,
            onAction: () async {
              await JackPermissionService.requestAll(context);
              _refresh();
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                await JackPermissionService.requestAll(context);
                await _refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: Text(
                'Grant All Permissions',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool granted,
    required VoidCallback onAction,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          granted
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'Enable',
                      style: GoogleFonts.inter(
                        color: AppColors.accentCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
