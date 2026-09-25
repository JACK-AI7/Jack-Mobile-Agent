import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/overlay/jack_global_overlay.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'services/jack_master_dispatcher.dart';
import 'services/api/direct_groq_service.dart';
import 'services/telephony/jack_call_screener_service.dart' as import_call_service;
import 'services/voice/jack_male_voice_helper.dart';
import 'services/tasks/jack_task_service.dart';
import 'services/immortal/jack_immortal_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080814),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: JackApp()));
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const JackGlobalOverlay(),
    ),
  );
}

class JackApp extends ConsumerStatefulWidget {
  const JackApp({super.key});

  @override
  ConsumerState<JackApp> createState() => _JackAppState();
}

class _JackAppState extends ConsumerState<JackApp> with WidgetsBindingObserver {
  static const EventChannel _callChannel = EventChannel('com.jack.agent/calls');
  static const MethodChannel _overlayChannel =
      MethodChannel('com.jack.agent/overlay');
  StreamSubscription? _callSub;

  final stt.SpeechToText _overlaySpeech = stt.SpeechToText();
  final FlutterTts _overlayTts = FlutterTts();
  bool _overlaySpeechInit = false;
  bool _isOverlayLoopActive = false;
  final List<Map<String, String>> _overlayChatMemory = [];
  Timer? _overlayInactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize Telephony Call Screener global handles
    import_call_service.JackCallScreenerService.navigatorKey = rootNavigatorKey;
    import_call_service.JackCallScreenerService.globalRef = ref;

    // Initialize Jack Immortal 24/7 Background Persistence & Daemon
    ref.read(jackImmortalProvider);

    // Hide overlay when app starts in foreground
    try {
      _overlayChannel.invokeMethod('hideAll');
    } catch (_) {}
    FlutterOverlayWindow.closeOverlay();

    // Listen for floating bubble taps & pill dismissals outside the app
    _overlayChannel.setMethodCallHandler((call) async {
      if (call.method == 'onBubbleTapped') {
        _handleBubbleVoiceInteraction();
      } else if (call.method == 'onPillDismissed') {
        _isOverlayLoopActive = false;
        _overlayInactivityTimer?.cancel();
        await JackTaskRecorder.completeSessionTask();
        try {
          await _overlaySpeech.stop();
          await _overlayTts.stop();
        } catch (_) {}
      }
    });

    _callSub = _callChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final evType = event['event'];
        if (evType == 'incoming' || evType == 'answered') {
          if (!mounted) return;
          import_call_service.JackCallScreenerService.instance.triggerIncomingCall(
            context,
            ref,
            callerName: event['contactName']?.toString() ?? 'Unknown',
            phoneNumber: event['number']?.toString() ?? '',
            autoAnswer: true,
          );
        }
      }
    });
  }

  void _resetInactivityTimer() {
    _overlayInactivityTimer?.cancel();
    _overlayInactivityTimer = Timer(const Duration(seconds: 16), () async {
      if (_isOverlayLoopActive) {
        _isOverlayLoopActive = false;
        await JackTaskRecorder.completeSessionTask();
        try {
          await _overlaySpeech.stop();
          await _overlayTts.stop();
          await _overlayChannel.invokeMethod('show', {'mode': 'bubble'});
        } catch (_) {}
      }
    });
  }

  Future<void> _handleBubbleVoiceInteraction() async {
    _isOverlayLoopActive = true;
    _overlayChatMemory.clear();

    // Start single continuous task for this pill session
    await JackTaskRecorder.startOrGetSessionTask(initialTitle: 'Live Assistant Session');

    try {
      await _overlayChannel.invokeMethod('show', {'mode': 'listening'});
      await _overlayChannel.invokeMethod(
          'updateOverlayChat', {'user': 'Listening...', 'jack': ''});

      if (!_overlaySpeechInit) {
        _overlaySpeechInit = await _overlaySpeech.initialize();
        await JackMaleVoiceHelper.configureMaleBaritoneVoice(_overlayTts);
      }

      _listenOverlayLoop();
    } catch (_) {}
  }

  Future<void> _listenOverlayLoop() async {
    if (!_isOverlayLoopActive) return;
    _resetInactivityTimer();

    try {
      if (_overlaySpeech.isListening) {
        await _overlaySpeech.stop();
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await _overlaySpeech.listen(
        onResult: (result) async {
          _resetInactivityTimer();
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            await _overlayChannel.invokeMethod(
                'updateOverlayChat', {'user': words, 'jack': 'Listening...'});
          }

          if (result.finalResult && words.isNotEmpty) {
            _overlayInactivityTimer?.cancel();
            await _overlaySpeech.stop();

            // Check dismissal / goodbye commands
            final lower = words.toLowerCase();
            if (lower == 'bye' ||
                lower == 'goodbye' ||
                lower == 'close' ||
                lower == 'exit' ||
                lower == 'stop' ||
                lower == 'cancel' ||
                lower.contains('close pill') ||
                lower.contains('thank you jack')) {
              await _overlayChannel.invokeMethod('show', {'mode': 'speaking'});
              await _overlayChannel.invokeMethod('updateOverlayChat', {
                'user': words,
                'jack': 'Good day, Sir.',
              });
              await _overlayTts.speak('Good day, Sir.');
              await JackTaskRecorder.completeSessionTask();
              await Future.delayed(const Duration(milliseconds: 1400));
              _isOverlayLoopActive = false;
              await _overlayChannel.invokeMethod('show', {'mode': 'bubble'});
              return;
            }

            await _overlayChannel.invokeMethod('show', {'mode': 'thinking'});
            await _overlayChannel.invokeMethod('updateOverlayChat', {
              'user': words,
              'jack': 'Processing request...',
            });

            // 1. Try continuous reflex fast-path (Hardware, DOM, YouTube, Chrome, Volume, Power, etc.)
            final reflex = await JackMasterDispatcher.tryReflexFastPath(words);
            String response = reflex?['message']?.toString() ??
                reflex?['result']?.toString() ??
                '';

            // 2. If not reflex, use dynamic AI with conversational memory
            if (reflex == null || response.isEmpty) {
              try {
                final groq = DirectGroqService();
                response = await groq.generate(
                  prompt: words,
                  conversationHistory: _overlayChatMemory,
                );
                response = response
                    .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
                    .trim();
              } catch (_) {
                response = "I have processed your command, Sir.";
              }
            }

            // Clean markdown and raw links for speech and pill display
            final verbalSpeech = response
                .replaceAll(RegExp(r'!\[.*?\]\(.*?\)', dotAll: true), '')
                .replaceAll(RegExp(r'\[(.*?)\]\((.*?)\)'), r'$1')
                .replaceAll(RegExp(r'https?://\S+'), '')
                .replaceAll(RegExp(r'[#*`_>~-]'), '')
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();

            // Extract concise 1-2 sentence preview for the pill (Never show raw markdown or URLs)
            String cleanPillPreview = verbalSpeech;
            if (cleanPillPreview.contains('.')) {
              final sentences = cleanPillPreview.split('.');
              cleanPillPreview = sentences.take(2).join('. ').trim();
              if (!cleanPillPreview.endsWith('.')) cleanPillPreview += '.';
            }
            if (cleanPillPreview.length > 130) {
              cleanPillPreview = '${cleanPillPreview.substring(0, 127)}...';
            }

            _overlayChatMemory.add({'role': 'user', 'content': words});
            _overlayChatMemory
                .add({'role': 'assistant', 'content': verbalSpeech});
            if (_overlayChatMemory.length > 10) {
              _overlayChatMemory.removeRange(0, 2);
            }

            // Append to the SINGLE continuous session task
            await JackTaskRecorder.appendSessionAction(words, cleanPillPreview);

            await _overlayChannel.invokeMethod('show', {'mode': 'speaking'});
            await _overlayChannel.invokeMethod('updateOverlayChat', {
              'user': words,
              'jack': cleanPillPreview,
            });

            // Ensure male baritone voice is active
            await JackMaleVoiceHelper.configureMaleBaritoneVoice(_overlayTts);

            final speakText = verbalSpeech.length > 250
                ? '${verbalSpeech.substring(0, 250)}...'
                : verbalSpeech;
            await _overlayTts.speak(speakText);

            // Robust watchdog timer to ensure continuous loop never freezes
            Timer? watchdog;
            bool didContinue = false;

            void resumeListening() async {
              if (didContinue) return;
              didContinue = true;
              watchdog?.cancel();

              if (!_isOverlayLoopActive) return;
              await Future.delayed(const Duration(milliseconds: 350));
              if (!_isOverlayLoopActive) return;

              await _overlayChannel.invokeMethod('show', {'mode': 'listening'});
              await _overlayChannel.invokeMethod('updateOverlayChat', {
                'user': 'Listening...',
                'jack': cleanPillPreview,
              });

              _listenOverlayLoop();
            }

            _overlayTts.setCompletionHandler(() => resumeListening());
            _overlayTts.setErrorHandler((_) => resumeListening());

            final expectedMs = (speakText.length * 80).clamp(2200, 11000);
            watchdog = Timer(Duration(milliseconds: expectedMs + 1200), () {
              resumeListening();
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 16),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _overlayInactivityTimer?.cancel();
    _overlaySpeech.stop();
    _overlayTts.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background — show native floating 3D Jack Orb bubble outside the app
      try {
        await _overlayChannel.invokeMethod('show', {'mode': 'bubble'});
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground — hide floating bubble inside the app
      try {
        _isOverlayLoopActive = false;
        _overlayInactivityTimer?.cancel();
        await _overlaySpeech.stop();
        await _overlayTts.stop();
        await _overlayChannel.invokeMethod('hideAll');
      } catch (_) {}
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Jack Agent',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
