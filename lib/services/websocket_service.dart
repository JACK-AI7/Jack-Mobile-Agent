// lib/services/websocket_service.dart
//
// Connects to the Termux Python backend at ws://127.0.0.1:8000/ws/audio.
// Streams raw PCM audio bytes and emits server messages as Strings.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<String>.broadcast();

  /// Stream of raw text frames from the server (JSON).
  Stream<String> get messageStream => _messageController.stream;

  bool get isConnected => _channel != null;

  // ── Connection ──────────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_channel != null) return; // already connected

    _channel = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:8000/ws/audio'),
    );

    _channel!.stream.listen(
      (message) {
        if (message is String) {
          _messageController.add(message);
        }
      },
      onError: (e) => _messageController.addError(e),
      onDone: () {
        _channel = null; // server closed connection
      },
      cancelOnError: false,
    );
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  // ── Audio Streaming ─────────────────────────────────────────────────────────

  /// Streams raw PCM chunk to the WebSocket server.
  void sendAudioChunk(Uint8List chunk) {
    if (_channel != null) {
      _channel!.sink.add(chunk);
    }
  }

  /// Signal to the server that the audio stream is complete.
  void sendAudioEnd() {
    _channel?.sink.add('{"event":"audio_end"}');
  }

  /// Starts audio streaming (for API backward compatibility).
  Future<void> startAudioStream() async {}

  /// Stops audio streaming (for API backward compatibility).
  Future<void> stopAudioStream() async {
    sendAudioEnd();
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
  }
}
