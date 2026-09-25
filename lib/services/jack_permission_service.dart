// lib/services/jack_permission_service.dart
//
// Complete Device & DOM Full-Access Permission Manager for JACK Mobile Agent.
// Controls and requests:
// 1. Accessibility Service (DOM Automation, UI Click, Gestures, Typing, Recents/Home)
// 2. Overlay Window (Floating Bubble Orb & Wide Live Gemini Pill across apps)
// 3. Microphone (Voice Recognition & Live Conversations)
// 4. Phone & Telephony (Autonomous Call Screening, Answer Calls, Direct Dialing)
// 5. Contacts (Contact Directory Resolution for Calls & Messaging)
// 6. SMS (Reading & Composing Text Messages)
// 7. Camera & Flashlight Torch (Physical hardware torch & vision)
// 8. Notifications (Listening to and reading heads-up alerts)
// 9. Battery Optimization (24/7 background agent execution)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class JackPermissionStatus {
  final bool accessibility;
  final bool overlay;
  final bool microphone;
  final bool phone;
  final bool contacts;
  final bool sms;
  final bool notification;
  final bool camera;
  final bool battery;

  const JackPermissionStatus({
    required this.accessibility,
    required this.overlay,
    required this.microphone,
    required this.phone,
    required this.contacts,
    required this.sms,
    required this.notification,
    required this.camera,
    required this.battery,
  });

  int get grantedCount {
    int count = 0;
    if (accessibility) count++;
    if (overlay) count++;
    if (microphone) count++;
    if (phone) count++;
    if (contacts) count++;
    if (sms) count++;
    if (notification) count++;
    if (camera) count++;
    if (battery) count++;
    return count;
  }

  int get totalCount => 9;

  double get progress => grantedCount / totalCount;

  bool get allGranted =>
      accessibility && overlay && microphone && phone && contacts && notification;
}

class JackPermissionService {
  JackPermissionService._();

  static const MethodChannel _controllerChannel =
      MethodChannel('com.jack.agent/controller');

  static Future<JackPermissionStatus> checkAll() async {
    bool a11y = false;
    bool overlay = false;
    bool mic = false;
    bool phone = false;
    bool contacts = false;
    bool sms = false;
    bool notif = false;
    bool camera = false;
    bool battery = false;

    // 1. Accessibility Service
    try {
      final res = await _controllerChannel.invokeMethod<bool>('isAccessibilityActive');
      a11y = res ?? false;
    } catch (_) {}

    // 2. Overlay Window
    try {
      final res = await const MethodChannel('com.jack.agent/overlay').invokeMethod<bool>('hasPermission');
      overlay = res ?? false;
      if (!overlay) {
        overlay = await FlutterOverlayWindow.isPermissionGranted();
      }
    } catch (_) {
      try {
        overlay = await FlutterOverlayWindow.isPermissionGranted();
      } catch (_) {}
    }

    // 3. Microphone
    try {
      mic = await Permission.microphone.isGranted;
    } catch (_) {}

    // 4. Phone
    try {
      phone = await Permission.phone.isGranted;
    } catch (_) {}

    // 5. Contacts
    try {
      contacts = await Permission.contacts.isGranted;
    } catch (_) {}

    // 6. SMS
    try {
      sms = await Permission.sms.isGranted;
    } catch (_) {}

    // 7. Notification
    try {
      notif = await Permission.notification.isGranted;
    } catch (_) {}

    // 8. Camera
    try {
      camera = await Permission.camera.isGranted;
    } catch (_) {}

    // 9. Battery Optimization
    try {
      battery = await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {}

    return JackPermissionStatus(
      accessibility: a11y,
      overlay: overlay,
      microphone: mic,
      phone: phone,
      contacts: contacts,
      sms: sms,
      notification: notif,
      camera: camera,
      battery: battery,
    );
  }

  static Future<void> requestAll(BuildContext context) async {
    // 1. Request all runtime permissions sequentially in batch
    try {
      await [
        Permission.microphone,
        Permission.phone,
        Permission.contacts,
        Permission.sms,
        Permission.notification,
        Permission.camera,
        Permission.ignoreBatteryOptimizations,
      ].request();
    } catch (_) {}

    // 2. Request overlay permission
    try {
      final hasOverlay = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasOverlay) {
        await FlutterOverlayWindow.requestPermission();
      }
    } catch (_) {
      try {
        await openOverlaySettings();
      } catch (_) {}
    }

    // 3. Check accessibility
    try {
      final a11yActive = await _controllerChannel.invokeMethod<bool>('isAccessibilityActive');
      if (a11yActive != true) {
        await openAccessibilitySettings();
      }
    } catch (_) {}
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _controllerChannel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  static Future<void> openOverlaySettings() async {
    try {
      await const MethodChannel('com.jack.agent/overlay').invokeMethod('requestOverlayPermission');
    } catch (_) {
      try {
        await _controllerChannel.invokeMethod('openOverlaySettings');
      } catch (_) {
        try {
          await FlutterOverlayWindow.requestPermission();
        } catch (_) {}
      }
    }
  }

  static Future<bool> hasOverlayPermission() async {
    try {
      final res = await const MethodChannel('com.jack.agent/overlay').invokeMethod<bool>('hasPermission');
      if (res == true) return true;
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  static Future<void> launchOutsideOrb() async {
    try {
      await const MethodChannel('com.jack.agent/overlay').invokeMethod('showBubble');
    } catch (_) {}
  }

  static Future<void> openWriteSettings() async {
    try {
      await _controllerChannel.invokeMethod('openWriteSettings');
    } catch (_) {}
  }

  static Future<void> openNotificationListenerSettings() async {
    try {
      await _controllerChannel.invokeMethod('openNotificationListenerSettings');
    } catch (_) {}
  }

  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _controllerChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {
      try {
        await Permission.ignoreBatteryOptimizations.request();
      } catch (_) {}
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _controllerChannel.invokeMethod('openAppSettings');
    } catch (_) {
      openAppSettings();
    }
  }

  static void showPermissionSheet(BuildContext context, {VoidCallback? onComplete}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _JackPermissionSheetContent(onComplete: onComplete),
    );
  }
}

class _JackPermissionSheetContent extends StatefulWidget {
  final VoidCallback? onComplete;

  const _JackPermissionSheetContent({this.onComplete});

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
    phone: false,
    contacts: false,
    sms: false,
    notification: false,
    camera: false,
    battery: false,
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
      height: MediaQuery.of(context).size.height * 0.90,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A1A).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: Colors.white24, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCyan.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.accentCyan, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'FULL ACCESS AUTHORIZATION',
                      style: GoogleFonts.inter(
                        color: AppColors.accentCyan,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${_status.grantedCount} / ${_status.totalCount} Granted',
                style: GoogleFonts.inter(
                  color: _status.progress >= 0.8 ? const Color(0xFF22C55E) : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            'Hardware & Software Permissions',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grant permissions for Jack to automate actions, intercept calls, listen to voice, and control device hardware seamlessly.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _status.progress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _status.progress >= 0.8
                    ? const Color(0xFF22C55E)
                    : (_status.progress >= 0.4 ? AppColors.accentCyan : AppColors.accentPink),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Master Grant All Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.heavyImpact();
                await JackPermissionService.requestAll(context);
                await Future.delayed(const Duration(seconds: 1));
                await _refresh();
              },
              icon: const Icon(Icons.flash_on_rounded, size: 20),
              label: Text(
                'Grant All Permissions Now',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Scrollable Permission Items List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(
                  icon: Icons.accessibility_new_rounded,
                  color: const Color(0xFF00FF88),
                  title: 'Accessibility Service (DOM & Actions)',
                  subtitle: 'Auto-clicks, scrolls, types text, and inspects UI nodes',
                  granted: _status.accessibility,
                  onAction: () async {
                    await JackPermissionService.openAccessibilitySettings();
                    await Future.delayed(const Duration(seconds: 2));
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.picture_in_picture_rounded,
                  color: AppColors.accentCyan,
                  title: 'Draw Over Other Apps (Floating Orb)',
                  subtitle: 'Displays Jack 3D Orb and Live Pill over all apps',
                  granted: _status.overlay,
                  onAction: () async {
                    await JackPermissionService.openOverlaySettings();
                    await Future.delayed(const Duration(seconds: 1));
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.mic_rounded,
                  color: AppColors.accentPink,
                  title: 'Microphone (Voice Conversation)',
                  subtitle: 'Real-time hands-free speech recognition and voice commands',
                  granted: _status.microphone,
                  onAction: () async {
                    await Permission.microphone.request();
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.phone_in_talk_rounded,
                  color: const Color(0xFF38BDF8),
                  title: 'Phone Calls & Call Screener',
                  subtitle: 'Screens unknown calls, speaks to callers, and dials numbers',
                  granted: _status.phone,
                  onAction: () async {
                    await Permission.phone.request();
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.contacts_rounded,
                  color: const Color(0xFFA855F7),
                  title: 'Contacts Directory',
                  subtitle: 'Resolves caller identity and dials contacts by name',
                  granted: _status.contacts,
                  onAction: () async {
                    await Permission.contacts.request();
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.sms_rounded,
                  color: const Color(0xFFFBBF24),
                  title: 'SMS Messaging',
                  subtitle: 'Reads incoming messages and composes text replies',
                  granted: _status.sms,
                  onAction: () async {
                    await Permission.sms.request();
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFFF59E0B),
                  title: 'Camera & Flashlight Torch (Hardware)',
                  subtitle: 'Turns flashlight on/off and visual assistance',
                  granted: _status.camera,
                  onAction: () async {
                    await Permission.camera.request();
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.notifications_active_rounded,
                  color: AppColors.accentViolet,
                  title: 'Notification Access & Alerts',
                  subtitle: 'Enables Jack to read and announce heads-up alerts',
                  granted: _status.notification,
                  onAction: () async {
                    await Permission.notification.request();
                    _refresh();
                  },
                ),
                const SizedBox(height: 10),
                _buildItem(
                  icon: Icons.battery_charging_full_rounded,
                  color: const Color(0xFF10B981),
                  title: 'Ignore Battery Optimizations',
                  subtitle: 'Keeps Jack active 24/7 in the background without being killed',
                  granted: _status.battery,
                  onAction: () async {
                    await JackPermissionService.openBatteryOptimizationSettings();
                    await Future.delayed(const Duration(seconds: 1));
                    _refresh();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onComplete?.call();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _status.allGranted ? 'Continue to Jack Agent' : 'Continue Anyway',
                style: GoogleFonts.inter(
                  fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, color: AppColors.success, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        'Active',
                        style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onAction();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
