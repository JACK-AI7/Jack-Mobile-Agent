import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/jack_api_client.dart';
import '../models/agent/agent.dart';

final agentsProvider = FutureProvider.autoDispose<List<Agent>>((ref) async {
  final client = ref.read(apiClientProvider);
  return client.listAgents();
});

final agentDeleteProvider = FutureProvider.autoDispose.family<void, String>((ref, id) async {
  final client = ref.read(apiClientProvider);
  await client.deleteAgent(id);
});