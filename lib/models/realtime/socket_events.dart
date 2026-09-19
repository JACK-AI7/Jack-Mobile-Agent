// lib/models/realtime/socket_events.dart
export 'jack_orb_state.dart';

class AgentRealtimeEvent {
  final String jobId;
  final String? agentId;
  final String? taskId;
  final String timestamp;

  AgentRealtimeEvent({
    required this.jobId,
    this.agentId,
    this.taskId,
    required this.timestamp,
  });

  factory AgentRealtimeEvent.fromJson(Map<String, dynamic> json) {
    return AgentRealtimeEvent(
      jobId: json['jobId'] as String? ?? '',
      agentId: json['agentId'] as String?,
      taskId: json['taskId'] as String?,
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class AgentToolStartedEvent extends AgentRealtimeEvent {
  final String toolName;
  final String toolDescription;

  AgentToolStartedEvent({
    required super.jobId,
    super.agentId,
    super.taskId,
    required super.timestamp,
    required this.toolName,
    required this.toolDescription,
  });

  factory AgentToolStartedEvent.fromJson(Map<String, dynamic> json) {
    return AgentToolStartedEvent(
      jobId: json['jobId'] as String? ?? '',
      agentId: json['agentId'] as String?,
      taskId: json['taskId'] as String?,
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      toolName: json['toolName'] as String? ?? 'Unknown Tool',
      toolDescription: json['toolDescription'] as String? ?? '',
    );
  }
}
