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
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../models/realtime/jack_orb_state.dart';
import '../services/jack_auth_state.dart';
import '../services/realtime/agent_execution_controller.dart';
import '../services/jack_master_dispatcher.dart';
import '../services/app_launcher_helper.dart';
import '../services/jack_permission_service.dart';
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

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechInitialized = false;
    }
  }

  Future<void> _toggleVoiceListening() async {
    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required for voice listening.'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!_speechInitialized) {
      await _initSpeech();
    }

    if (_speechInitialized) {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _searchController.text = result.recognizedWords;
            });
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              _submitQuery(result.recognizedWords.trim());
            }
          }
        },
      );
    }
  }

  void _submitQuery(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    _searchFocus.unfocus();
    _searchController.clear();
    HapticFeedback.lightImpact();

    final reflex = await JackMasterDispatcher.tryReflexFastPath(query);
    if (reflex != null) {
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
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final realtimeState = ref.watch(agentExecutionProvider);
    final orbState = _isListening
        ? OrbState.listening
        : (realtimeState.orbState == JackOrbState.THINKING ||
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
      data: (name) => (name != null && name.trim().isNotEmpty) ? name.trim() : 'Easin',
      loading: () => 'Easin',
      error: (err, stack) => 'Easin',
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
            icon: const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 22),
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

                // Greeting: Centered "Hello Easin!"
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
                      onTap: _toggleVoiceListening,
                    ),
                  ),
                ),

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
                                  hintText: _isListening
                                      ? 'Listening to your voice...'
                                      : 'Ask Jack anything...',
                                  hintStyle: GoogleFonts.inter(
                                    color: _isListening
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
                              onTap: _toggleVoiceListening,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening
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
                                  _isListening
                                      ? Icons.graphic_eq_rounded
                                      : Icons.mic_rounded,
                                  color: _isListening ? Colors.white : Colors.black,
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

                const SizedBox(height: 18),
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
