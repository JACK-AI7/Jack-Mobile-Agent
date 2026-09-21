import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/realtime/socket_events.dart';

final realtimeClientProvider = Provider((ref) => JackRealtimeClient());

class JackRealtimeClient {
  io.Socket? _socket;
  
  final _orbStateController = StreamController<JackOrbState>.broadcast();
  final _toolStateController = StreamController<AgentToolStartedEvent>.broadcast();
  final _approvalRequestController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<JackOrbState> get orbStateStream => _orbStateController.stream;
  Stream<AgentToolStartedEvent> get toolStateStream => _toolStateController.stream;
  Stream<Map<String, dynamic>> get approvalRequestStream => _approvalRequestController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String url, String token) {
    if (_socket != null) return;

    _socket = io.io(url, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .build()
    );

    _socket!.onConnect((_) {
      debugPrint('JackRealtimeClient: Connected to backend');
      _orbStateController.add(JackOrbState.IDLE);
    });

    _socket!.onDisconnect((_) {
      debugPrint('JackRealtimeClient: Disconnected');
      _orbStateController.add(JackOrbState.OFFLINE);
    });

    // Handle Orb State transitions (legacy event name)
    _socket!.on('orb_state', (data) {
      if (data is Map<String, dynamic> && data['state'] != null) {
        final parsedState = parseOrbState(data['state'].toString());
        _orbStateController.add(parsedState);
      }
    });

    // Handle Orb State transitions (canonical backend event name)
    _socket!.on('agent.state', (data) {
      if (data is Map<String, dynamic> && data['state'] != null) {
        final parsedState = parseOrbState(data['state'].toString());
        _orbStateController.add(parsedState);
      }
    });

    // Handle strongly typed Tool Execution events
    _socket!.on('agent.tool.started', (data) {
      if (data is Map<String, dynamic>) {
        try {
          final event = AgentToolStartedEvent.fromJson(data);
          _toolStateController.add(event);
        } catch (e) {
          debugPrint('Failed to parse agent.tool.started payload: $e');
        }
      }
    });

    _socket!.on('agent.approval.required', (data) {
      if (data is Map<String, dynamic>) {
        _approvalRequestController.add(data);
      }
    });

    _socket!.connect();
  }

  /// Re-connects using a fresh token. If a socket already exists it is torn
  /// down first so the new auth token is applied correctly.
  void reconnect(String url, String token) {
    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }
    connect(url, token);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _orbStateController.add(JackOrbState.OFFLINE);
  }

  void dispose() {
    disconnect();
    _orbStateController.close();
    _toolStateController.close();
  }
}
