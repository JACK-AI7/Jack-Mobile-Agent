// lib/services/voice/jack_voice_service.dart
//
// Real-time Voice Duplex & Male British JARVIS Voice Engine for JACK.
// Configures British English (en-GB) male baritone cadence (pitch 0.90, rate 0.48),
// discovers system male voices, supports continuous listening with SpeechToText,
// drives audio-reactive waveform metrics, and synthesizes JARVIS responses.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class JackVoiceState {
  final bool isListening;
  final bool isSpeaking;
  final String activeTranscript;
  final double audioLevel; // 0.0 to 1.0 for visual waveform glow
  final String voiceName;
  final bool isInitialized;

  const JackVoiceState({
    required this.isListening,
    required this.isSpeaking,
    required this.activeTranscript,
    required this.audioLevel,
    required this.voiceName,
    required this.isInitialized,
  });

  JackVoiceState copyWith({
    bool? isListening,
    bool? isSpeaking,
    String? activeTranscript,
    double? audioLevel,
    String? voiceName,
    bool? isInitialized,
  }) {
    return JackVoiceState(
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      activeTranscript: activeTranscript ?? this.activeTranscript,
      audioLevel: audioLevel ?? this.audioLevel,
      voiceName: voiceName ?? this.voiceName,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class JackVoiceNotifier extends StateNotifier<JackVoiceState> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  Timer? _waveformTimer;

  JackVoiceNotifier()
      : super(const JackVoiceState(
          isListening: false,
          isSpeaking: false,
          activeTranscript: '',
          audioLevel: 0.15,
          voiceName: 'JARVIS (British Male)',
          isInitialized: false,
        )) {
    _initEngine();
  }

  static const String jarvisSystemPrompt =
      "You are Jack, a sophisticated British AI personal assistant modeled after JARVIS. "
      "You serve your principal Easin (addressed respectfully as 'Sir' or 'Mr. Easin'). "
      "Your tone is cultured, razor-sharp, calm, and exquisitely articulate. "
      "Deliver answers concisely (1-2 sentences for verbal answers) without preamble or fluff.";

  Future<void> _initEngine() async {
    try {
      await _setupTtsJarvisVoice();
      final hasStt = await _stt.initialize(
        onError: (err) {
          state = state.copyWith(isListening: false);
          _waveformTimer?.cancel();
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            state = state.copyWith(isListening: false);
            _waveformTimer?.cancel();
          }
        },
      );

      state = state.copyWith(isInitialized: hasStt);
    } catch (e) {
      debugPrint('Voice engine initialization warning: $e');
    }
  }

  /// Sets up British English (en-GB) male JARVIS voice profile
  Future<void> _setupTtsJarvisVoice() async {
    try {
      await _tts.setLanguage('en-GB');

      // Male baritone JARVIS tuning:
      // Pitch: 0.88 - 0.92 gives that distinguished deep British resonance
      // Speech Rate: 0.48 provides calm, measured, articulate pacing
      await _tts.setPitch(0.90);
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);

      // Search available system voices for male British / UK voice
      final List<dynamic>? voices = await _tts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        Map<dynamic, dynamic>? chosenVoice;

        for (final v in voices) {
          if (v is Map) {
            final name = (v['name'] ?? '').toString().toLowerCase();
            final locale = (v['locale'] ?? '').toString().toLowerCase();

            // Match British male candidates: e.g. en-gb-x-rjs-local, en-gb-x-gbc-local, en_GB male
            if ((locale.contains('en-gb') || locale.contains('en_gb') || locale.contains('gbr')) &&
                (name.contains('male') || name.contains('rjs') || name.contains('gbb') || name.contains('george') || name.contains('oliver'))) {
              chosenVoice = v;
              break;
            }
          }
        }

        // Fallback to any en-GB voice if specific male tag not found
        if (chosenVoice == null) {
          for (final v in voices) {
            if (v is Map) {
              final locale = (v['locale'] ?? '').toString().toLowerCase();
              if (locale.contains('en-gb') || locale.contains('en_gb')) {
                chosenVoice = v;
                break;
              }
            }
          }
        }

        if (chosenVoice != null) {
          await _tts.setVoice({
            'name': chosenVoice['name'].toString(),
            'locale': chosenVoice['locale'].toString(),
          });
          state = state.copyWith(voiceName: 'JARVIS (${chosenVoice['name']})');
        }
      }

      _tts.setStartHandler(() {
        state = state.copyWith(isSpeaking: true);
        _startWaveformDance();
      });

      _tts.setCompletionHandler(() {
        state = state.copyWith(isSpeaking: false, audioLevel: 0.1);
        _waveformTimer?.cancel();
      });

      _tts.setErrorHandler((_) {
        state = state.copyWith(isSpeaking: false, audioLevel: 0.1);
        _waveformTimer?.cancel();
      });
    } catch (e) {
      debugPrint('Error configuring JARVIS TTS voice: $e');
    }
  }

  void _startWaveformDance() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!state.isSpeaking && !state.isListening) {
        t.cancel();
        return;
      }
      final simLevel = (0.35 + (DateTime.now().millisecond % 65) / 100.0);
      state = state.copyWith(audioLevel: simLevel);
    });
  }

  /// Speaks out text with the male JARVIS voice
  Future<void> speakJarvis(String text) async {
    if (text.trim().isEmpty) return;

    // Clean markdown, links, and thinking tags
    var clean = text
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        .replaceAll(RegExp(r'[*_#`~\[\]]'), '')
        .trim();

    if (clean.isEmpty) return;

    try {
      await _tts.stop();
      await _tts.speak(clean);
    } catch (_) {}
  }

  /// Stops any ongoing speech immediately
  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
    _waveformTimer?.cancel();
  }

  /// Continuous duplex listening
  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
  }) async {
    HapticFeedback.mediumImpact();

    final micPerm = await Permission.microphone.request();
    if (!micPerm.isGranted) return;

    if (!state.isInitialized) {
      await _initEngine();
    }

    state = state.copyWith(isListening: true, activeTranscript: '');
    _startWaveformDance();

    try {
      await _stt.listen(
        onResult: (result) {
          state = state.copyWith(activeTranscript: result.recognizedWords);
          onResult(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_GB', // British locale for recognition alignment
      );
    } catch (_) {
      state = state.copyWith(isListening: false);
    }
  }

  Future<void> stopListening() async {
    await _stt.stop();
    state = state.copyWith(isListening: false);
    _waveformTimer?.cancel();
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}

final jackVoiceProvider =
    StateNotifierProvider<JackVoiceNotifier, JackVoiceState>((ref) {
  return JackVoiceNotifier();
});
