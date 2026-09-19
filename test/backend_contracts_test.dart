import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/agent/jack_agent_request.dart';
import '../lib/models/realtime/socket_events.dart';
import '../lib/models/realtime/jack_orb_state.dart';

void main() {
  group('Backend Contracts', () {
    test('JackAgentRequest serialization', () {
      final req = JackAgentRequest(requestId: '123', message: 'Hello', agentId: 'agent-1');
      final json = req.toJson();
      expect(json['requestId'], '123');
      expect(json['message'], 'Hello');
      expect(json['agentId'], 'agent-1');
    });

    test('JackAgentResponse deserialization', () {
      final json = {
        'executionId': 'exec-1',
        'agentId': 'agent-1',
        'status': 'COMPLETED',
        'result': 'I did it.',
      };
      final res = JackAgentResponse.fromJson(json);
      expect(res.executionId, 'exec-1');
      expect(res.status, 'COMPLETED');
      expect(res.result, 'I did it.');
    });

    test('AgentToolStartedEvent deserialization', () {
      final json = {
        'executionId': 'exec-1',
        'toolName': 'calculator',
        'toolDescription': 'calculating...',
      };
      final event = AgentToolStartedEvent.fromJson(json);
      expect(event.toolName, 'calculator');
    });

    test('JackOrbState parses correctly', () {
      expect(parseOrbState('IDLE'), JackOrbState.IDLE);
      expect(parseOrbState('WAITING_FOR_APPROVAL'), JackOrbState.WAITING_FOR_APPROVAL);
      expect(parseOrbState('UNKNOWN_GARBAGE'), JackOrbState.IDLE);
    });
  });
}
