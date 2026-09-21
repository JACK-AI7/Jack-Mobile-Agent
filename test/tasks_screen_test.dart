import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/screens/tasks_screen.dart';
import '../lib/providers/tasks_provider.dart';
import '../lib/models/task_model.dart';

void main() {
  testWidgets('TasksScreen renders correctly with empty data', (WidgetTester tester) async {
    // Provide a mocked empty list
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith((ref) => Future.value(<TaskModel>[])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TasksScreen()),
        ),
      ),
    );

    // Wait for the FutureProvider to resolve
    await tester.pumpAndSettle();

    // Verify header exists
    expect(find.text('Tasks'), findsOneWidget);
    
    // Verify subtitle
    expect(find.text('Track what Jack is working on'), findsOneWidget);
    
    // Verify filters
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Verify empty state message
    expect(find.textContaining('No tasks'), findsWidgets);
  });
}
