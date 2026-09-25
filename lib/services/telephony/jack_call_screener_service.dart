// lib/services/telephony/jack_call_screener_service.dart
//
// Autonomous AI Call Screening & Answering Engine for JACK Mobile Agent.
// Lifts incoming calls, speaks autonomously to the caller using FlutterTts,
// listens and transcribes caller speech with SpeechToText, reasons dynamically
// with Groq LLM, takes notes, logs a persistent task, and fires real notifications.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
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
import '../voice/jack_male_voice_helper.dart';
import '../../providers/call_log_provider.dart';
import '../../models/call_log_model.dart';
import '../security/jack_security_shield_service.dart';
import '../personality/jack_personality_service.dart';
import '../memory/jack_cognitive_memory.dart';

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
  static GlobalKey<NavigatorState>? navigatorKey;
  static WidgetRef? globalRef;

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _ttsInitialized = false;
  bool _sttInitialized = false;

  /// Trigger incoming call screening modal globally from any service or dispatcher
  static void triggerGlobally({
    String callerName = 'Sarah Jenkins',
    String phoneNumber = '+1 (415) 892-0199',
    String? scenarioPrompt,
    bool autoAnswer = true,
  }) {
    final ctx = navigatorKey?.currentContext;
    if (ctx != null && globalRef != null) {
      instance.triggerIncomingCall(
        ctx,
        globalRef!,
        callerName: callerName,
        phoneNumber: phoneNumber,
        scenarioPrompt: scenarioPrompt,
        autoAnswer: autoAnswer,
      );
    }
  }

  Future<void> _initAudio() async {
    if (!_ttsInitialized) {
      try {
        await _tts.setLanguage('en-GB');
        
        // Find a male voice
        final voices = await _tts.getVoices;
        if (voices != null) {
          for (var voice in voices) {
            final name = voice['name'].toString().toLowerCase();
            final locale = voice['locale'].toString();
            if (locale.contains('en-GB') && (name.contains('male') || name.contains('network'))) {
              await _tts.setVoice({"name": voice['name'], "locale": voice['locale']});
              break;
            }
          }
        }
        
        await _tts.setPitch(0.85);
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
    bool autoAnswer = true,
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
        autoAnswer: autoAnswer,
      ),
    );
  }

  /// Launch outgoing AI call screen modal
  void triggerOutgoingCall(
    BuildContext context,
    WidgetRef ref, {
    required String phoneNumber,
    String? contactName,
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
        callerName: contactName ?? phoneNumber,
        phoneNumber: phoneNumber,
        ref: ref,
        autoAnswer: true,
        isOutgoing: true,
      ),
    );
  }
}

class _JackCallScreeningModal extends StatefulWidget {
  final String callerName;
  final String phoneNumber;
  final String? scenarioPrompt;
  final WidgetRef ref;
  final bool autoAnswer;
  final bool isOutgoing;

  const _JackCallScreeningModal({
    required this.callerName,
    required this.phoneNumber,
    this.scenarioPrompt,
    required this.ref,
    this.autoAnswer = true,
    this.isOutgoing = false,
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
  Completer<String>? _turnCompleter;

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
    _initModalAudio();

    if (widget.autoAnswer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _jackAnswerCall();
        });
      });
    }
  }

  Future<void> _initModalAudio() async {
    try {
      await JackMaleVoiceHelper.configureMaleBaritoneVoice(_tts);
    } catch (_) {}
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

    // 1. Send speech to Android telephony in-call audio stream (USAGE_VOICE_COMMUNICATION)
    try {
      const MethodChannel('com.jack.agent/call_talk')
          .invokeMethod('speak', {'text': text, 'lang': 'en'});
    } catch (_) {}

    // 2. Play speech locally on speaker with active personality voice
    try {
      final personality = widget.ref.read(jackPersonalityProvider).activeProfile;
      await _tts.setPitch(personality.voicePitch);
      await _tts.setSpeechRate(personality.voiceRate);
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

    // Answer the physical call and enable speakerphone so speech is loud and clear
    try {
      const MethodChannel('com.jack.agent/accessibility')
          .invokeMethod('answerCall');
      const MethodChannel('com.jack.agent/accessibility')
          .invokeMethod('setSpeakerphone', {'enable': true});
    } catch (_) {}

    // 1. Jack greets the caller out loud over the call line
    await Future.delayed(const Duration(milliseconds: 600));
    final greeting = widget.isOutgoing
        ? "Hello! I am Jack, the AI assistant calling on behalf of the device owner. Am I speaking with ${widget.callerName}?"
        : (widget.callerName != 'Unknown' && widget.callerName.isNotEmpty
            ? "Hello ${widget.callerName}! I am Jack, the AI assistant. I am answering this call for the device owner. How may I assist you?"
            : "Hello! I am Jack, the AI assistant. I am taking this call for the device owner. Who is calling, and how may I assist you?");
    await _speakJack(greeting);

    if (!mounted) return;

    // 2. Real-time dynamic conversation loop with the live caller
    String callerMessage = '';
    String jackResponse = '';

    for (int turn = 0; turn < 2; turn++) {
      if (!mounted || _phase == CallScreeningPhase.completed) break;

      setState(() {
        _phase = CallScreeningPhase.callerSpeaking;
        _livePartialSpeech = 'Listening to caller...';
      });

      String currentTurnMessage = '';
      _turnCompleter = Completer<String>();

      // Live STT capture from the caller
      try {
        final hasSpeech = await _stt.initialize();
        if (hasSpeech) {
          await _stt.listen(
            onResult: (r) {
              if (mounted) {
                setState(() => _livePartialSpeech = r.recognizedWords);
              }
              if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
                if (_turnCompleter != null && !_turnCompleter!.isCompleted) {
                  _turnCompleter!.complete(r.recognizedWords.trim());
                }
              }
            },
          );

          currentTurnMessage = await _turnCompleter!.future.timeout(
            const Duration(seconds: 8),
            onTimeout: () => _livePartialSpeech != 'Listening to caller...' ? _livePartialSpeech : '',
          );
          await _stt.stop();
        }
      } catch (_) {}

      // If caller spoke, analyze security first, then reason with Groq LLM
      if (currentTurnMessage.trim().isNotEmpty) {
        callerMessage = currentTurnMessage.trim();
        if (!mounted) return;
        setState(() {
          _livePartialSpeech = '';
          _transcript.add(CallTranscriptTurn(
            speaker: widget.callerName != 'Unknown' ? widget.callerName : 'Caller',
            message: callerMessage,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();

        // 🛡️ Real Autonomous Security Shield Detection (OTP, IRS/Police Scam, Bank Fraud)
        final securityNotifier = widget.ref.read(jackSecurityProvider.notifier);
        final assessment = securityNotifier.analyzeCallTranscript(
          callerMessage,
          widget.phoneNumber,
        );

        if (assessment.isScam) {
          setState(() {
            _phase = CallScreeningPhase.reasoning;
            _transcript.add(CallTranscriptTurn(
              speaker: 'Jack Security Shield',
              message: '🚨 THREAT DEFLECTED: Scam Call Blocked (Score: ${assessment.threatScore}%)\nPatterns: ${assessment.detectedPatterns.join(', ')}',
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();

          jackResponse = assessment.deflectionScript;
          await _speakJack(jackResponse);
          break; // Stop and terminate call immediately
        }

        // Reason dynamically using Groq LLM with personality system prompt
        setState(() => _phase = CallScreeningPhase.reasoning);
        try {
          final groq = widget.ref.read(directGroqServiceProvider);
          final activePersonality = widget.ref.read(jackPersonalityProvider).activeProfile;
          final prompt =
              "${activePersonality.systemPrompt}\n"
              "You are on a live phone call with ${widget.callerName}. "
              "The caller just said: '$callerMessage'. "
              "Respond directly to the caller in 1-2 natural sentences according to your personality, confirming you noted it.";
          jackResponse = await groq.generate(prompt: prompt);
          jackResponse = jackResponse.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();
        } catch (_) {
          final activePersonality = widget.ref.read(jackPersonalityProvider).activeProfile;
          jackResponse = "${activePersonality.confirmPhrase} I have recorded your message and notified the team.";
        }

        if (jackResponse.isEmpty) {
          final activePersonality = widget.ref.read(jackPersonalityProvider).activeProfile;
          jackResponse = "${activePersonality.confirmPhrase} I have carefully noted your message and will pass it along immediately.";
        }

        // Speak response back to caller
        await _speakJack(jackResponse);


      } else {
        // If no speech detected on this turn
        if (turn == 0) {
          await _speakJack("I'm still here. Could you please repeat your name and message?");
        } else {
          await _speakJack("I am not hearing any response, so I will conclude this call. Goodbye!");
          break;
        }
      }
    }

    if (!mounted) return;

    // Wrap up call politely
    if (_phase != CallScreeningPhase.completed) {
      await _speakJack("Have a great day. Goodbye!");
    }

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

    // Record in CallLogProvider
    try {
      widget.ref.read(callLogProvider.notifier).addEntry(CallLogEntry(
        id: 'call_${DateTime.now().millisecondsSinceEpoch}',
        contactName: widget.callerName,
        phoneNumber: widget.phoneNumber,
        type: CallLogType.incoming,
        startTime: DateTime.now().subtract(Duration(seconds: _callSeconds)),
        duration: Duration(seconds: _callSeconds),
        aiSummary: callerMessage.isNotEmpty
            ? 'Caller: "$callerMessage"\nJack: "$jackResponse"'
            : 'Call screened autonomously by Jack AI.',
        jackActions: [
          'Screened call autonomously via British Male AI voice',
          if (callerMessage.isNotEmpty) 'Captured caller message & intent',
          'Logged to persistent system tasks',
        ],
      ));
    } catch (_) {}

    // Persist call history to SQLite Cognitive Memory
    try {
      await JackCognitiveMemory().logCallMemory(
        callerNumber: widget.phoneNumber,
        callerName: widget.callerName,
        callType: widget.isOutgoing ? 'outgoing' : 'incoming',
        summary: callerMessage.isNotEmpty
            ? 'Caller: "$callerMessage" | Jack: "$jackResponse"'
            : 'Call handled autonomously by Jack AI.',
        transcription: _transcript.map((t) => "${t.speaker}: ${t.message}").join(' | '),
      );
    } catch (_) {}

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
            if (_phase == CallScreeningPhase.callerSpeaking)
              _buildLiveMicIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveMicIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF100E20),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _livePartialSpeech.isNotEmpty
                  ? 'Transcribing: "$_livePartialSpeech"'
                  : 'Live Caller Audio Stream Active • Listening...',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.mic_rounded, color: Color(0xFF22C55E), size: 18),
        ],
      ),
    );
  }
}
