// ignore_for_file: constant_identifier_names
// lib/models/call_log_model.dart
//
// Represents a call Jack observed (incoming/outgoing/missed)
// with AI-generated summary of what was discussed.

class CallLogEntry {
  final String id;
  final String contactName;
  final String phoneNumber;
  final CallLogType type; // incoming / outgoing / missed
  final DateTime startTime;
  final Duration? duration;
  final String? aiSummary; // AI generated summary of the call context
  final List<String> jackActions; // things Jack did after call

  const CallLogEntry({
    required this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.type,
    required this.startTime,
    this.duration,
    this.aiSummary,
    this.jackActions = const [],
  });

  String get displayName => contactName.isNotEmpty ? contactName : phoneNumber;

  String get durationDisplay {
    if (duration == null) return '';
    final m = duration!.inMinutes;
    final s = duration!.inSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactName': contactName,
    'phoneNumber': phoneNumber,
    'type': type.name,
    'startTime': startTime.toIso8601String(),
    'duration': duration?.inSeconds,
    'aiSummary': aiSummary,
    'jackActions': jackActions,
  };

  factory CallLogEntry.fromJson(Map<String, dynamic> j) => CallLogEntry(
    id: j['id'] as String,
    contactName: j['contactName'] as String? ?? '',
    phoneNumber: j['phoneNumber'] as String? ?? '',
    type: CallLogType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => CallLogType.incoming,
    ),
    startTime: DateTime.parse(j['startTime'] as String),
    duration: j['duration'] != null
        ? Duration(seconds: j['duration'] as int)
        : null,
    aiSummary: j['aiSummary'] as String?,
    jackActions: (j['jackActions'] as List?)?.cast<String>() ?? [],
  );

  CallLogEntry copyWith({
    String? aiSummary,
    Duration? duration,
    List<String>? jackActions,
  }) => CallLogEntry(
    id: id,
    contactName: contactName,
    phoneNumber: phoneNumber,
    type: type,
    startTime: startTime,
    duration: duration ?? this.duration,
    aiSummary: aiSummary ?? this.aiSummary,
    jackActions: jackActions ?? this.jackActions,
  );
}

enum CallLogType { incoming, outgoing, missed }
