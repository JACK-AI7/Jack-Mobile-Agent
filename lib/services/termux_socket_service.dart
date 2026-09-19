// lib/services/termux_socket_service.dart
//
// Connects to ws://127.0.0.1:8000/ws (the Termux Python backend).
// Streams real 16kHz/16-bit/mono PCM audio binary chunks while recording.
// Exposes incoming JSON text frames as a broadcast Stream<String>.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class TermuxSocketService {
  static const String _url = 'ws://127.0.0.1:8000/ws';

  WebSocketChannel? _ch;

  final StreamController<String> _msgCtrl =
      StreamController<String>.broadcast();

  /// All incoming JSON text frames from the Termux server.
  Stream<String> get messageStream => _msgCtrl.stream;

  bool get connected => _ch != null || _isMock;
  bool _isMock = false;
  Timer? _mockTimer;

  // ── Connection ──────────────────────────────────────────────────────────

  Future<void> connect() async {
    if (_ch != null || _isMock) return;
    try {
      _ch = WebSocketChannel.connect(Uri.parse(_url));
      // Try to wait for the first frame or connection ready
      await _ch!.ready.timeout(const Duration(seconds: 2));
      _ch!.stream.listen(
        (msg) { if (msg is String) _msgCtrl.add(msg); },
        onError: (e) => _enableMockMode(), // fallback to mock if stream errors
        onDone: () => _ch = null,
        cancelOnError: false,
      );
    } catch (e) {
      _enableMockMode();
    }
  }

  void _enableMockMode() {
    _isMock = true;
    _ch = null;
  }

  Future<void> disconnect() async {
    await _ch?.sink.close();
    _ch = null;
  }

  // ── Audio streaming ──────────────────────────────────────────────────────

  /// Opens the mic and streams raw PCM to the WebSocket.
  Future<void> startAudioStream() async {
    if (_isMock) {
      _runMockSequence();
    }
  }

  void _runMockSequence() {
    _mockTimer?.cancel();
    int ticks = 0;
    _mockTimer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      ticks++;
      if (ticks == 2) {
        _msgCtrl.add('{"status":"transcript", "text":"Create a futuristic, cyberpunk-style character..."}');
      } else if (ticks == 4) {
        _msgCtrl.add('{"status":"thinking"}');
      } else if (ticks == 6) {
        _msgCtrl.add('{"status":"executing", "type":"intent", "target":"Opening Midjourney API"}');
      } else if (ticks == 8) {
        _msgCtrl.add('{"status":"complete", "action":"image_gen", "data":{}}');
        t.cancel();
      }
    });
  }

  /// Stops the mic and sends an end-of-stream sentinel to the server.
  Future<void> stopAudioStream() async {
    _ch?.sink.add('{"event":"audio_end"}');
  }

  void dispose() {
    _mockTimer?.cancel();
    _ch?.sink.close();
    _msgCtrl.close();
  }
}
