// lib/screens/home_screen.dart
//
// 02. Home — Ask, search or explore anything
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/realtime/jack_orb_state.dart';
import '../services/jack_auth_state.dart';
import '../services/realtime/agent_execution_controller.dart';
import '../services/jack_master_dispatcher.dart';
import '../services/app_launcher_helper.dart';
import '../services/overlay/jack_floating_overlay_controller.dart';
import '../services/jack_permission_service.dart';
import '../services/voice/jack_voice_service.dart';
import '../services/voice/jack_wake_word_service.dart';
import '../theme/app_colors.dart';
import '../widgets/jack_orb.dart';
import '../widgets/glass_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await JackPermissionService.checkAll();
      if (!status.allGranted && mounted) {
        JackPermissionService.showPermissionSheet(context);
      } else if (mounted) {
        ref.read(jackWakeWordProvider.notifier).startMonitoring();
      }
    });
  }

  void _submitQuery(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    _searchFocus.unfocus();
    _searchController.clear();
    HapticFeedback.lightImpact();

    final reflex = await JackMasterDispatcher.tryReflexFastPath(query);
    if (reflex != null) {
      final resText = reflex['result']?.toString() ?? 'Right away, Sir.';
      ref.read(jackVoiceProvider.notifier).speakJarvis(resText);
      return;
    }

    final lower = query.toLowerCase();
    if (lower.startsWith('open ') || lower.startsWith('launch ')) {
      final appTarget = query.substring(lower.indexOf(' ') + 1).trim();
      final launched = await AppLauncherHelper.launchAppByName(appTarget);
      if (launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $appTarget...'),
              backgroundColor: AppColors.surfaceElevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      context.push('/chat', extra: query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wakeWordState = ref.watch(jackWakeWordProvider);
    final realtimeState = ref.watch(agentExecutionProvider);
    final isAwakeOrListening = wakeWordState.isListening ||
        wakeWordState.isWokenUp ||
        wakeWordState.isAwaitingTask;
    final orbState = isAwakeOrListening
        ? OrbState.listening
        : (wakeWordState.isSpeaking ||
                realtimeState.orbState == JackOrbState.THINKING ||
                realtimeState.orbState == JackOrbState.PLANNING
            ? OrbState.thinking
            : (realtimeState.orbState == JackOrbState.EXECUTING ||
                    realtimeState.orbState == JackOrbState.USING_TOOL ||
                    realtimeState.orbState == JackOrbState.SEARCHING
                ? OrbState.working
                : (realtimeState.orbState == JackOrbState.SUCCESS
                    ? OrbState.success
                    : (realtimeState.orbState == JackOrbState.ERROR
                        ? OrbState.error
                        : OrbState.idle))));

    final userNameAsync = ref.watch(userNameProvider);
    final displayName = userNameAsync.when(
      data: (name) => (name != null && name.trim().isNotEmpty) ? name.trim() : 'Jaswanth',
      loading: () => 'Jaswanth',
      error: (err, stack) => 'Jaswanth',
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    final orbSize = (screenWidth * 0.65).clamp(210.0, 260.0);

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          onPressed: () => JackPermissionService.showPermissionSheet(context),
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
        actions: [
          IconButton(
            tooltip: 'AI Call Center & Screener',
            icon: const Icon(Icons.phone_in_talk_rounded,
                color: AppColors.accentCyan, size: 21),
            onPressed: () => context.push('/calls'),
          ),
          IconButton(
            tooltip: 'Jack Multitasking Overlay',
            icon: const Icon(Icons.layers_rounded,
                color: Color(0xFFA855F7), size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(jackFloatingOverlayProvider.notifier).toggleExpanded();
            },
          ),
          IconButton(
            tooltip: 'Tasks & Notifications',
            icon: const Icon(Icons.notifications_rounded,
                color: Colors.white70, size: 22),
            onPressed: () => context.go('/tasks'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Radial glow background
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3),
                  radius: 1.1,
                  colors: [
                    Color(0xFF140C2C),
                    Color(0xFF07070A),
                    Color(0xFF04040A),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Greeting: Centered "Hello Jaswanth!"
                Text(
                  'Hello $displayName!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),

                const SizedBox(height: 10),

                // Headline: Centered "What do you want\nJack to do?"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'What do you want\nJack to do?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                // Center glowing Jack Orb (Tappable for voice activation)
                Expanded(
                  child: Center(
                    child: JackOrb(
                      size: orbSize,
                      state: orbState,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(jackWakeWordProvider.notifier).wakeUpManually();
                      },
                    ),
                  ),
                ),

                // ── WAKE WORD STATUS HUD CHIP ──
                Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(jackWakeWordProvider.notifier).toggleMonitoring();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 22.0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: wakeWordState.isWokenUp
                            ? const Color(0xFF28143C).withValues(alpha: 0.95)
                            : const Color(0xFF121024).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: wakeWordState.isWokenUp
                              ? AppColors.accentPink
                              : (wakeWordState.isEnabled
                                  ? AppColors.accentCyan.withValues(alpha: 0.45)
                                  : Colors.white12),
                          width: 1.2,
                        ),
                        boxShadow: [
                          if (wakeWordState.isWokenUp)
                            BoxShadow(
                              color: AppColors.accentPink.withValues(alpha: 0.35),
                              blurRadius: 14,
                            )
                          else if (wakeWordState.isEnabled)
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            wakeWordState.isWokenUp
                                ? Icons.graphic_eq_rounded
                                : (wakeWordState.isEnabled
                                    ? Icons.mic_rounded
                                    : Icons.mic_off_rounded),
                            color: wakeWordState.isWokenUp
                                ? AppColors.accentPink
                                : (wakeWordState.isEnabled
                                    ? AppColors.accentCyan
                                    : Colors.white38),
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wakeWordState.isWokenUp
                                ? "Jack Awake: Ask your task"
                                : (wakeWordState.isEnabled
                                    ? 'Wake Word: Say "Hey Jack" or "Jack"'
                                    : 'Wake Word: Paused (Tap to Enable)'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: wakeWordState.isWokenUp
                                  ? AppColors.accentPink.withValues(alpha: 0.25)
                                  : (wakeWordState.isEnabled
                                      ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                                      : Colors.white10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              wakeWordState.isWokenUp
                                  ? 'AWAKE'
                                  : (wakeWordState.isEnabled ? 'LISTENING' : 'OFF'),
                              style: GoogleFonts.inter(
                                color: wakeWordState.isWokenUp
                                    ? AppColors.accentPink
                                    : (wakeWordState.isEnabled
                                        ? const Color(0xFF22C55E)
                                        : Colors.white38),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Input bar: "Ask Jack anything..." with Search icon & White Mic Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.only(left: 18, right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141320).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Colors.white38,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: _submitQuery,
                                decoration: InputDecoration(
                                  hintText: wakeWordState.isAwaitingTask
                                      ? "Hi Sir, what's the task? Listening..."
                                      : (wakeWordState.isListening
                                          ? 'Listening to your voice...'
                                          : 'Ask Jack anything or say "Hey Jack"...'),
                                  hintStyle: GoogleFonts.inter(
                                    color: (wakeWordState.isAwaitingTask || wakeWordState.isListening)
                                        ? AppColors.accentPink
                                        : Colors.white38,
                                    fontSize: 14.5,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                cursorColor: AppColors.accentCyan,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                ref.read(jackWakeWordProvider.notifier).wakeUpManually();
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (wakeWordState.isWokenUp || wakeWordState.isListening)
                                      ? AppColors.accentPink
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  (wakeWordState.isWokenUp || wakeWordState.isListening)
                                      ? Icons.graphic_eq_rounded
                                      : Icons.mic_rounded,
                                  color: (wakeWordState.isWokenUp || wakeWordState.isListening)
                                      ? Colors.white
                                      : Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Action Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.bolt_rounded,
                            color: Color(0xFFF59E0B), size: 14),
                        backgroundColor: const Color(0xFF141226),
                        side: BorderSide(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        label: Text(
                          '⚡ Say "Hey Jack" or Tap',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 11.5),
                        ),
                        onPressed: () {
                          ref.read(jackWakeWordProvider.notifier).wakeUpManually();
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.phone_callback_rounded,
                            color: AppColors.accentCyan, size: 14),
                        backgroundColor: const Color(0xFF141226),
                        side: BorderSide(
                            color: AppColors.accentCyan.withValues(alpha: 0.3)),
                        label: Text(
                          'AI Call Screener',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 11.5),
                        ),
                        onPressed: () => context.push('/calls'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.shield_rounded,
                            color: Color(0xFF00FFCC), size: 14),
                        backgroundColor: const Color(0xFF141226),
                        side: BorderSide(
                            color: const Color(0xFF00FFCC).withValues(alpha: 0.3)),
                        label: Text(
                          '🛡️ Security Shield',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 11.5),
                        ),
                        onPressed: () => context.push('/security'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.smart_toy_rounded,
                            color: Color(0xFFA855F7), size: 14),
                        backgroundColor: const Color(0xFF141226),
                        side: BorderSide(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
                        label: Text(
                          'Agent Builder',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 11.5),
                        ),
                        onPressed: () => context.go('/agent-builder'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.flash_on_rounded,
                            color: Color(0xFF22C55E), size: 14),
                        backgroundColor: const Color(0xFF141226),
                        side: BorderSide(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                        label: Text(
                          'Flashlight',
                          style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 11.5),
                        ),
                        onPressed: () {
                          JackMasterDispatcher.executeCommand(
                              {'intent': 'toggle_flashlight', 'params': {'state': true}});
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: 0,
        onTap: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              // Already on home
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
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
