// lib/services/action_handler.dart
//
// Routes completed agent intents to the appropriate handler.
// Heavy/multi-step logic is delegated to n8n webhook URLs so the
// Flutter UI thread is never blocked.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:dio/dio.dart';

class ActionHandler {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // ── n8n webhook base URL (override via environment or settings) ─────────────
  static const String _n8nBase = 'http://localhost:5678/webhook';

  // Webhook endpoints per intent action
  static const Map<String, String> _webhookRoutes = {
    'bus_search': '$_n8nBase/bus-search',
    'book_ticket': '$_n8nBase/book-ticket',
    'schedule_meeting': '$_n8nBase/schedule-meeting',
    'generate_image': '$_n8nBase/generate-image',
    'create_document': '$_n8nBase/create-document',
    'write_note': '$_n8nBase/write-note',
    'web_search': '$_n8nBase/web-search',
  };

  /// Called by AgentStateNotifier whenever the server returns action=complete.
  /// Fires-and-forgets – does NOT await or block the UI thread.
  void handle(String action, Map<String, dynamic> data) {
    final url = _webhookRoutes[action];
    if (url == null) return; // unknown action, skip

    _fireWebhook(url, action, data); // intentionally not awaited
  }

  Future<void> _fireWebhook(
    String url,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      final payload = jsonEncode({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      });

      await _dio.post(url, data: payload);
    } catch (_) {
      // Webhook delivery failure is non-fatal — the agent keeps running.
      // In production, retry logic / local queue can be added here.
    }
  }

  /// Directly send a custom structured payload to a specific n8n webhook.
  Future<bool> sendCustomPayload(
    String webhookPath,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '$_n8nBase/$webhookPath';
      await _dio.post(url, data: jsonEncode(payload));
      return true;
    } catch (_) {
      return false;
    }
  }
}
