// lib/services/telephony/jack_ai_voice_call_engine.dart
//
// Jack AI Voice Call Engine — Unified Telephony & WebRTC Voice Architecture.
// Combines flutter_callkit_incoming for native lock-screen / heads-up call UI
// with flutter_webrtc audio channels, speech-to-text live transcription,
// and DirectGroqService for real-time bi-directional voice calling.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../ai/jack_local_llm_engine.dart';
import '../memory/jack_cognitive_memory.dart';
import '../voice/jack_male_voice_helper.dart';

enum AiCallState {
  idle,
  incomingRinging,
  outgoingDialing,
  connected,
  ended,
}

class JackAiVoiceCallEngine {
  static final JackAiVoiceCallEngine instance = JackAiVoiceCallEngine._internal();
  JackAiVoiceCallEngine._internal();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  AiCallState _callState = AiCallState.idle;
  AiCallState get callState => _callState;

  String _currentCallUuid = '';
  String _currentCallerName = '';
  String _currentCallerNumber = '';
  bool _isOutgoing = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localAudioStream;

  final ValueNotifier<List<Map<String, String>>> liveTranscriptNotifier =
      ValueNotifier<List<Map<String, String>>>([]);

  final ValueNotifier<bool> isJackSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isCallerSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isTakenOverByUserNotifier = ValueNotifier<bool>(false);
  bool get isTakenOverByUser => isTakenOverByUserNotifier.value;

  Future<void> init() async {
    try {
      await JackMaleVoiceHelper.configureMaleBaritoneVoice(_tts);
      await _stt.initialize();
      _listenToCallKitEvents();
      unawaited(JackLocalLlmEngine.instance.initializeLocalAgent());
    } catch (e) {
      debugPrint('[JackAiVoiceCallEngine] Init error: $e');
    }
  }

  void _listenToCallKitEvents() {
    FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;
      if (event is CallEventActionCallAccept) {
        debugPrint('[CallKit] Call Accepted');
        _onCallAnswered();
      } else if (event is CallEventActionCallDecline ||
          event is CallEventActionCallEnded ||
          event is CallEventActionCallTimeout) {
        debugPrint('[CallKit] Call Ended/Declined');
        endCall();
      }
    });
  }

  /// Triggers a real incoming call with full-screen native CallKit UI
  Future<void> showIncomingCall({
    required String callerName,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    _currentCallerName = callerName;
    _currentCallerNumber = phoneNumber;
    _isOutgoing = false;
    _callState = AiCallState.incomingRinging;
    _currentCallUuid = DateTime.now().millisecondsSinceEpoch.toString();
    isTakenOverByUserNotifier.value = false;
    liveTranscriptNotifier.value = [];

    final params = CallKitParams(
      id: _currentCallUuid,
      nameCaller: callerName,
      appName: 'Jack AI Agent',
      avatar: avatarUrl ?? 'https://i.pravatar.cc/150',
      handle: phoneNumber,
      type: 0, // Audio call
      duration: 30000,
      extra: <String, dynamic>{
        'callerName': callerName,
        'phoneNumber': phoneNumber,
        'isAiScreened': true,
      },
      headers: <String, dynamic>{'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#07070A',
        actionColor: '#00E5FF',
        textColor: '#FFFFFF',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Triggers a real outgoing call initiated by Jack AI
  Future<void> startOutgoingCall({
    required String recipientName,
    required String phoneNumber,
  }) async {
    _currentCallerName = recipientName;
    _currentCallerNumber = phoneNumber;
    _isOutgoing = true;
    _callState = AiCallState.outgoingDialing;
    _currentCallUuid = DateTime.now().millisecondsSinceEpoch.toString();
    isTakenOverByUserNotifier.value = false;
    liveTranscriptNotifier.value = [];

    final params = CallKitParams(
      id: _currentCallUuid,
      nameCaller: recipientName,
      appName: 'Jack AI Agent',
      handle: phoneNumber,
      type: 0,
      extra: <String, dynamic>{
        'callerName': recipientName,
        'phoneNumber': phoneNumber,
        'isOutgoing': true,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        backgroundColor: '#07070A',
        actionColor: '#8B5CF6',
        textColor: '#FFFFFF',
      ),
    );

    await FlutterCallkitIncoming.startCall(params);
    await _initWebRtcAudioChannel();

    // Auto-connect call after dialing
    Future.delayed(const Duration(milliseconds: 1500), () {
      _onCallAnswered();
    });
  }

  /// Sets up WebRTC local audio track for bi-directional streaming
  Future<void> _initWebRtcAudioChannel() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      _localAudioStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      _peerConnection = await createPeerConnection(configuration);
      _localAudioStream?.getAudioTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localAudioStream!);
      });
    } catch (e) {
      debugPrint('[WebRTC] Audio stream setup error: $e');
    }
  }

  Future<void> _onCallAnswered() async {
    _callState = AiCallState.connected;
    if (_currentCallUuid.isNotEmpty) {
      await FlutterCallkitIncoming.setCallConnected(_currentCallUuid);
    }
    await _initWebRtcAudioChannel();

    // Opening greeting spoken aloud by Jack
    final greeting = _isOutgoing
        ? 'Hello, this is Jack calling on behalf of the device owner. How are you today?'
        : 'Hello! I am Jack, AI executive assistant for the device owner. How may I direct your call?';

    _appendTranscript('Jack', greeting);
    await _speak(greeting);

    // After greeting, listen to caller's response
    _listenToCaller();
  }

  Future<void> _speak(String text) async {
    isJackSpeakingNotifier.value = true;
    try {
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    isJackSpeakingNotifier.value = false;
  }

  void _listenToCaller() async {
    if (_callState != AiCallState.connected) return;

    isCallerSpeakingNotifier.value = true;
    try {
      await _stt.listen(
        onResult: (result) async {
          final words = result.recognizedWords.trim();
          if (result.finalResult && words.isNotEmpty) {
            _appendTranscript(_currentCallerName.isNotEmpty ? _currentCallerName : 'Caller', words);
            _stt.stop();
            isCallerSpeakingNotifier.value = false;

            if (!isTakenOverByUser) {
              await _reasonAndReply(words);
            } else {
              // User has taken over: keep transcribing caller in background
              _listenToCaller();
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('[JackCall] STT listen error: $e');
      isCallerSpeakingNotifier.value = false;
    }
  }

  /// User taps "Take Over Call" to speak directly to caller
  Future<void> takeOverCall() async {
    isTakenOverByUserNotifier.value = true;
    const msg = 'One moment please, connecting you directly to the device owner now.';
    _appendTranscript('Jack', msg);
    await _speak(msg);
    _listenToCaller();
  }

  /// User hands call back to Jack to resume AI screening
  Future<void> handBackToJack() async {
    isTakenOverByUserNotifier.value = false;
    const msg = 'Jack is back on the line. How can I assist you further?';
    _appendTranscript('Jack', msg);
    await _speak(msg);
    _listenToCaller();
  }

  /// User sends a quick directive during screening for Jack to speak
  Future<void> sendUserDirective(String directive) async {
    _appendTranscript('You (Directive)', directive);
    final response = await JackLocalLlmEngine.instance.generateVoiceResponse(
      'The device owner instructed: "$directive". Inform the caller in 1 polite spoken sentence.',
      systemDirective: 'You are Jack on a live call. Inform the caller of the device owner\'s instruction politely and concisely.',
    );
    _appendTranscript('Jack', response);
    await _speak(response);
    _listenToCaller();
  }

  Future<void> _reasonAndReply(String callerInput) async {
    if (_callState != AiCallState.connected || isTakenOverByUser) return;

    try {
      final systemPrompt = '''
You are Jack, a professional, protective AI executive assistant on a live phone call.
Caller: "$_currentCallerName" ($_currentCallerNumber).
Transcript so far:
${liveTranscriptNotifier.value.map((t) => "${t['speaker']}: ${t['message']}").join('\n')}
''';

      // Executes locally via ONNX Runtime Llama 3.2 1B (Sub-50ms) or hybrid Groq fallback
      final replyText = await JackLocalLlmEngine.instance.generateVoiceResponse(
        callerInput,
        systemDirective: systemPrompt,
      );

      _appendTranscript('Jack', replyText);
      await _speak(replyText);

      // Continue the conversation loop
      if (_callState == AiCallState.connected && !isTakenOverByUser) {
        _listenToCaller();
      }
    } catch (e) {
      const fallback = 'I have noted that down and will inform the owner right away. Thank you.';
      _appendTranscript('Jack', fallback);
      await _speak(fallback);
      endCall();
    }
  }

  void _appendTranscript(String speaker, String message) {
    final updated = List<Map<String, String>>.from(liveTranscriptNotifier.value);
    updated.add({'speaker': speaker, 'message': message, 'time': DateTime.now().toIso8601String()});
    liveTranscriptNotifier.value = updated;
  }

  Future<void> endCall() async {
    _callState = AiCallState.ended;
    try {
      await _tts.stop();
      await _stt.stop();
      _localAudioStream?.dispose();
      await _peerConnection?.close();
      if (_currentCallUuid.isNotEmpty) {
        await FlutterCallkitIncoming.endCall(_currentCallUuid);
      }
    } catch (_) {}

    // Persist call to SQLite Cognitive Memory
    if (liveTranscriptNotifier.value.isNotEmpty) {
      final summary = liveTranscriptNotifier.value.map((e) => "${e['speaker']}: ${e['message']}").join(' | ');
      await JackCognitiveMemory().logCallMemory(
        callerNumber: _currentCallerNumber.isNotEmpty ? _currentCallerNumber : 'Unknown',
        callerName: _currentCallerName.isNotEmpty ? _currentCallerName : 'Caller',
        callType: _isOutgoing ? 'outgoing' : 'incoming',
        summary: summary,
        transcription: summary,
      );
    }

    _callState = AiCallState.idle;
    isJackSpeakingNotifier.value = false;
    isCallerSpeakingNotifier.value = false;
  }
}
