// ignore_for_file: constant_identifier_names
// lib/models/agent/jack_agent_request.dart
class JackAgentRequest {
  final String requestId;
  final String message;
  final String? agentId;
  final String? conversationId;

  JackAgentRequest({
    required this.requestId,
    required this.message,
    this.agentId,
    this.conversationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'message': message,
      if (agentId != null) 'agentId': agentId,
      if (conversationId != null) 'conversationId': conversationId,
    };
  }
}

class JackAgentResponse {
  final String executionId;
  final String agentId;
  final String status;
  final String? result;
  final String? error;

  JackAgentResponse({
    required this.executionId,
    required this.agentId,
    required this.status,
    this.result,
    this.error,
  });

  factory JackAgentResponse.fromJson(Map<String, dynamic> json) {
    return JackAgentResponse(
      executionId: json['executionId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      status: json['status'] as String? ?? 'QUEUED',
      result: json['result'] as String?,
      error: json['error'] as String?,
    );
  }
}
