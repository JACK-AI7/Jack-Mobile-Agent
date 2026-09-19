// lib/services/execution_parser.dart
//
// Stateless utility that converts raw WebSocket JSON frames
// into typed OsCommand objects and agent status signals.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import '../models/agent_models.dart';

/// Result of parsing a single WebSocket frame.
class ParsedFrame {
  const ParsedFrame({
    required this.wsStatus,
    this.command,
    this.transcript,
    this.action,
    this.data,
    this.errorMessage,
  });

  /// Top-level 'status' field from the server.
  final String wsStatus;

  /// Set when wsStatus == "executing"
  final OsCommand? command;

  /// Set when wsStatus == "transcript"
  final String? transcript;

  /// Set when wsStatus == "complete"
  final String? action;
  final Map<String, dynamic>? data;

  /// Set when wsStatus == "error"
  final String? errorMessage;
}

class ExecutionParser {
  const ExecutionParser._();

  /// Parse a raw WebSocket text frame into a [ParsedFrame].
  /// Returns null if the frame is not valid JSON.
  static ParsedFrame? parse(String raw) {
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final status = j['status'] as String? ?? '';

    switch (status) {
      case 'transcript':
        return ParsedFrame(
          wsStatus:   status,
          transcript: j['text'] as String? ?? '',
        );

      case 'processing':
      case 'thinking':
        return ParsedFrame(wsStatus: 'thinking');

      case 'executing':
        return ParsedFrame(
          wsStatus: status,
          command:  OsCommand.fromJson(j),
        );

      case 'complete':
        return ParsedFrame(
          wsStatus: status,
          action:   j['action'] as String? ?? '',
          data:     j['data'] as Map<String, dynamic>? ?? {},
        );

      case 'error':
        return ParsedFrame(
          wsStatus:     status,
          errorMessage: j['message'] as String? ?? 'Unknown error',
        );

      default:
        return ParsedFrame(wsStatus: status);
    }
  }

  /// Build a human-readable status pill from an OsCommand.
  /// Examples:
  ///   intent → "Launching WhatsApp..."
  ///   click  → "Tapping Search Bar..."
  ///   type   → "Typing query..."
  static String statusPill(OsCommand cmd) => cmd.label;
}
