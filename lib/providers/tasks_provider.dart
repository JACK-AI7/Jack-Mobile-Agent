import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/jack_api_client.dart';
import '../models/task_model.dart';

final tasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final client = ref.read(apiClientProvider);
  return client.listTasks();
});