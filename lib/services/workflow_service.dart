// lib/services/workflow_service.dart
//
// Fire-and-forget n8n webhook dispatcher.
// Never blocks the Flutter UI thread.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:dio/dio.dart';

class WorkflowService {
  static const String _base = 'http://localhost:5678/webhook';

  static const Map<String, String> _routes = {
    'bus_search'       : '$_base/bus-search',
    'book_ticket'      : '$_base/book-ticket',
    'schedule_meeting' : '$_base/schedule-meeting',
    'generate_image'   : '$_base/generate-image',
    'create_document'  : '$_base/create-document',
    'write_note'       : '$_base/write-note',
    'web_search'       : '$_base/web-search',
    'os_action'        : '$_base/os-action',
  };

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  /// Dispatch and forget — intentionally not awaited.
  void dispatch(String action, Map<String, dynamic> data) {
    final url = _routes[action] ?? '$_base/generic';
    _post(url, action, data);
  }

  Future<void> _post(
      String url, String action, Map<String, dynamic> data) async {
    try {
      await _dio.post(url,
          data: jsonEncode({
            'action': action,
            'timestamp': DateTime.now().toIso8601String(),
            'data': data,
          }));
    } catch (_) {/* non-fatal */}
  }
}
