// lib/widgets/overlay/jack_floating_overlay_host.dart
//
// Jack Floating Bubble & Multitasking Multimodal Overlay.
// Matches the Gemini Live floating overlay architecture:
// - Root Container: Wide pill-shaped / rounded-rectangle glass card
// - Multimodal Controls: Camera (screen context), Plus (+) tools menu, Mic, Account
// - Waveform Banner: Status text ("Listening..."), animated glowing waveform bars, actionable hint text
// - Trigger Context: Temporary "Minimize" pill above the interface
// - Explanatory System Prompt: Slides out on minimize ("Jack is still available while you multitask...")
// - Morphing Animation: Gooey contraction/expansion into the compact Jack Orb
// - Six-Position Snap Grid: Top-L/R, Mid-L/R, Bot-L/R magnetic snap
// - Drag to Dismiss: Circular cross (X) zone at bottom center with magnetic expand & haptics
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api/direct_groq_service.dart';
import '../../services/overlay/jack_floating_overlay_controller.dart';
import '../../services/telephony/jack_call_screener_service.dart';
import '../../services/voice/jack_voice_service.dart';
import '../../theme/app_colors.dart';
import '../jack_orb.dart';

class JackFloatingOverlayHost extends ConsumerStatefulWidget {
  final Widget child;

  const JackFloatingOverlayHost({super.key, required this.child});

  @override
  ConsumerState<JackFloatingOverlayHost> createState() =>
      _JackFloatingOverlayHostState();
}

class _JackFloatingOverlayHostState extends ConsumerState<JackFloatingOverlayHost>
    with TickerProviderStateMixin {
  static const double _bubbleSize = 62.0;

  late AnimationController _waveAnimCtrl;
  final TextEditingController _queryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveAnimCtrl.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _showToolDrawer(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121026),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.accentCyan, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Pull-in Multimodal Tools',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _toolTile(
              icon: Icons.screen_search_desktop_rounded,
              title: 'Analyze Visible Screen',
              subtitle: 'Jack inspects visible elements across your apps',
              color: AppColors.accentCyan,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(jackFloatingOverlayProvider.notifier).captureScreen();
              },
            ),
            _toolTile(
              icon: Icons.phone_callback_rounded,
              title: 'Autonomous Call Screener',
              subtitle: 'Trigger a simulated call for Jack to answer',
              color: const Color(0xFF22C55E),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(jackFloatingOverlayProvider.notifier).minimize();
                JackCallScreenerService.instance.triggerIncomingCall(
                  context,
                  ref,
                  callerName: 'Alex Rivera (Design Lead)',
                  phoneNumber: '+1 (415) 392-4910',
                );
              },
            ),
            _toolTile(
              icon: Icons.code_rounded,
              title: 'GitHub Repo Sync',
              subtitle: 'Inspect commit history and PR statuses',
              color: const Color(0xFF38BDF8),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(jackFloatingOverlayProvider.notifier).minimize();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GitHub MCP synchronized with Jack.'),
                    backgroundColor: AppColors.surfaceElevated,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: Colors.white60,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }

  void _handleUserQuery(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;
    _queryCtrl.clear();
    HapticFeedback.lightImpact();

    final notifier = ref.read(jackFloatingOverlayProvider.notifier);
    notifier.toggleVoiceListening();

    try {
      final groq = ref.read(directGroqServiceProvider);
      final response = await groq.generate(
        prompt:
            "You are Jack, a concise multimodal assistant running in a multitasking overlay over other apps. "
            "Respond in 1-2 sharp, highly actionable sentences: $text",
      );
      final clean = response.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();
      notifier.show();
      // Speak out loud in British male JARVIS voice
      if (clean.isNotEmpty) {
        ref.read(jackVoiceProvider.notifier).speakJarvis(clean);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(clean.isNotEmpty ? clean : 'Jack responded to your query.'),
          backgroundColor: const Color(0xFF1D1836),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final overlayState = ref.watch(jackFloatingOverlayProvider);
    final notifier = ref.read(jackFloatingOverlayProvider.notifier);

    final screenSize = MediaQuery.sizeOf(context);
    final safeArea = MediaQuery.paddingOf(context);

    // Initial positioning guarantee
    final anchors = JackFloatingOverlayNotifier.computeSnapAnchors(
      screenSize: screenSize,
      safeArea: safeArea,
      bubbleSize: _bubbleSize,
    );

    final activePos = overlayState.isDragging
        ? overlayState.bubblePosition
        : anchors[overlayState.snapGridIndex.clamp(0, 5)];

    final dismissCenter = JackFloatingOverlayNotifier.computeDismissCenter(
      screenSize: screenSize,
      safeArea: safeArea,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // The underlying application UI
          Positioned.fill(child: widget.child),

          // If overlay dismissed entirely, show tiny reactivation pill on profile/home
          if (!overlayState.isVisible)
            Positioned(
              right: 16,
              bottom: safeArea.bottom + 76,
              child: GestureDetector(
                onTap: notifier.show,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A182F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const JackOrb(size: 20, state: OrbState.working),
                      const SizedBox(width: 8),
                      Text(
                        'Enable Jack Overlay',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (overlayState.isVisible) ...[
            // ── DRAG TO DISMISS / CROSS ZONE ──────────────────────────────
            if (overlayState.isDragging && !overlayState.isExpanded)
              Positioned(
                left: dismissCenter.dx - (overlayState.isInDismissZone ? 38 : 28),
                top: dismissCenter.dy - (overlayState.isInDismissZone ? 38 : 28),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: overlayState.isInDismissZone ? 76 : 56,
                  height: overlayState.isInDismissZone ? 76 : 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: overlayState.isInDismissZone
                        ? const Color(0xFFEF4444).withValues(alpha: 0.85)
                        : const Color(0xFF1F1D32).withValues(alpha: 0.8),
                    border: Border.all(
                      color: overlayState.isInDismissZone
                          ? Colors.white
                          : const Color(0xFFEF4444).withValues(alpha: 0.6),
                      width: overlayState.isInDismissZone ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444)
                            .withValues(alpha: overlayState.isInDismissZone ? 0.6 : 0.2),
                        blurRadius: overlayState.isInDismissZone ? 24 : 10,
                        spreadRadius: overlayState.isInDismissZone ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: overlayState.isInDismissZone ? 32 : 24,
                    ),
                  ),
                ),
              ),

            // ── COMPACT FLOATING BUBBLE + EXPLANATORY PROMPT ──────────────
            if (!overlayState.isExpanded) ...[
              // Explanatory System Prompt (slides out when minimized)
              if (overlayState.showExplanatoryPrompt)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: activePos.dx > screenSize.width / 2
                      ? (activePos.dx - 240).clamp(16.0, screenSize.width - 260)
                      : (activePos.dx + _bubbleSize + 12),
                  top: activePos.dy + 8,
                  child: Container(
                    width: 230,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141228).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentCyan.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentCyan.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(color: Colors.black45, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.accentCyan, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Multitasking Mode',
                              style: GoogleFonts.inter(
                                color: AppColors.accentCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jack is still available while you multitask. Tap to expand. Drag to move or dismiss.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // The Floating Bubble (Snapping to 6-grid positions)
              AnimatedPositioned(
                duration: overlayState.isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 340),
                curve: Curves.easeOutBack,
                left: activePos.dx,
                top: activePos.dy,
                child: GestureDetector(
                  onTap: notifier.expand,
                  onPanStart: (_) => notifier.onPanStart(),
                  onPanUpdate: (details) => notifier.onPanUpdate(
                    details.delta,
                    screenSize,
                    safeArea,
                    _bubbleSize,
                  ),
                  onPanEnd: (_) => notifier.onPanEnd(
                    screenSize,
                    safeArea,
                    _bubbleSize,
                  ),
                  child: Container(
                    width: _bubbleSize,
                    height: _bubbleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF281E4E),
                          Color(0xFF0F0E20),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.accentCyan.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentCyan.withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                        const BoxShadow(
                          color: Colors.black87,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Center(
                      child: JackOrb(
                        size: 52,
                        state: OrbState.working,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── EXPANDED MULTIMODAL OVERLAY CARD (GEMINI ARCHITECTURE) ────
            if (overlayState.isExpanded) ...[
              // Scrim barrier (tap outside to minimize)
              Positioned.fill(
                child: GestureDetector(
                  onTap: notifier.minimize,
                  child: Container(color: Colors.black45),
                ),
              ),

              // The Root Container: Wide pill-shaped / rounded-rectangle card
              Positioned(
                left: 16,
                right: 16,
                bottom: safeArea.bottom + 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.88, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0D22).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.accentCyan.withValues(alpha: 0.35),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentPurple.withValues(alpha: 0.3),
                              blurRadius: 36,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── TRIGGER CONTEXT: MINIMIZE BUTTON HEADER ───
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 12, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Jack agent badge
                                  Row(
                                    children: [
                                      const JackOrb(size: 22, state: OrbState.listening),
                                      const SizedBox(width: 8),
                                      Text(
                                        'JACK OVERLAY',
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.8,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Temporary Minimize & Close actions
                                  Row(
                                    children: [
                                      // Minimize button
                                      GestureDetector(
                                        onTap: notifier.minimize,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                color: Colors.white70,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Minimize',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white70,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Close button
                                      GestureDetector(
                                        onTap: notifier.dismiss,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(alpha: 0.08),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white60,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ── MULTIMODAL CONTROLS (THE TOP LAYER) ───────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  // Camera / Screen Context button
                                  _multimodalButton(
                                    icon: Icons.camera_alt_rounded,
                                    label: 'Camera',
                                    onTap: notifier.captureScreen,
                                  ),
                                  const SizedBox(width: 8),

                                  // Plus (+) Menu to pull in tools
                                  _multimodalButton(
                                    icon: Icons.add_rounded,
                                    label: 'Tools (+)',
                                    onTap: () => _showToolDrawer(context),
                                  ),
                                  const SizedBox(width: 8),

                                  // Mic / Audio Toggle
                                  _multimodalButton(
                                    icon: overlayState.isListening
                                        ? Icons.mic_rounded
                                        : Icons.mic_off_rounded,
                                    label: overlayState.isListening ? 'Live' : 'Muted',
                                    color: overlayState.isListening
                                        ? AppColors.accentPink
                                        : Colors.white54,
                                    onTap: notifier.toggleVoiceListening,
                                  ),

                                  const Spacer(),

                                  // Account / Profile Access
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 10,
                                          backgroundColor: AppColors.accentCyan,
                                          child: Icon(Icons.person,
                                              size: 12, color: Colors.black),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Easin',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── THE WAVEFORM BANNER (ACTIVE STATUS BOX) ───
                            Container(
                              margin: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF231B4A),
                                    Color(0xFF14122C),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Status Text Header + Visual Waveform Glow
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: overlayState.isListening
                                                  ? AppColors.accentCyan
                                                  : Colors.white38,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            overlayState.statusText,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Visual Waveform (Glow Interface)
                                      _buildWaveformBars(
                                        intensity: overlayState.waveformIntensity,
                                        active: overlayState.isListening,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // System Hint Text
                                  Text(
                                    overlayState.hintText,
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Quick Text Input Row
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _queryCtrl,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            textInputAction: TextInputAction.send,
                                            onSubmitted: _handleUserQuery,
                                            decoration: InputDecoration(
                                              hintText: 'Type to Jack or speak...',
                                              hintStyle: GoogleFonts.inter(
                                                color: Colors.white38,
                                                fontSize: 13,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _handleUserQuery(_queryCtrl.text),
                                          child: const Icon(
                                            Icons.arrow_upward_rounded,
                                            color: AppColors.accentCyan,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _multimodalButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color ?? Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformBars({required double intensity, required bool active}) {
    final barHeights = [
      0.35 * intensity,
      0.80 * intensity,
      0.50 * intensity,
      1.00 * intensity,
      0.65 * intensity,
      0.90 * intensity,
      0.40 * intensity,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final h = (barHeights[i] * 18).clamp(4.0, 20.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3.5,
          height: active ? h : 4.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: active
                  ? [
                      const Color(0xFF00E5FF),
                      const Color(0xFFA855F7),
                      const Color(0xFFEC4899),
                    ]
                  : [Colors.white24, Colors.white24],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
