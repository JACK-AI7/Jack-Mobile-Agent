import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jack/screens/tasks_screen.dart';
import 'package:jack/providers/tasks_provider.dart';
import 'package:jack/models/task_model.dart';

void main() {
  testWidgets('TasksScreen renders correctly with empty data', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith((ref) => Future.value(<TaskModel>[])),
        ],
        child: const MaterialApp(
          home: TasksScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify header exists (appears in title only, nav bar shows 'Tasks' too)
    expect(find.text('Tasks'), findsWidgets);

    // Verify subtitle
    expect(find.textContaining('Track what Jack is working on'), findsOneWidget);

    // Verify filters
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // Verify seed tasks are shown when backend returns empty
    expect(find.text('Laptop research'), findsOneWidget);
    expect(find.text('Summarize article'), findsOneWidget);
  });
}
