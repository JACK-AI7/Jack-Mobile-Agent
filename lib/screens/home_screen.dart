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

  Future<void> _submitQuery(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    _searchFocus.unfocus();
    _searchController.clear();
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }

    HapticFeedback.lightImpact();

    // 1. Check Hardware / Deterministic Reflex Action (<100ms)
    final reflexResult = await JackMasterDispatcher.tryReflexFastPath(query);
    if (reflexResult != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reflexResult['message']?.toString() ?? 'Action executed on device',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 2. Check App Launch Intent
    final lower = query.toLowerCase();
    if (lower.startsWith('open ') || lower.startsWith('launch ')) {
      final appName = lower.replaceFirst('open ', '').replaceFirst('launch ', '').trim();
      final opened = await AppLauncherHelper.launchAppByName(appName);
      if (opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $appName on your device...'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // 3. Navigate to Chat for Deep AI Reasoning & Product Results
    if (!mounted) return;
    context.push('/chat', extra: query);
  }

  @override
  void dispose() {
    if (_isListening) _speechToText.stop();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final realtimeState = ref.watch(agentExecutionProvider);
    final orbState = _isListening
        ? OrbState.listening
        : (realtimeState.orbState == JackOrbState.THINKING
            ? OrbState.thinking
            : OrbState.idle);

    final userNameAsync = ref.watch(userNameProvider);
    final displayName = userNameAsync.when(
      data: (name) => (name != null && name.trim().isNotEmpty) ? name.trim() : 'User',
      loading: () => '...',
      error: (err, stack) => 'User',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white70, size: 24),
          onPressed: () => JackPermissionService.showPermissionSheet(context),
        ),
        centerTitle: true,
        title: Text(
          'JACK AGENT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: Colors.white70,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
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
                  center: Alignment(0.0, -0.4),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Greeting: Real user name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  child: Text(
                    'Hello $displayName!',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Headline: "What do you want\nJack to do?"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  child: Text(
                    'What do you want\nJack to do?',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                      height: 1.12,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // Center glowing Jack Orb (Tappable for voice activation)
                Expanded(
                  child: Center(
                    child: JackOrb(
                      size: 280,
                      state: orbState,
                      onTap: _toggleVoiceListening,
                    ),
                  ),
                ),

                // Input bar: "Ask Jack anything..." with Search icon & White Mic Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.only(left: 18, right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151522).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(32),
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
                                width: 46,
                                height: 46,
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
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
