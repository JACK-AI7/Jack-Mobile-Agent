// ignore_for_file: constant_identifier_names
// lib/models/realtime/agent_execution_state.dart
enum AgentExecutionState {
  QUEUED,
  PLANNING,
  WAITING_FOR_APPROVAL,
  RUNNING,
  WAITING_FOR_TOOL,
  PAUSED,
  COMPLETED,
  FAILED,
  CANCELLED,
  UNKNOWN
}

AgentExecutionState parseExecutionState(String state) {
  return AgentExecutionState.values.firstWhere(
    (e) => e.name == state,
    orElse: () => AgentExecutionState.UNKNOWN,
  );
}
