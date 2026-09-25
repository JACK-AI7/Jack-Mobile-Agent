// lib/services/telephony/jack_outbound_dialing_client.dart
//
// Outbound AI Dialing Bridge for JACK Mobile Agent.
// Supports:
// 1. Direct on-device SIM calling showing native personal Caller ID at $0 cost.
// 2. Cloud Telephony Backend (Twilio / LiveKit / FastAPI) with custom Caller ID & task prompt.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'jack_ai_voice_call_engine.dart';
import '../jack_master_dispatcher.dart';
import '../memory/jack_cognitive_memory.dart';

class OutboundCallStatus {
  final String callId;
  final String recipientNumber;
  final String callerId;
  final String status; // 'initiating', 'ringing', 'in_progress', 'completed', 'failed'
  final List<Map<String, String>> transcript;

  OutboundCallStatus({
    required this.callId,
    required this.recipientNumber,
    required this.callerId,
    required this.status,
    required this.transcript,
  });
}

class JackOutboundDialingClient {
  static final JackOutboundDialingClient instance = JackOutboundDialingClient._internal();
  JackOutboundDialingClient._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  WebSocketChannel? _wsChannel;
  final ValueNotifier<OutboundCallStatus?> activeCallNotifier = ValueNotifier<OutboundCallStatus?>(null);

  /// OPTION A: Free Native On-Device SIM Dialing
  /// Uses the device's physical SIM card to call out, automatically showing the owner's personal Caller ID.
  Future<bool> dialNativeSim({
    required String recipientNumber,
    String? contactName,
    String? taskPrompt,
  }) async {
    try {
      final callId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      activeCallNotifier.value = OutboundCallStatus(
        callId: callId,
        recipientNumber: recipientNumber,
        callerId: 'Device SIM (Personal Caller ID)',
        status: 'ringing',
        transcript: [
          {'speaker': 'Jack', 'message': 'Dialing $recipientNumber via device SIM...'}
        ],
      );

      // Start CallKit & WebRTC audio bridge
      await JackAiVoiceCallEngine.instance.startOutgoingCall(
        recipientName: contactName ?? recipientNumber,
        phoneNumber: recipientNumber,
      );

      // Dispatch native Android telephony dial intent
      await JackMasterDispatcher.executeCommand({
        'intent': 'make_call',
        'params': {'target': recipientNumber},
      });

      return true;
    } catch (e) {
      debugPrint('[JackOutbound] Native SIM dial error: $e');
      return false;
    }
  }

  /// OPTION B: Cloud Telephony Backend (FastAPI / Twilio / LiveKit / Pipecat)
  /// Triggers cloud server to dial out showing verified personal Caller ID,
  /// streaming conversational turns back to the Flutter app over WebSocket.
  Future<String?> dialCloudBackend({
    required String backendUrl,
    required String recipientNumber,
    required String personalCallerId,
    required String taskPrompt,
    String? firstGreeting,
  }) async {
    try {
      final endpoint = '$backendUrl/api/dial-outbound';
      final response = await _dio.post(
        endpoint,
        data: {
          'recipient_number': recipientNumber,
          'caller_id': personalCallerId,
          'task_prompt': taskPrompt,
          'first_greeting': firstGreeting ?? 'Hello, this is Jack calling on behalf of the device owner.',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final callId = response.data['call_id']?.toString() ?? '';
        final baseWs = backendUrl.replaceFirst('http', 'ws');
        final wsUrl = response.data['ws_stream_url']?.toString() ?? '$baseWs/ws/call-stream/$callId';

        activeCallNotifier.value = OutboundCallStatus(
          callId: callId,
          recipientNumber: recipientNumber,
          callerId: personalCallerId,
          status: 'initiating',
          transcript: [],
        );

        // Connect WebSocket for real-time live transcript sync
        _connectCallStream(wsUrl, callId, recipientNumber, personalCallerId);
        return callId;
      }
    } catch (e) {
      debugPrint('[JackOutbound] Cloud backend error: $e');
    }
    return null;
  }

  void _connectCallStream(String wsUrl, String callId, String recipientNumber, String callerId) {
    try {
      _wsChannel?.sink.close();
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _wsChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString());
            final event = json['event']?.toString() ?? '';
            final speaker = json['speaker']?.toString() ?? 'Jack';
            final text = json['text']?.toString() ?? '';
            final status = json['status']?.toString() ?? 'in_progress';

            final current = activeCallNotifier.value;
            final updatedTranscript = List<Map<String, String>>.from(current?.transcript ?? []);

            if (text.isNotEmpty) {
              updatedTranscript.add({'speaker': speaker, 'message': text});
            }

            activeCallNotifier.value = OutboundCallStatus(
              callId: callId,
              recipientNumber: recipientNumber,
              callerId: callerId,
              status: status,
              transcript: updatedTranscript,
            );

            if (event == 'call_ended') {
              endCloudCall();
            }
          } catch (_) {}
        },
        onError: (err) {
          debugPrint('[JackOutbound] WS Error: $err');
        },
      );
    } catch (e) {
      debugPrint('[JackOutbound] WS connect error: $e');
    }
  }

  Future<void> endCloudCall() async {
    try {
      await _wsChannel?.sink.close();
      _wsChannel = null;

      final current = activeCallNotifier.value;
      if (current != null && current.transcript.isNotEmpty) {
        final summary = current.transcript.map((t) => "${t['speaker']}: ${t['message']}").join(' | ');
        await JackCognitiveMemory().logCallMemory(
          callerNumber: current.recipientNumber,
          callerName: 'Outbound: ${current.recipientNumber}',
          callType: 'outgoing',
          summary: summary,
          transcription: summary,
        );
      }
    } catch (_) {}
  }
}
