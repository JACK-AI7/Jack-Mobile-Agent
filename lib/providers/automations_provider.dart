import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/jack_api_client.dart';
import '../models/automation_model.dart';

final automationsProvider = FutureProvider.autoDispose<List<AutomationModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  return client.listAutomations();
});