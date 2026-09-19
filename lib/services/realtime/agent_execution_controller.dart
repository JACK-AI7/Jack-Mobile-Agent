import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/realtime/jack_orb_state.dart';
import '../../models/realtime/socket_events.dart';
import '../../config/environment.dart';
import 'jack_realtime_client.dart';

class AgentRealtimeState {
  final JackOrbState orbState;
  final String? currentToolName;
  final String? currentToolDescription;
  final dynamic approvalRequest;

  AgentRealtimeState({
    required this.orbState,
    this.currentToolName,
    this.currentToolDescription,
    this.approvalRequest,
  });

  AgentRealtimeState copyWith({
    JackOrbState? orbState,
    String? currentToolName,
    String? currentToolDescription,
    dynamic approvalRequest,
  }) {
    return AgentRealtimeState(
      orbState: orbState ?? this.orbState,
      currentToolName: currentToolName ?? this.currentToolName,
      currentToolDescription: currentToolDescription ?? this.currentToolDescription,
      approvalRequest: approvalRequest ?? this.approvalRequest,
    );
  }
}

class AgentExecutionController extends StateNotifier<AgentRealtimeState> {
  final JackRealtimeClient _realtimeClient;

  AgentExecutionController(this._realtimeClient) 
      : super(AgentRealtimeState(orbState: JackOrbState.OFFLINE)) {
    
    _realtimeClient.orbStateStream.listen((orbState) {
      state = state.copyWith(orbState: orbState);
    });

    _realtimeClient.toolStateStream.listen((toolEvent) {
      state = state.copyWith(
        orbState: JackOrbState.USING_TOOL,
        currentToolName: toolEvent.toolName,
        currentToolDescription: toolEvent.toolDescription,
      );
    });

    _realtimeClient.approvalRequestStream.listen((data) {
      state = state.copyWith(
        orbState: JackOrbState.WAITING_FOR_APPROVAL,
        approvalRequest: data,
      );
    });
  }

  void connect(String token) {
    _realtimeClient.connect(EnvironmentConfig.apiUrl, token);
  }

  void disconnect() {
    _realtimeClient.disconnect();
  }
}

final agentExecutionProvider = StateNotifierProvider<AgentExecutionController, AgentRealtimeState>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return AgentExecutionController(client);
});
