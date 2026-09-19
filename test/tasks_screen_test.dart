// test/tasks_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack/screens/tasks_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasksScreen Widget Tests', () {
    testWidgets('TasksScreen renders header, subtitle, and filter tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: TasksScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify header and subtitle
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Track what Jack is working on.'), findsOneWidget);

      // Verify filter segmented controls
      expect(find.byKey(const Key('filter_all')), findsOneWidget);
      expect(find.byKey(const Key('filter_running')), findsOneWidget);
      expect(find.byKey(const Key('filter_completed')), findsOneWidget);

      // Verify sample task titles are present
      expect(find.text('Laptop research'), findsOneWidget);
      expect(find.text('Summarize article'), findsOneWidget);
      expect(find.text('Create presentation'), findsOneWidget);
      expect(find.text('Analyze dataset'), findsOneWidget);
      expect(find.text('Plan vacation'), findsOneWidget);

      // Verify status badges
      expect(find.text('In progress'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);

      // Verify timeline steps for initially expanded task (Laptop research)
      expect(find.text('Understanding request ✓'), findsWidgets);
      expect(find.text('Planning ✓'), findsWidgets);
      expect(find.text('Searching ●'), findsWidgets);
      expect(find.text('Analyzing ○'), findsWidgets);
      expect(find.text('Preparing answer ○'), findsWidgets);
    });

    testWidgets('Filtering by Running displays only in-progress tasks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TasksScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Running' tab
      await tester.tap(find.byKey(const Key('filter_running')));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Laptop research'), findsOneWidget);
      expect(find.text('Analyze dataset'), findsOneWidget);
      expect(find.text('Summarize article'), findsNothing);
      expect(find.text('Create presentation'), findsNothing);
      expect(find.text('Plan vacation'), findsNothing);
    });

    testWidgets('Filtering by Completed displays only completed tasks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: TasksScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Completed' filter tab
      await tester.tap(find.byKey(const Key('filter_completed')));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Summarize article'), findsOneWidget);
      expect(find.text('Create presentation'), findsOneWidget);
      expect(find.text('Plan vacation'), findsOneWidget);
      expect(find.text('Laptop research'), findsNothing);
      expect(find.text('Analyze dataset'), findsNothing);
    });

    testWidgets('Tapping a task expands/collapses execution timeline steps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TasksScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Laptop research starts expanded. Tap it to collapse.
      await tester.tap(find.text('Laptop research'));
      await tester.pump(const Duration(milliseconds: 250));

      // Should no longer find timeline steps
      expect(find.text('Searching ●'), findsNothing);

      // Tap it again to expand
      await tester.tap(find.text('Laptop research'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Searching ●'), findsOneWidget);
    });
  });
}
