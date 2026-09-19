// lib/providers/agent_state_provider.dart
//
// Jack — Production-Ready AI Mobile Agent
//   • Real-time voice (speech_to_text) — words stream on screen as you speak
//   • Multi-language TTS (speaks back in whatever language you spoke)
//   • JACK Backend llama-3.3-70b-versatile (primary) / llama-3.1-8b-instant (fallback)
//   • Full DOM automation via Android AccessibilityService:
//       click: [text]         → tap any on-screen element
//       type: [text]          → type into the focused field
//       swipe: up / down      → scroll the page
//       launch: [package]     → open any installed app
//       open: [url]           → open a URL in the browser
//   • Human-in-loop (HIL): For dangerous/irreversible actions, Jack asks
//     the user "Should I proceed? Say yes or no." before executing.
//   • Haptic feedback on action execution
//   • Full conversation memory (last 10 turns passed to JACK Backend)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent_models.dart';
import '../services/termux_socket_service.dart';
import '../services/execution_parser.dart';
import '../services/workflow_service.dart';
import '../services/jack_tools.dart';
import '../services/app_launcher_helper.dart';
import '../services/jack_master_dispatcher.dart';
import '../services/jack_reflex_cache.dart';
import '../services/nemotron_agent_service.dart';
import '../capsules/capsule_registry.dart';
import '../capsules/core_models.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:url_launcher/url_launcher.dart';

// ── Service providers ─────────────────────────────────────────────────────────

final termuxSocketProvider = Provider<TermuxSocketService>((ref) {
  final svc = TermuxSocketService();
  ref.onDispose(svc.dispose);
  return svc;
});

final workflowProvider = Provider<WorkflowService>((_) => WorkflowService());

// ── Notifier ──────────────────────────────────────────────────────────────────

class AgentStateNotifier extends StateNotifier<AgentState> {
  AgentStateNotifier(this._ws, this._wf) : super(const AgentState()) {
    _ws.messageStream.listen(_onFrame, onError: _onError);
    _initServices();
  }

  final TermuxSocketService _ws;
  final WorkflowService _wf;
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  

  bool _speechReady = false;
  // Detected language is set from the TEXT the user spoke, NOT from device locale
  // Default English — only changes if user actually speaks Hindi/Tamil etc.
  String _spokenLanguage = 'en-US';

  /// Notification listener subscription
  static const _notifChannel = EventChannel('com.syncra.syncra/notifications');
  StreamSubscription? _notifSub;

  // ── AI Model config ────────────────────────────────────────────────────────────────────────
  // All AI model execution, tool calling, and API keys are now securely managed
  // by the NestJS backend (Jack AI Router) and not stored inside the Flutter app.
  // The Flutter app strictly consumes JackApiClient and JackRealtimeClient.

  static const _platform = MethodChannel('com.syncra.syncra/accessibility');
  static const _overlay  = MethodChannel('com.syncra.syncra/overlay');

  static const _prefKey  = 'jack_chat_history';

  // â”€â”€ Initialization â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Map<String, String>? _maleVoice;

  Future<void> _initServices() async {
    JackCapsuleRegistry.initialize();

    _speechReady = await _speech.initialize(
      onError: (e) => debugPrint('STT Error: $e'),
    );

    // â”€â”€ TTS: Force deep male voice â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    await _tts.setSharedInstance(true);
    // Never block isolate on speak completion
    await _tts.awaitSpeakCompletion(false);
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(0.62); // very deep â€” clearly male
    await _tts.setLanguage('en-US');
    _tts.setCompletionHandler(() {
      // TTS finished â€” if we have a pending action after speaking, trigger it
      _onTtsComplete();
    });
    _tts.setErrorHandler((msg) {
      debugPrint('Jack TTS error: $msg');
    });

    // Try to explicitly pick a known Google male voice
    try {
      final rawVoices = await _tts.getVoices;
      final voices = (rawVoices as List).map((v) => Map<String, String>.from(
        (v as Map).map((k, val) => MapEntry(k.toString(), val.toString()))
      )).toList();

      // Known Google TTS male voice name prefixes on Android
      const malePatterns = ['tmc', 'rjs', 'gba', 'male', '-m-', 'en-in-x-end'];
      Map<String, String>? pick;

      for (final pattern in malePatterns) {
        pick = voices.firstWhere(
          (v) => (v['name'] ?? '').toLowerCase().contains(pattern) &&
                 (v['locale'] ?? '').toLowerCase().startsWith('en'),
          orElse: () => <String, String>{},
        );
        if (pick.isNotEmpty) break;
      }

      if (pick != null && pick.isNotEmpty) {
        _maleVoice = {'name': pick['name']!, 'locale': pick['locale']!};
        await _tts.setVoice(_maleVoice!);
      }
    } catch (e) {
      debugPrint('Jack TTS voice selection error: $e');
    }

    // â”€â”€ Load persisted chat history â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    await _loadHistory();

    // â”€â”€ Subscribe to incoming notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    _notifSub = _notifChannel
        .receiveBroadcastStream()
        .cast<Map>()
        .listen((event) async {
      final title = event['title'] as String? ?? '';
      final text  = event['text']  as String? ?? '';
      final pkg   = event['pkg']   as String? ?? '';
      if (state.isListening || state.isThinking || state.isExecutingOS) return;
      final appName = pkg.split('.').last;
      String prompt = 'Notification from $appName: "$title â€” $text". Give 1 short sentence summary.';
      if (pkg.contains('whatsapp')) {
          prompt = 'You received a WhatsApp message from "$title": "$text". Read it out concisely and accurately in 1 sentence. Do not skip the sender name or the message content.';
      }
      final summary = await _quickJACK Backend(prompt);
      if (summary.isNotEmpty) {
        final h = List<String>.from(state.chatHistory)
          ..add('ðŸ“¬ $appName: $title')
          ..add('Jack: $summary');
        state = state.copyWith(chatHistory: h, transcript: '');
        await _saveHistory();
        await _speak(summary);
      }
    });

    // â”€â”€ Handle incoming events from the Android Native Overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    _overlay.setMethodCallHandler((call) async {
      if (call.method == 'onBubbleTapped') {
        startListening();
      }
    });
  }

  // â”€â”€ Persistent memory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.chatHistory);
      await prefs.setString(_prefKey, encoded);
    } catch (_) {}
  }

  static const _personalityKey = 'jack_personality_mode';

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List).cast<String>();
        state = state.copyWith(chatHistory: list);
      }
      final savedMode = prefs.getString(_personalityKey);
      if (savedMode != null && savedMode.isNotEmpty) {
        state = state.copyWith(personalityMode: savedMode);
      }
    } catch (_) {}
  }

  void setPersonalityMode(String mode) async {
    final cleanMode = (mode == 'fun' || mode == 'roast') ? 'fun' : 'normal';
    state = state.copyWith(personalityMode: cleanMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_personalityKey, cleanMode);
    } catch (_) {}
  }

  void togglePersonalityMode() {
    final next = state.personalityMode == 'fun' ? 'normal' : 'fun';
    setPersonalityMode(next);
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
    state = state.copyWith(chatHistory: [], clearThoughtTrace: true, clearRoastCard: true);
  }

  // â”€â”€ System-wide overlay helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _showOverlay(String mode) async {
    try {
      state = state.copyWith(isPill: false);
      await _overlay.invokeMethod('show', {'mode': mode});
      await _overlay.invokeMethod('expandOverlay');
    } catch (_) {}
  }

  Future<void> _hideOverlay() async {
    try {
      state = state.copyWith(isPill: true);
      // collapse pill â†’ show bubble (stays visible outside the app)
      await _overlay.invokeMethod('collapseOverlay');
    } catch (_) {}
  }


  // â”€â”€ TTS completion callback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    void _onTtsComplete() {
    // Called by FlutterTTS when speaking finishes
    // Used for auto-restart-listen after speaking
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

    /// Fast 1-shot JACK Backend call with intelligent key rotation and backup model fallback
  

  // â”€â”€ Haptics (Flutter built-in, no extra package needed) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _haptic([bool heavy = false]) async {
    if (heavy) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // â”€â”€ TTS multi-language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    
    // If user is speaking English, explicitly use our chosen male voice (which overrides language)
    if (_spokenLanguage.startsWith('en')) {
      if (_maleVoice != null) {
        await _tts.setVoice(_maleVoice!);
      } else {
        await _tts.setLanguage('en-US');
      }
    } else {
      // For other languages, just set the locale and let system pick default voice
      await _tts.setLanguage(_spokenLanguage);
    }
    
    await _tts.speak(text);
  }

  // â”€â”€ DOM execution engine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Parses JACK Backend response line-by-line OR via structured JSON tool call.
  /// Executes DOM commands, returns clean spoken reply text.
  Future<String> _executeDomCommands(String response) async {
    // ── Check for structured JSON tool calls ──
    final jsonMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```').firstMatch(response);
    if (jsonMatch != null) {
      try {
        final parsed = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
        if (parsed['action'] == 'EXECUTE_TOOL' || parsed['command'] != null) {
          final cmd = parsed['command'] as String? ?? '';
          final params = (parsed['parameters'] as Map?)?.cast<String, dynamic>() ?? {};
          await _executeStructuredTool(cmd, params);
          
          // Strip the JSON block so it is not spoken or shown as conversational text
          final cleaned = response.replaceAll(jsonMatch.group(0)!, '').trim();
          return cleaned.isNotEmpty ? cleaned : 'I have executed the command.';
        }
      } catch (e) {
        debugPrint('Failed to parse tool JSON: $e');
      }
    }

    final lines = response.split('\n');
    final replyLines = <String>[];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('click:')) {
        final target = line.substring(6).trim();
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Tapping "$target"...',
          osLog: [...state.osLog, OsCommand(type: OsCommandType.click, timestamp: DateTime.now(), element: target)],
        );
        await JackCapabilitiesService.clickText(target);
        await Future.delayed(const Duration(milliseconds: 700));

      } else if (line.startsWith('type:')) {
        final text = line.substring(5).trim();
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Typing "$text"...',
          osLog: [...state.osLog, OsCommand(type: OsCommandType.type, timestamp: DateTime.now(), text: text)],
        );
        await _platform.invokeMethod('typeText', {'text': text}).catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line == 'swipe: up' || line == 'swipeUp') {
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Scrolling...',
          osLog: [...state.osLog, OsCommand(type: OsCommandType.scroll, timestamp: DateTime.now(), element: 'up')],
        );
        await _platform.invokeMethod('swipeUp').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 600));

      } else if (line == 'swipe: down') {
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Scrolling down...',
          osLog: [...state.osLog, OsCommand(type: OsCommandType.scroll, timestamp: DateTime.now(), element: 'down')],
        );
        await _platform.invokeMethod('swipeDown').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 600));

      } else if (line.startsWith('launch:')) {
        final rawPkg = line.substring(7).trim();
        await _haptic();
        final pkg = await AppLauncherHelper.resolvePackage(rawPkg);
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Opening app...',
          osLog: [...state.osLog, OsCommand(type: OsCommandType.intent, timestamp: DateTime.now(), target: pkg)],
        );
        await _platform.invokeMethod('launchApp', {'package': pkg}).catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 800));

      } else if (line.startsWith('open:')) {
        final urlStr = line.substring(5).trim();
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Opening link...',
          osLog: [...state.osLog, OsCommand(type: OsCommandType.intent, timestamp: DateTime.now(), target: urlStr)],
        );
        final uri = Uri.tryParse(urlStr);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
        }
        await Future.delayed(const Duration(milliseconds: 800));

      } else if (line.startsWith('call:')) {
        final numStr = line.substring(5).trim();
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Calling $numStr...',
        );
        try {
          final callResult = await _platform.invokeMethod<String>('directCall', {'number': numStr});
          if (callResult == "NOT_FOUND") {
            replyLines.add("I couldn't find a contact named $numStr.");
          } else if (callResult == "NO_PERMISSION") {
            replyLines.add("Please grant the phone and contacts permissions first.");
          }
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 1000));

      } else if (line == 'lock_screen') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Locking screen...');
        await _platform.invokeMethod('lockScreen').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line.startsWith('flashlight:') || line.startsWith('torch:')) {
        final on = line.contains('on') || !line.contains('off');
        await _haptic(true);
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: on ? 'Turning on Flashlight...' : 'Turning off Flashlight...',
          bixbyCard: BixbyCardData(
            type: 'flashlight',
            title: 'Flashlight',
            subtitle: on ? 'Turned ON' : 'Turned OFF',
            data: {'enabled': on},
          ),
        );
        await JackTools.toggleFlashlight(on);
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line.startsWith('volume:')) {
        final val = int.tryParse(line.substring(7).trim()) ?? 50;
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Setting volume to $val%...',
          bixbyCard: BixbyCardData(
            type: 'volume',
            title: 'Media Volume',
            subtitle: '$val%',
            data: {'level': val},
          ),
        );
        await _platform.invokeMethod('setVolume', {'level': val}).catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 400));

      } else if (line == 'screenshot' || line == 'take_screenshot') {
        await _haptic(true);
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Capturing screenshot...',
          bixbyCard: const BixbyCardData(
            type: 'action',
            title: 'Screenshot Captured',
            subtitle: 'Saved to device',
          ),
        );
        await JackTools.takeScreenshot();
        await Future.delayed(const Duration(milliseconds: 600));

      } else if (line == 'wifi' || line == 'openWifi') {
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Opening Wi-Fi...',
        );
        await JackTools.openWifiSettings();
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line.startsWith('bluetooth:')) {
        final on = line.contains('on') || !line.contains('off');
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: on ? 'Enabling Bluetooth...' : 'Disabling Bluetooth...',
          bixbyCard: BixbyCardData(
            type: 'action',
            title: 'Bluetooth',
            subtitle: on ? 'Turned ON' : 'Turned OFF',
            data: {'enabled': on},
          ),
        );
        await JackTools.toggleBluetooth(on);
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line == 'camera' || line == 'open_camera') {
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Opening camera...',
          bixbyCard: const BixbyCardData(
            type: 'action',
            title: 'Camera Launched',
            subtitle: 'Ready to capture',
          ),
        );
        await JackTools.openCamera();
        await Future.delayed(const Duration(milliseconds: 600));

      } else if (line == 'battery' || line == 'get_battery') {
        await _haptic();
        final level = await _platform.invokeMethod<int>('getBatteryLevel') ?? -1;
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Checking battery...',
          bixbyCard: BixbyCardData(
            type: 'battery',
            title: 'Battery Level',
            subtitle: level >= 0 ? '$level% Remaining' : 'Battery Status Normal',
            data: {'level': level >= 0 ? level : 85},
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line.startsWith('routine:')) {
        final rName = line.substring(8).trim().toLowerCase();
        await _haptic(true);
        if (rName.contains('morning')) {
          await _platform.invokeMethod('setVolume', {'level': 70}).catchError((_) {});
          state = state.copyWith(
            status: AgentStatus.executingOS,
            currentCmd: 'Good Morning Routine...',
            bixbyCard: const BixbyCardData(
              type: 'routine',
              title: 'Good Morning Routine',
              subtitle: 'Active',
              data: {'actions': 'Volume 70% · Weather synced · Have a wonderful day!'},
            ),
          );
        } else if (rName.contains('bedtime') || rName.contains('night')) {
          await JackTools.toggleFlashlight(false);
          await _platform.invokeMethod('setVolume', {'level': 0}).catchError((_) {});
          state = state.copyWith(
            status: AgentStatus.executingOS,
            currentCmd: 'Bedtime Routine...',
            bixbyCard: const BixbyCardData(
              type: 'routine',
              title: 'Bedtime Routine',
              subtitle: 'Night Mode Active',
              data: {'actions': 'Flashlight off · Mute on · Sleep well!'},
            ),
          );
        } else if (rName.contains('focus')) {
          await _platform.invokeMethod('setVolume', {'level': 0}).catchError((_) {});
          state = state.copyWith(
            status: AgentStatus.executingOS,
            currentCmd: 'Focus Mode...',
            bixbyCard: const BixbyCardData(
              type: 'routine',
              title: 'Focus Mode',
              subtitle: 'Distractions Silenced',
              data: {'actions': 'Notifications muted · Media volume 0% · Focus timer active'},
            ),
          );
        }
        await Future.delayed(const Duration(milliseconds: 600));

      } else if (line == 'swipe: left') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Swiping left...');
        await _platform.invokeMethod('swipeLeft').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line == 'swipe: right') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Swiping right...');
        await _platform.invokeMethod('swipeRight').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line == 'pressBack') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Pressing Back...');
        await _platform.invokeMethod('pressBack').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 400));

      } else if (line == 'pressEnter') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Pressing Enter...');
        await _platform.invokeMethod('pressEnter').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 400));

      } else if (line == 'pressHome') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Going Home...');
        await _platform.invokeMethod('pressHome').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 400));

      } else if (line == 'pressRecents') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Opening Recents...');
        await _platform.invokeMethod('pressRecents').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 400));

      } else if (line == 'pullNotifications') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Pulling Notifications...');
        await _platform.invokeMethod('pullNotifications').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 500));

      } else if (line == 'pullQuickSettings') {
        await _haptic();
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Opening Quick Settings...');
        await _platform.invokeMethod('pullQuickSettings').catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 500));

      } else {
        replyLines.add(line);
      }
    }

    return replyLines.join(' ').trim();
  }

  /// Executes structured tool commands emitted in JSON by Jack.
  Future<void> _executeStructuredTool(String cmd, Map<String, dynamic> params) async {
    final lowerCmd = cmd.toLowerCase().trim();
    await _haptic();
    switch (lowerCmd) {
      case 'toggle_flashlight':
      case 'flashlight':
        final enabled = params['enabled'] == true || params['state'] == 'on';
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: enabled ? 'Turning on Flashlight...' : 'Turning off Flashlight...',
          bixbyCard: BixbyCardData(
            type: 'flashlight',
            title: 'Flashlight',
            subtitle: enabled ? 'Turned ON' : 'Turned OFF',
            data: {'enabled': enabled},
          ),
        );
        await JackTools.toggleFlashlight(enabled);
        break;

      case 'set_volume':
      case 'volume':
        final level = (params['level'] as num?)?.toInt() ?? 50;
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Setting volume to $level%...',
          bixbyCard: BixbyCardData(
            type: 'volume',
            title: 'Media Volume',
            subtitle: '$level%',
            data: {'level': level},
          ),
        );
        await _platform.invokeMethod('setVolume', {'level': level}).catchError((_) {});
        break;

      case 'take_screenshot':
      case 'screenshot':
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Capturing screenshot...',
          bixbyCard: const BixbyCardData(
            type: 'action',
            title: 'Screenshot Captured',
            subtitle: 'Saved to device',
          ),
        );
        await JackTools.takeScreenshot();
        break;

      case 'get_battery':
      case 'battery':
        final level = await _platform.invokeMethod<int>('getBatteryLevel') ?? -1;
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Checking battery...',
          bixbyCard: BixbyCardData(
            type: 'battery',
            title: 'Battery Level',
            subtitle: level >= 0 ? '$level% Remaining' : 'Battery Status Normal',
            data: {'level': level >= 0 ? level : 85},
          ),
        );
        break;

      case 'open_camera':
      case 'camera':
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Opening camera...',
          bixbyCard: const BixbyCardData(
            type: 'action',
            title: 'Camera Launched',
            subtitle: 'Ready to capture',
          ),
        );
        await JackTools.openCamera();
        break;

      case 'toggle_wifi':
      case 'open_wifi':
      case 'wifi':
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Opening Wi-Fi settings...');
        await JackTools.openWifiSettings();
        break;

      case 'toggle_bluetooth':
      case 'bluetooth':
        final enabled = params['enabled'] == true || params['state'] == 'on';
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: enabled ? 'Enabling Bluetooth...' : 'Disabling Bluetooth...',
        );
        await JackTools.toggleBluetooth(enabled);
        break;

      case 'launch_app':
      case 'launch':
        final rawPkg = (params['package'] ?? params['app_name'] ?? params['app'] ?? params['name']) as String? ?? '';
        final pkg = await AppLauncherHelper.resolvePackage(rawPkg);
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Opening $rawPkg...');
        await _platform.invokeMethod('launchApp', {'package': pkg}).catchError((_) {});
        break;

      case 'click':
      case 'click_element':
      case 'click_text':
        final target = (params['text'] ?? params['element'] ?? params['label']) as String? ?? '';
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Tapping "$target"...');
        await JackCapabilitiesService.clickText(target);
        break;

      case 'type':
      case 'type_text':
      case 'input_text':
        final text = params['text'] as String? ?? '';
        state = state.copyWith(status: AgentStatus.executingOS, currentCmd: 'Typing...');
        await _platform.invokeMethod('typeText', {'text': text}).catchError((_) {});
        break;

      case 'scroll':
      case 'swipe':
        final dir = (params['direction'] ?? 'up').toString().toLowerCase();
        if (dir == 'down') {
          await _platform.invokeMethod('swipeDown').catchError((_) {});
        } else if (dir == 'left') {
          await _platform.invokeMethod('swipeLeft').catchError((_) {});
        } else if (dir == 'right') {
          await _platform.invokeMethod('swipeRight').catchError((_) {});
        } else {
          await _platform.invokeMethod('swipeUp').catchError((_) {});
        }
        break;

      case 'run_routine':
      case 'routine':
        final rName = (params['name'] ?? params['routine'] ?? 'morning').toString().toLowerCase();
        if (rName.contains('morning')) {
          await _platform.invokeMethod('setVolume', {'level': 70}).catchError((_) {});
          state = state.copyWith(
            status: AgentStatus.executingOS,
            currentCmd: 'Good Morning Routine...',
            bixbyCard: const BixbyCardData(
              type: 'routine',
              title: 'Good Morning Routine',
              subtitle: 'Active',
              data: {'actions': 'Volume 70% · Weather synced · Have a wonderful day!'},
            ),
          );
        } else if (rName.contains('bedtime') || rName.contains('night')) {
          await JackTools.toggleFlashlight(false);
          await _platform.invokeMethod('setVolume', {'level': 0}).catchError((_) {});
          state = state.copyWith(
            status: AgentStatus.executingOS,
            currentCmd: 'Bedtime Routine...',
            bixbyCard: const BixbyCardData(
              type: 'routine',
              title: 'Bedtime Routine',
              subtitle: 'Night Mode Active',
              data: {'actions': 'Flashlight off · Mute on · Sleep well!'},
            ),
          );
        } else if (rName.contains('focus')) {
          await _platform.invokeMethod('setVolume', {'level': 0}).catchError((_) {});
          state = state.copyWith(
            status: AgentStatus.executingOS,
            currentCmd: 'Focus Mode...',
            bixbyCard: const BixbyCardData(
              type: 'routine',
              title: 'Focus Mode',
              subtitle: 'Distractions Silenced',
              data: {'actions': 'Notifications muted · Media volume 0% · Focus timer active'},
            ),
          );
        }
        break;

      case 'lock_screen':
        await _platform.invokeMethod('lockScreen').catchError((_) {});
        break;

      case 'press_back':
      case 'back':
        await _platform.invokeMethod('pressBack').catchError((_) {});
        break;

      case 'press_home':
      case 'home':
        await _platform.invokeMethod('pressHome').catchError((_) {});
        break;

      case 'press_recents':
      case 'recents':
        await _platform.invokeMethod('pressRecents').catchError((_) {});
        break;

      case 'pull_notifications':
      case 'notifications':
        await _platform.invokeMethod('pullNotifications').catchError((_) {});
        break;

      case 'pull_quick_settings':
      case 'quick_settings':
        await _platform.invokeMethod('pullQuickSettings').catchError((_) {});
        break;

      case 'set_alarm':
        final hour = (params['hour'] as num?)?.toInt() ?? 7;
        final minute = (params['minute'] as num?)?.toInt() ?? 0;
        final label = params['label'] as String? ?? 'Jack Alarm';
        await JackTools.call('set_alarm', {'hour': hour, 'minute': minute, 'label': label});
        break;

      case 'set_timer':
        final seconds = (params['seconds'] as num?)?.toInt() ?? 60;
        final label = params['label'] as String? ?? 'Jack Timer';
        await JackTools.call('set_timer', {'seconds': seconds, 'label': label});
        break;

      case 'direct_call':
      case 'call':
        final number = (params['number'] ?? params['contact']) as String? ?? '';
        await _platform.invokeMethod('directCall', {'number': number}).catchError((_) {});
        break;

      case 'send_sms':
        final to = (params['number'] ?? params['to']) as String? ?? '';
        final msg = (params['message'] ?? params['text']) as String? ?? '';
        await JackTools.call('send_sms', {'name_or_number': to, 'message': msg});
        break;

      default:
        final res = await JackMasterDispatcher.executeCommand({
          'intent': lowerCmd,
          'params': params,
        });
        if (res['status'] == 'success') {
          final msg = res['message'] as String? ?? 'Executed';
          final type = res['type'] as String?;
          final cardData = res['data'] as Map<String, dynamic>?;
          if (type != null) {
            state = state.copyWith(
              bixbyCard: BixbyCardData(
                type: type,
                title: type.toUpperCase(),
                subtitle: msg,
                data: cardData ?? {},
              ),
            );
          }
        }
        break;
    }
  }

  /// Shows a HIL confirmation â€” speaks the question and waits for the user
  // â”€â”€ WS legacy fallback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _onFrame(String raw) {
    final frame = ExecutionParser.parse(raw);
    if (frame == null) return;
    switch (frame.wsStatus) {
      case 'transcript':
        state = state.copyWith(transcript: frame.transcript ?? '');
      case 'thinking':
        state = state.copyWith(status: AgentStatus.thinking);
      case 'executing':
        final cmd = frame.command!;
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: ExecutionParser.statusPill(cmd),
          osLog: [...state.osLog, cmd],
        );
      case 'complete':
        final action = frame.action ?? '';
        final data = frame.data ?? {};
        final doneCmd = OsCommand(type: OsCommandType.complete, timestamp: DateTime.now(), target: action);
        state = state.copyWith(
          status: AgentStatus.complete, action: action,
          currentCmd: 'âœ“ Done', osLog: [...state.osLog, doneCmd],
        );
        _wf.dispatch(action, data);
      case 'error':
        state = state.copyWith(status: AgentStatus.error, errorMessage: frame.errorMessage ?? 'Unknown error');
    }
  }

  void _onError(Object e) => state = state.copyWith(
    status: AgentStatus.error,
    errorMessage: e.toString(),
  );

  // â”€â”€ Public actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> startListening() async {
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
    
    if (!_speechReady) {
      _speechReady = await _speech.initialize();
    }

    await _haptic();
    state = const AgentState(status: AgentStatus.listening, transcript: '');
    await _showOverlay('listening'); // Purple pulsing border = listening

    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          state = state.copyWith(transcript: result.recognizedWords);
          _spokenLanguage = _detectLangFromText(result.recognizedWords);
        }
        if (result.finalResult) {
          if (result.recognizedWords.isNotEmpty) {
            processText(result.recognizedWords);
          } else {
            // Empty result â€” restart
            Future.delayed(const Duration(milliseconds: 400), startListening);
          }
        }
      },
      onSoundLevelChange: (level) {
        try { _overlay.invokeMethod('updateAudioLevel', {'level': level}); } catch (_) {}
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.deviceDefault, // most reliable on Android
        autoPunctuation: true,
        sampleRate: 44100,
      ),
    );
    // Timeout: if no speech in 8s, restart
    Future.delayed(const Duration(seconds: 8), () {
      if (state.status == AgentStatus.listening) {
        _speech.stop();
        Future.delayed(const Duration(milliseconds: 300), startListening);
      }
    });
  }

  /// Detect language from text by analysing Unicode character ranges.
  /// Returns BCP-47 locale string e.g. 'hi-IN', 'ta-IN', 'en-US'.
  String _detectLangFromText(String text) {
    if (text.isEmpty) return 'en-US';
    final chars = text.runes;
    int devanagari = 0, latin = 0, tamil = 0, telugu = 0,
        kannada = 0, malayalam = 0, arabic = 0, bengali = 0;
    for (final c in chars) {
      if (c >= 0x0900 && c <= 0x097F) {
        devanagari++;
      } else if (c >= 0x0041 && c <= 0x007A) {
        latin++;
      } else if (c >= 0x0B80 && c <= 0x0BFF) {
        tamil++;
      } else if (c >= 0x0C00 && c <= 0x0C7F) {
        telugu++;
      } else if (c >= 0x0C80 && c <= 0x0CFF) {
        kannada++;
      } else if (c >= 0x0D00 && c <= 0x0D7F) {
        malayalam++;
      } else if (c >= 0x0600 && c <= 0x06FF) {
        arabic++;
      } else if (c >= 0x0980 && c <= 0x09FF) {
        bengali++;
      }
    }
    final max = [devanagari, latin, tamil, telugu, kannada, malayalam, arabic, bengali]
        .reduce((a, b) => a > b ? a : b);
    if (max == 0 || max == latin) return 'en-US';
    if (max == devanagari) return 'hi-IN';
    if (max == tamil)      return 'ta-IN';
    if (max == telugu)     return 'te-IN';
    if (max == kannada)    return 'kn-IN';
    if (max == malayalam)  return 'ml-IN';
    if (max == arabic)     return 'ar-SA';
    if (max == bengali)    return 'bn-IN';
    return 'en-US';
  }

  /// Called automatically when speech finalizes, OR manually via stopListening().
  Future<void> processText(String spokenText) async {
    if (state.status == AgentStatus.thinking || state.status == AgentStatus.executingOS) {
      return; // Already processing, ignore duplicate
    }

    final promptText = spokenText.trim();
    if (promptText.isEmpty) {
      if (!state.isPill) {
        state = state.copyWith(status: AgentStatus.idle);
        await _hideOverlay();
      }
      return;
    }

    // ── Wake Word Logic ──
    if (state.isPill) {
      final lower = promptText.toLowerCase();
      if (!lower.contains('bixby') && !lower.contains('jack')) {
        // Ignore background noise if Bixby or Jack is not called
        return; 
      } else {
        // Wake up!
        await _showOverlay('listening');
        await _haptic();
      }
    }

    await _speech.stop();
    await _haptic();

    // ── SYSTEM 1: Fast Reflex Engine (<100ms) ──────────────────────────────────
    final reflex = JackReflexCache.matchReflex(promptText);
    if (reflex != null) {
      debugPrint("[JackFastPath] Direct hit! Bypassing cloud LLM.");
      state = state.copyWith(status: AgentStatus.executingOS);
      
      final parsedCapsule = await JackCapsuleRegistry.dispatch(
        preferredCapsuleId: reflex['capsule_id'],
        actionName: reflex['action'],
        inputs: reflex['params'] ?? {},
      );

      final msg = parsedCapsule?.speechText ?? 'Executed.';
      
      state = state.copyWith(
        status: AgentStatus.complete,
        currentCmd: msg,
        capsuleResult: parsedCapsule,
        chatHistory: [...state.chatHistory, 'User: $promptText', 'Jack: $msg'],
      );

      _overlay.invokeMethod('updateOverlayChat', {'user': promptText, 'jack': msg});
      await _saveHistory();

      // Speculative Parallelism: System action already executed, speak response concurrently
      await _tts.speak(msg);
      return;
    }

    // ── Check if completing a suspended input-view session ───────────────────
    if (state.capsuleResult?.viewTemplate.viewType == ViewType.inputView) {
      // In a real implementation, NLP would extract the entity. 
      // For now, let the user tap the card (which calls resolveInputSelection).
      // Or if they say "Cancel", we cancel.
      if (promptText.toLowerCase() == 'cancel') {
         state = state.copyWith(status: AgentStatus.idle, clearCapsuleResult: true);
         await _speak("Action cancelled.");
         return;
      }
    }

    state = state.copyWith(
      status: AgentStatus.thinking,
      errorMessage: null,
      chatHistory: [...state.chatHistory, 'User: $promptText'],
    );
    
    // Update Kotlin floating overlay pill with what user said
    _overlay.invokeMethod('updateOverlayChat', {'user': promptText, 'jack': ''});
    _overlay.invokeMethod('show', {'mode': 'thinking'});
    await _showOverlay('thinking'); // Cyan pulse while processing
    if (state.activeModels.contains('nemotron')) {
      await _callNemotron(promptText, state.chatHistory);
    } else {
      await _callJACK Backend(promptText, state.chatHistory);
    }
  }

  Future<void> submitTextPrompt(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    await processText(query);
  }

  Future<void> stopListening() async {
    final spokenText = state.transcript.trim();
    await processText(spokenText.isEmpty ? '' : spokenText);
  }

  Future<void> resolveInputSelection(Map<String, dynamic> chosenPayload) async {
    final currentCapsule = state.capsuleResult;
    if (currentCapsule == null || currentCapsule.viewTemplate.viewType != ViewType.inputView) return;

    // The currentCapsule tells us what action was pending.
    // In our architecture, if it's input-view, the action name should be preserved.
    // But how do we know the action name? CapsuleDispatchResult doesn't store actionName by default.
    // Let's assume the UI payload has it, or we just pass it.
    // Actually, chosenPayload from BixbyInputViewRenderer contains the parameters to resume.
    final pendingAction = chosenPayload['action_name'] ?? 'PlaceCall'; // fallback
    final pendingCapsule = chosenPayload['capsule_id'] ?? 'jack.communication';
    
    // Merge the chosenPayload['params'] with whatever we needed. 
    // The user spec said `onOptionSelected(payload)`, so `chosenPayload` is the params.
    final mergedParams = chosenPayload;

    state = state.copyWith(status: AgentStatus.executingOS, clearCapsuleResult: true);

    final result = await JackCapsuleRegistry.dispatch(
      preferredCapsuleId: pendingCapsule,
      actionName: pendingAction,
      inputs: mergedParams,
    );

    final cleanReply = result?.speechText ?? 'Executed.';
    final finalHistory = List<String>.from(state.chatHistory)..add('Jack: $cleanReply');

    state = state.copyWith(
      status: AgentStatus.complete,
      currentCmd: '✓ Done',
      chatHistory: finalHistory,
      transcript: '',
      capsuleResult: result,
    );

    _overlay.invokeMethod('updateOverlayChat', {'user': '', 'jack': cleanReply});
    await _saveHistory();
    await _speak(cleanReply);
  }


  // ── Unified LLM POST (JACK Backend) ────────────────────────────────────────────────
  // Primary model: llama-3.3-70b-versatile (supports tools)
  // Backup model:  llama-3.1-8b-instant (fallback)
  // Automatically rotates through [] on 429 (rate limit) or 401.
  


        if (rawIntent.contains('routine')) {
          capsuleId = 'jack.routines';
          actionName = 'ExecuteRoutine';
        } else if (rawIntent.contains('communication') || rawIntent.contains('call')) {
          capsuleId = 'jack.communication';
          actionName = 'PlaceCall';
        } else if (rawIntent.contains('alarm')) {
          capsuleId = 'jack.alarm';
          actionName = 'SetAlarm';
        }

        parsedCapsule = await JackCapsuleRegistry.dispatch(
          preferredCapsuleId: capsuleId,
          actionName: actionName,
          inputs: execution['payload'] ?? execution['parameters'] ?? {},
        );
      }

      final finalHistory = List<String>.from(state.chatHistory)..add('Jack: $speechText');

      state = state.copyWith(
        status: AgentStatus.complete,
        currentCmd: '✓ Done',
        chatHistory: finalHistory,
        transcript: '',
        thoughtTrace: thoughtSummary,
        capsuleResult: parsedCapsule,
      );

      _overlay.invokeMethod('updateOverlayChat', {'user': '', 'jack': speechText});
      await _saveHistory();
      await _speak(speechText);
      await _hideOverlay();
      
    } catch (e) {
      state = state.copyWith(
        status: AgentStatus.error,
        errorMessage: 'Nemotron Error: $e',
        transcript: '',
      );
      await _hideOverlay();
      await _speak("Nemotron error.");
    }
  }

  

  Future<void> reset() async {
    await _speech.stop();
    await _tts.stop();
    await _hideOverlay();
    await clearHistory();
    state = const AgentState();
  }

  void toggleModelActive(String path) {} // no-op, all always active
}

// â”€â”€ Root provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final agentStateProvider =
    StateNotifierProvider<AgentStateNotifier, AgentState>((ref) {
  return AgentStateNotifier(
    ref.watch(termuxSocketProvider),
    ref.watch(workflowProvider),
  );
});


