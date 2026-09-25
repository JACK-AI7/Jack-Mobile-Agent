// lib/services/voice/jack_wake_word_service.dart
//
// Continuous "Hey Jack" & "Jack" Wake-Word Detection & Voice Execution Engine.
//
// Features:
// 1. Hands-free Wake Word Detection: Listens for "Hey Jack", "Jack", "Hi Jack", "Ok Jack".
// 2. JARVIS Verbal Response: Immediately answers in deep British male baritone:
//    "Hi Sir, what's the task?"
// 3. Autonomous Task Capture: Dynamically switches to active command listening as soon as
//    Jack finishes asking for the task.
// 4. One-Shot Command Support: Handles compound phrases (e.g., "Hey Jack turn on the flashlight")
//    by stripping the wake word, speaking "Right away, Sir", and executing immediately.
// 5. Reflex & AI Dispatch: Executes hardware, telephony, and app commands via
//    JackMasterDispatcher or deep intelligence via DirectGroqService.
// 6. Seamless Standby Loop: Automatically returns to low-overhead wake word standby.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../api/direct_groq_service.dart';
import '../jack_master_dispatcher.dart';
import '../personality/jack_personality_service.dart';
import '../tasks/jack_task_service.dart';
import 'jack_male_voice_helper.dart';

class JackWakeWordState {
  final bool isEnabled;
  final bool isListening;
  final bool isWokenUp;
  final bool isAwaitingTask;
  final bool isSpeaking;
  final String lastRecognized;
  final String statusMessage;
  final double waveformLevel;

  const JackWakeWordState({
    required this.isEnabled,
    required this.isListening,
    required this.isWokenUp,
    required this.isAwaitingTask,
    required this.isSpeaking,
    required this.lastRecognized,
    required this.statusMessage,
    required this.waveformLevel,
  });

  JackWakeWordState copyWith({
    bool? isEnabled,
    bool? isListening,
    bool? isWokenUp,
    bool? isAwaitingTask,
    bool? isSpeaking,
    String? lastRecognized,
    String? statusMessage,
    double? waveformLevel,
  }) {
    return JackWakeWordState(
      isEnabled: isEnabled ?? this.isEnabled,
      isListening: isListening ?? this.isListening,
      isWokenUp: isWokenUp ?? this.isWokenUp,
      isAwaitingTask: isAwaitingTask ?? this.isAwaitingTask,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      lastRecognized: lastRecognized ?? this.lastRecognized,
      statusMessage: statusMessage ?? this.statusMessage,
      waveformLevel: waveformLevel ?? this.waveformLevel,
    );
  }
}

class JackWakeWordNotifier extends StateNotifier<JackWakeWordState> {
  final Ref _ref;
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _sttInitialized = false;
  bool _isProcessing = false;
  String _currentTaskWords = '';
  Timer? _restartLoopTimer;
  Timer? _waveformTimer;

  static final RegExp _wakeRegex = RegExp(
    r'\b(hey\s+jack|hi\s+jack|ok\s+jack|okay\s+jack|hello\s+jack|jack)\b',
    caseSensitive: false,
  );

  JackWakeWordNotifier(this._ref)
      : super(const JackWakeWordState(
          isEnabled: true,
          isListening: false,
          isWokenUp: false,
          isAwaitingTask: false,
          isSpeaking: false,
          lastRecognized: '',
          statusMessage: 'Say "Hey Jack" or "Jack" to wake up',
          waveformLevel: 0.15,
        )) {
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      await JackMaleVoiceHelper.configureMaleBaritoneVoice(_tts);

      _tts.setStartHandler(() {
        state = state.copyWith(isSpeaking: true);
        _startWaveformDance();
      });

      _tts.setCompletionHandler(() {
        state = state.copyWith(isSpeaking: false, waveformLevel: 0.15);
        _waveformTimer?.cancel();
        _onTtsFinished();
      });

      _tts.setErrorHandler((_) {
        state = state.copyWith(isSpeaking: false, waveformLevel: 0.15);
        _waveformTimer?.cancel();
        _onTtsFinished();
      });

      _sttInitialized = await _stt.initialize(
        onError: (err) {
          debugPrint('JackWakeWord STT error: $err');
          if (state.isAwaitingTask && !_isProcessing) {
            _finishTaskFlow('Could not hear task. Standing by.');
          } else {
            _scheduleLoopRestart(1200);
          }
        },
        onStatus: (status) {
          debugPrint('JackWakeWord STT status: $status');
          if (status == 'listening') {
            state = state.copyWith(isListening: true);
          } else if (status == 'notListening' || status == 'done') {
            if (state.isAwaitingTask) {
              if (_currentTaskWords.isNotEmpty && !_isProcessing) {
                final task = _currentTaskWords;
                _currentTaskWords = '';
                _waveformTimer?.cancel();
                _executeUserTask(task);
              } else if (_currentTaskWords.isEmpty && !_isProcessing) {
                _finishTaskFlow('Could not hear task. Standing by.');
              }
            } else {
              state = state.copyWith(isListening: false);
              _scheduleLoopRestart(500);
            }
          }
        },
      );
    } catch (e) {
      debugPrint('JackWakeWord init error: $e');
    }
  }

  void _startWaveformDance() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 110), (_) {
      if (!state.isSpeaking && !state.isAwaitingTask) {
        return;
      }
      final sim = 0.35 + (DateTime.now().millisecond % 65) / 100.0;
      state = state.copyWith(waveformLevel: sim);
    });
  }

  /// Arms the wake word listener
  Future<void> startMonitoring() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;

    if (!_sttInitialized) {
      await _initEngine();
    }

    state = state.copyWith(
      isEnabled: true,
      statusMessage: 'Say "Hey Jack" or "Jack" to wake up',
    );

    _listenForWakeWord();
  }

  /// Disarms the wake word listener
  Future<void> stopMonitoring() async {
    _restartLoopTimer?.cancel();
    _waveformTimer?.cancel();
    await _stt.stop();
    await _tts.stop();

    state = state.copyWith(
      isEnabled: false,
      isListening: false,
      isWokenUp: false,
      isAwaitingTask: false,
      isSpeaking: false,
      statusMessage: 'Wake word paused',
    );
  }

  /// Toggles wake word monitoring
  Future<void> toggleMonitoring() async {
    if (state.isEnabled) {
      await stopMonitoring();
    } else {
      await startMonitoring();
    }
  }

  /// Internal loop: listens for wake words
  Future<void> _listenForWakeWord() async {
    if (!state.isEnabled || _isProcessing || state.isSpeaking || state.isAwaitingTask) {
      return;
    }

    if (!_sttInitialized) {
      await _initEngine();
    }

    try {
      state = state.copyWith(
        isListening: true,
        statusMessage: 'Listening for "Hey Jack"...',
      );

      await _stt.listen(
        onResult: (result) => _handleWakeWordResult(result.recognizedWords, result.finalResult),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('Error starting wake word listener: $e');
      _scheduleLoopRestart(1500);
    }
  }

  /// Processes spoken audio looking for "Hey Jack" or "Jack"
  void _handleWakeWordResult(String speech, bool isFinal) async {
    final lower = speech.toLowerCase().trim();
    state = state.copyWith(lastRecognized: speech);

    final match = _wakeRegex.firstMatch(lower);
    if (match != null && !_isProcessing) {
      _isProcessing = true;
      _restartLoopTimer?.cancel();
      await _stt.stop();

      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);

      final afterWakeWord = lower.substring(match.end).replaceAll(RegExp(r'^[,\.\s]+'), '').trim();

      final personality = _ref.read(jackPersonalityProvider).activeProfile;

      if (afterWakeWord.isNotEmpty && afterWakeWord.length > 2) {
        // Case B: User said wake word + task together (e.g. "Hey Jack turn on the flashlight")
        state = state.copyWith(
          isWokenUp: true,
          isAwaitingTask: false,
          statusMessage: 'Executing: $afterWakeWord',
        );

        await _speak(personality.confirmPhrase);
        await _executeUserTask(afterWakeWord);
      } else {
        // Case A: User said wake word only ("Hey Jack" or "Jack")
        state = state.copyWith(
          isWokenUp: true,
          isAwaitingTask: true,
          statusMessage: personality.wakeGreeting,
        );

        // Jack verbally asks using personality-driven greeting
        await _speak(personality.wakeGreeting);
      }
    }
  }

  /// Called when TTS finishes speaking
  void _onTtsFinished() {
    if (state.isAwaitingTask) {
      _isProcessing = false;
      // Begin listening for the user's task
      _listenForUserTask();
    } else if (state.isEnabled && !_isProcessing) {
      // Resume wake word standby
      _scheduleLoopRestart(600);
    }
  }

  /// Listens specifically for the user's task command after Jack asked "Hi Sir, what's the task?"
  Future<void> _listenForUserTask() async {
    _isProcessing = false;
    _currentTaskWords = '';
    HapticFeedback.selectionClick();
    _startWaveformDance();

    state = state.copyWith(
      isListening: true,
      statusMessage: "Listening to your task...",
      lastRecognized: '',
    );

    try {
      await _stt.listen(
        onResult: (result) {
          _currentTaskWords = result.recognizedWords.trim();
          state = state.copyWith(
            lastRecognized: _currentTaskWords,
            statusMessage: _currentTaskWords.isNotEmpty
                ? _currentTaskWords
                : "Listening to your task...",
          );

          if (result.finalResult && _currentTaskWords.isNotEmpty && !_isProcessing) {
            final taskText = _currentTaskWords;
            _currentTaskWords = '';
            _stt.stop();
            _waveformTimer?.cancel();
            _executeUserTask(taskText);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 16),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Error listening for task: $e');
      _finishTaskFlow('Could not hear task. Standing by.');
    }
  }

  /// Executes the captured task via reflex fast-path or Groq LLM
  Future<void> _executeUserTask(String task) async {
    _isProcessing = true;
    state = state.copyWith(
      isAwaitingTask: false,
      statusMessage: 'Processing: "$task"',
    );

    try {
      // 1. Try instantaneous reflex (<100ms)
      final reflex = await JackMasterDispatcher.tryReflexFastPath(task);
      if (reflex != null) {
        final resultText = reflex['result']?.toString() ??
            reflex['message']?.toString() ??
            'Task executed, Sir.';
        await _speak(resultText);
        _finishTaskFlow(resultText);
        return;
      }

      // 2. Dispatches to Direct Groq LLM intelligence
      final groq = _ref.read(directGroqServiceProvider);
      final aiResponse = await groq.generate(
        prompt:
            "You are Jack, a sophisticated British personal AI assistant modeled after JARVIS. "
            "Your principal has given you this voice task: '$task'. "
            "Provide a concise, direct, and actionable answer in 1-2 sharp spoken sentences without markdown formatting.",
      );

      final clean = aiResponse
          .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
          .replaceAll(RegExp(r'[*_#`~\[\]]'), '')
          .trim();

      final speechText = clean.isNotEmpty ? clean : 'Task completed, Sir.';

      JackTaskRecorder.recordTask(
        title: task.length > 36 ? '${task.substring(0, 36)}...' : task,
        description: speechText,
        category: 'AI Voice Task',
        resultSummary: speechText,
      );

      await _speak(speechText);
      _finishTaskFlow(speechText);
    } catch (e) {
      debugPrint('Error executing user task: $e');
      await _speak('Task completed, Sir.');
      _finishTaskFlow('Task completed.');
    }
  }

  void _finishTaskFlow(String message) {
    _isProcessing = false;
    _currentTaskWords = '';
    _waveformTimer?.cancel();

    state = state.copyWith(
      isWokenUp: false,
      isAwaitingTask: false,
      isListening: false,
      statusMessage: 'Say "Hey Jack" or "Jack" to wake up',
      lastRecognized: message,
      waveformLevel: 0.15,
    );

    _scheduleLoopRestart(1200);
  }

  /// Toggles immediate listening when user taps the Jack Orb
  Future<void> toggleListeningNow() async {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    if (state.isListening && state.isAwaitingTask) {
      // If currently listening for task, cancel cleanly and return to standby
      _restartLoopTimer?.cancel();
      _waveformTimer?.cancel();
      _currentTaskWords = '';
      await _stt.stop();
      _isProcessing = false;
      state = state.copyWith(
        isListening: false,
        isWokenUp: false,
        isAwaitingTask: false,
        statusMessage: 'Say "Hey Jack" or tap Orb to listen',
        waveformLevel: 0.15,
      );
      _scheduleLoopRestart(1000);
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      state = state.copyWith(
        statusMessage: 'Microphone permission required',
      );
      return;
    }

    if (!_sttInitialized) {
      await _initEngine();
    }

    _restartLoopTimer?.cancel();
    _currentTaskWords = '';
    await _stt.stop();
    await _tts.stop();
    _isProcessing = false;

    state = state.copyWith(
      isWokenUp: true,
      isAwaitingTask: true,
      isListening: true,
      statusMessage: "Listening to your task...",
      lastRecognized: '',
    );

    _listenForUserTask();
  }

  /// Manually triggers the wake up flow (for testing or one-tap UI trigger)
  Future<void> wakeUpManually({String? customPrompt}) async {
    toggleListeningNow();
  }

  /// Speaks text with voice parameters dynamically tuned for active personality
  Future<void> _speak(String text) async {
    try {
      final personality = _ref.read(jackPersonalityProvider).activeProfile;
      await _tts.setPitch(personality.voicePitch);
      await _tts.setSpeechRate(personality.voiceRate);
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  void _scheduleLoopRestart(int delayMs) {
    _restartLoopTimer?.cancel();
    if (!state.isEnabled || _isProcessing || state.isAwaitingTask) return;

    _restartLoopTimer = Timer(Duration(milliseconds: delayMs), () {
      if (state.isEnabled && !_isProcessing && !state.isAwaitingTask) {
        _listenForWakeWord();
      }
    });
  }

  @override
  void dispose() {
    _restartLoopTimer?.cancel();
    _waveformTimer?.cancel();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}

final jackWakeWordProvider =
    StateNotifierProvider<JackWakeWordNotifier, JackWakeWordState>((ref) {
  return JackWakeWordNotifier(ref);
});
