// lib/models/realtime/jack_orb_state.dart
enum JackOrbState {
  IDLE,
  LISTENING,
  THINKING,
  PLANNING,
  EXECUTING,
  SEARCHING,
  USING_TOOL,
  WAITING_FOR_USER,
  WAITING_FOR_APPROVAL,
  SPEAKING,
  SUCCESS,
  ERROR,
  OFFLINE,
  SLEEPING,
  WAKE
}

JackOrbState parseOrbState(String state) {
  return JackOrbState.values.firstWhere(
    (e) => e.name == state,
    orElse: () => JackOrbState.IDLE,
  );
}
