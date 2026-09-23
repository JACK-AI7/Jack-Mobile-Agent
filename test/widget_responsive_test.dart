import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jack/screens/splash_screen.dart';
import 'package:jack/screens/home_screen.dart';
import 'package:jack/screens/autonomy_screen.dart';
import 'package:jack/screens/agent_builder_screen.dart';
import 'package:jack/screens/automations_screen.dart';
import 'package:jack/screens/chat_screen.dart';
import 'package:jack/screens/tools_screen.dart';
import 'package:jack/screens/library_screen.dart';
import 'package:jack/screens/tasks_screen.dart';
import 'package:jack/screens/profile_screen.dart';
import 'package:jack/screens/upgrade_screen.dart';
import 'package:jack/screens/more_screen.dart';

void main() {
  const viewports = [
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
  ];

  for (final size in viewports) {
    group('Screen Responsive Verification on ${size.width}x${size.height}', () {
      Widget buildTestHarness(Widget child) {
        return ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        );
      }

      testWidgets('01 Splash renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const SplashScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('JACK'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('02 Home renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const HomeScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('JACK AGENT'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('03 Autonomy renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const AutonomyScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Agent Autonomy'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('04 Builder renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const BuilderScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('Build how your'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('05 Automations renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const AutomationsScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Automations'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('06 Chat renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const ChatScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Chat'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('07 Tools renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const ToolsScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Tools'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('08 Library renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const LibraryScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Library'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('09 Tasks renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const TasksScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Tasks'), findsWidgets); // title + nav bar label
        expect(tester.takeException(), isNull);
      });

      testWidgets('10 Profile renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const ProfileScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Profile'), findsWidgets); // title + nav bar label
        expect(tester.takeException(), isNull);
      });

      testWidgets('11 Upgrade renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const UpgradeScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Upgrade'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('12 More renders cleanly', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(buildTestHarness(const MoreScreen()));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('More'), findsWidgets); // title + nav bar label
        expect(tester.takeException(), isNull);
      });
    });
  }
}
