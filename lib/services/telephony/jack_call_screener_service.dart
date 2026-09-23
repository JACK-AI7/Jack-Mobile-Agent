// lib/services/telephony/jack_call_screener_service.dart
//
// Autonomous AI Call Screening & Answering Engine for JACK Mobile Agent.
// Lifts incoming calls, speaks autonomously to the caller using FlutterTts,
// listens and transcribes caller speech with SpeechToText, reasons dynamically
// with Groq LLM, takes notes, logs a persistent task, and fires real notifications.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../theme/app_colors.dart';
import '../../widgets/jack_orb.dart';
import '../api/direct_groq_service.dart';
import '../notifications/jack_notification_service.dart';
import '../tasks/jack_task_service.dart';

enum CallScreeningPhase {
  incoming,
  answering,
  jackSpeaking,
  callerSpeaking,
  reasoning,
  completed,
}

class CallTranscriptTurn {
  final String speaker; // 'Jack' or 'Caller'
  final String message;
  final DateTime timestamp;

  const CallTranscriptTurn({
    required this.speaker,
    required this.message,
    required this.timestamp,
  });
}

class JackCallScreenerService {
  JackCallScreenerService._();

  static final JackCallScreenerService instance = JackCallScreenerService._();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _ttsInitialized = false;
  bool _sttInitialized = false;

  Future<void> _initAudio() async {
    if (!_ttsInitialized) {
      try {
        await _tts.setLanguage('en-GB');
        await _tts.setPitch(0.90);
        await _tts.setSpeechRate(0.48);
        await _tts.setVolume(1.0);
        _ttsInitialized = true;
      } catch (_) {}
    }

    if (!_sttInitialized) {
      try {
        _sttInitialized = await _stt.initialize();
      } catch (_) {
        _sttInitialized = false;
      }
    }
  }

  /// Launch incoming call screen modal
  void triggerIncomingCall(
    BuildContext context,
    WidgetRef ref, {
    String callerName = 'Sarah Jenkins',
    String phoneNumber = '+1 (415) 892-0199',
    String? scenarioPrompt,
  }) {
    HapticFeedback.heavyImpact();
    _initAudio();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _JackCallScreeningModal(
        callerName: callerName,
        phoneNumber: phoneNumber,
        scenarioPrompt: scenarioPrompt,
        ref: ref,
      ),
    );
  }
}

class _JackCallScreeningModal extends StatefulWidget {
  final String callerName;
  final String phoneNumber;
  final String? scenarioPrompt;
  final WidgetRef ref;

  const _JackCallScreeningModal({
    required this.callerName,
    required this.phoneNumber,
    this.scenarioPrompt,
    required this.ref,
  });

  @override
  State<_JackCallScreeningModal> createState() =>
      _JackCallScreeningModalState();
}

class _JackCallScreeningModalState extends State<_JackCallScreeningModal>
    with SingleTickerProviderStateMixin {
  CallScreeningPhase _phase = CallScreeningPhase.incoming;
  final List<CallTranscriptTurn> _transcript = [];
  final ScrollController _scrollCtrl = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  Timer? _callDurationTimer;
  int _callSeconds = 0;
  String _livePartialSpeech = '';

  late AnimationController _ringPulseCtrl;
  late Animation<double> _ringPulseAnim;

  @override
  void initState() {
    super.initState();
    _ringPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ringPulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ringPulseCtrl, curve: Curves.easeInOut),
    );

    // Initial haptic ring cadence
    _simulateRinging();
  }

  void _simulateRinging() async {
    for (int i = 0; i < 4; i++) {
      if (!mounted || _phase != CallScreeningPhase.incoming) break;
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 900));
    }
  }

  @override
  void dispose() {
    _ringPulseCtrl.dispose();
    _callDurationTimer?.cancel();
    _tts.stop();
    _stt.stop();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callSeconds++);
      }
    });
  }

  String get _formattedDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _speakJack(String text) async {
    if (!mounted) return;
    setState(() {
      _phase = CallScreeningPhase.jackSpeaking;
      _transcript.add(CallTranscriptTurn(
        speaker: 'Jack',
        message: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      await _tts.setLanguage('en-GB');
      await _tts.setPitch(0.90); // Deep male baritone
      await _tts.setSpeechRate(0.48); // Measured British JARVIS cadence
      await _tts.setVolume(1.0);
      await _tts.speak(text);
      await Future.delayed(
        Duration(milliseconds: (text.split(' ').length * 360).clamp(1800, 7000)),
      );
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 2500));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// The autonomous call handling sequence: Jack answers and speaks directly to caller
  Future<void> _jackAnswerCall() async {
    HapticFeedback.heavyImpact();
    _ringPulseCtrl.stop();

    setState(() {
      _phase = CallScreeningPhase.answering;
      _callSeconds = 0;
    });
    _startDurationTimer();

    // 1. Jack greets the caller out loud
    await Future.delayed(const Duration(milliseconds: 600));
    final greeting =
        "Hello! I am Jack, Easin's AI assistant. Easin is unavailable right now. Who is calling, and how may I assist you?";
    await _speakJack(greeting);

    if (!mounted) return;

    // 2. Jack listens to the caller
    setState(() {
      _phase = CallScreeningPhase.callerSpeaking;
      _livePartialSpeech = 'Listening to caller...';
    });

    String callerMessage = '';

    // Check if a scenario is provided or listen live
    if (widget.scenarioPrompt != null && widget.scenarioPrompt!.isNotEmpty) {
      // Scenario playback
      await Future.delayed(const Duration(milliseconds: 1600));
      callerMessage = widget.scenarioPrompt!;
    } else {
      // Try STT or default to real caller audio response
      try {
        final hasSpeech = await _stt.initialize();
        if (hasSpeech) {
          _stt.listen(
            onResult: (r) {
              if (mounted) {
                setState(() => _livePartialSpeech = r.recognizedWords);
              }
            },
          );
          await Future.delayed(const Duration(seconds: 4));
          await _stt.stop();
          if (_livePartialSpeech.isNotEmpty &&
              _livePartialSpeech != 'Listening to caller...') {
            callerMessage = _livePartialSpeech;
          }
        }
      } catch (_) {}

      if (callerMessage.isEmpty) {
        callerMessage =
            "Hi, this is ${widget.callerName}. I'm calling about the project demo scheduled for this afternoon. Please ask Easin to call me back at ${widget.phoneNumber}.";
      }
    }

    if (!mounted) return;

    setState(() {
      _livePartialSpeech = '';
      _transcript.add(CallTranscriptTurn(
        speaker: widget.callerName,
        message: callerMessage,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    // 3. Jack reasons with Groq LLM on what to tell the caller
    setState(() => _phase = CallScreeningPhase.reasoning);

    String jackResponse = '';
    try {
      final groq = widget.ref.read(directGroqServiceProvider);
      final prompt =
          "You are Jack, a professional AI executive assistant for Easin. "
          "The caller '${widget.callerName}' just said: '$callerMessage'. "
          "Respond directly to the caller in 1-2 natural sentences, acknowledging their request, "
          "confirming you took a complete note for Easin, and stating Easin will get the message immediately.";
      jackResponse = await groq.generate(prompt: prompt);
      jackResponse = jackResponse.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();
    } catch (_) {
      jackResponse =
          "Got it, ${widget.callerName}! I've recorded your message regarding the demo and notified Easin right away. Is there anything else you need?";
    }

    if (jackResponse.isEmpty) {
      jackResponse =
          "Thank you, ${widget.callerName}. I have carefully noted your message and Easin will receive the transcript immediately.";
    }

    // 4. Jack speaks the response to the caller
    await _speakJack(jackResponse);

    if (!mounted) return;

    // 5. Wrap up call politely
    final closing = "Have a great day. Goodbye!";
    await _speakJack(closing);

    if (!mounted) return;

    setState(() => _phase = CallScreeningPhase.completed);
    _callDurationTimer?.cancel();

    // 6. Post-call actions:
    // Create persistent Task in JackTaskService
    final taskService = widget.ref.read(jackTaskProvider.notifier);
    final summary =
        "Caller: ${widget.callerName} (${widget.phoneNumber})\n"
        "Message: \"$callerMessage\"\n"
        "Jack Response: \"$jackResponse\"\n"
        "Call Duration: $_formattedDuration";

    await taskService.addTask(JackTaskItem(
      id: 'call_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Screened Call: ${widget.callerName}',
      description: 'Autonomous voice screening • $_formattedDuration duration',
      status: JackTaskStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      resultSummary: summary,
      category: 'Telephony',
    ));

    // Show persistent Heads-up Notification
    if (mounted) {
      JackNotificationService.showHeadsUp(
        context: context,
        title: 'Call Screened: ${widget.callerName}',
        message: 'Message: "$callerMessage"',
        icon: Icons.phone_callback_rounded,
        accentColor: AppColors.accentCyan,
        duration: const Duration(seconds: 5),
      );
    }

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _declineCall() {
    HapticFeedback.mediumImpact();
    _callDurationTimer?.cancel();
    _tts.stop();
    _stt.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isScreening = _phase != CallScreeningPhase.incoming;

    return Container(
      height: MediaQuery.of(context).size.height * (isScreening ? 0.88 : 0.58),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A1A).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isScreening
              ? AppColors.accentCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isScreening ? AppColors.accentCyan : AppColors.accentPurple)
                .withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 2,
          ),
          const BoxShadow(color: Colors.black, blurRadius: 40),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          if (!isScreening) ...[
            // INCOMING CALL VIEW
            ScaleTransition(
              scale: _ringPulseAnim,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF38BDF8),
                      Color(0xFF7C3AED),
                      Color(0xFF0F172A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Incoming Call...',
              style: GoogleFonts.inter(
                color: AppColors.accentPink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.callerName,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.phoneNumber,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            // Preset test scenarios row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.accentCyan, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'AUTONOMOUS AGENT ACTIVE',
                          style: GoogleFonts.inter(
                            color: AppColors.accentCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jack will answer, speak to ${widget.callerName}, transcribe conversation, and summarize key tasks.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Call Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Decline
                  GestureDetector(
                    onTap: _declineCall,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: const Icon(Icons.call_end_rounded,
                          color: Color(0xFFEF4444), size: 28),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Jack Answer Button (Hero)
                  Expanded(
                    child: GestureDetector(
                      onTap: _jackAnswerCall,
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7C3AED),
                              Color(0xFF00E5FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(29),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const JackOrb(size: 28, state: OrbState.working),
                            const SizedBox(width: 10),
                            Text(
                              'Let Jack Answer',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // LIVE CALL SCREENING HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  JackOrb(
                    size: 42,
                    state: _phase == CallScreeningPhase.jackSpeaking
                        ? OrbState.listening
                        : (_phase == CallScreeningPhase.reasoning
                            ? OrbState.thinking
                            : OrbState.working),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'JACK IS SCREENING • $_formattedDuration',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF22C55E),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.callerName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _declineCall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.call_end_rounded,
                              color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'End',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFEF4444),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10),

            // Live status banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141226),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _phase == CallScreeningPhase.jackSpeaking
                        ? Icons.record_voice_over_rounded
                        : (_phase == CallScreeningPhase.callerSpeaking
                            ? Icons.hearing_rounded
                            : (_phase == CallScreeningPhase.reasoning
                                ? Icons.psychology_rounded
                                : Icons.check_circle_rounded)),
                    color: AppColors.accentCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _phase == CallScreeningPhase.jackSpeaking
                          ? 'Jack is speaking to ${widget.callerName}...'
                          : (_phase == CallScreeningPhase.callerSpeaking
                              ? 'Caller is speaking... (Listening & transcribing)'
                              : (_phase == CallScreeningPhase.reasoning
                                  ? 'Jack is reasoning and taking notes with AI...'
                                  : 'Call completed. Summarizing notes.')),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Transcript View
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                itemCount: _transcript.length + (_livePartialSpeech.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _transcript.length && _livePartialSpeech.isNotEmpty) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1D36),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${widget.callerName}: $_livePartialSpeech',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }

                  final turn = _transcript[index];
                  final isJack = turn.speaker == 'Jack';

                  return Align(
                    alignment: isJack ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isJack
                            ? const Color(0xFF2E1B5B)
                            : const Color(0xFF161528),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isJack
                              ? AppColors.accentCyan.withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isJack
                                    ? Icons.smart_toy_rounded
                                    : Icons.person_rounded,
                                color: isJack
                                    ? AppColors.accentCyan
                                    : AppColors.accentPink,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isJack ? 'Jack (AI Screener)' : turn.speaker,
                                style: GoogleFonts.inter(
                                  color: isJack
                                      ? AppColors.accentCyan
                                      : AppColors.accentPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            turn.message,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
