// test/overlay_and_screener_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack/services/overlay/jack_floating_overlay_controller.dart';
import 'package:jack/services/tasks/jack_task_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JackFloatingOverlayNotifier & Snap Grid Tests', () {
    test('Initial overlay state matches specifications', () {
      final notifier = JackFloatingOverlayNotifier();
      expect(notifier.state.isVisible, isTrue);
      expect(notifier.state.isExpanded, isFalse);
      expect(notifier.state.isListening, isTrue);
      expect(notifier.state.statusText, 'Listening...');
      notifier.dispose();
    });

    test('Computes 6 distinct snap anchors along screen edges', () {
      const screenSize = Size(390, 844);
      const safeArea = EdgeInsets.only(top: 44, bottom: 34);
      final anchors = JackFloatingOverlayNotifier.computeSnapAnchors(
        screenSize: screenSize,
        safeArea: safeArea,
        bubbleSize: 62.0,
      );

      expect(anchors.length, 6);
      // Top-Left & Top-Right
      expect(anchors[0].dx, 16.0);
      expect(anchors[1].dx, greaterThan(300.0));
      // Middle-Left & Middle-Right
      expect(anchors[2].dx, 16.0);
      expect(anchors[3].dx, greaterThan(300.0));
      // Bottom-Left & Bottom-Right
      expect(anchors[4].dx, 16.0);
      expect(anchors[5].dx, greaterThan(300.0));

      // Y coordinates monotonic top -> mid -> bottom
      expect(anchors[0].dy, lessThan(anchors[2].dy));
      expect(anchors[2].dy, lessThan(anchors[4].dy));
    });

    test('Pan and snap logic selects nearest anchor', () {
      final notifier = JackFloatingOverlayNotifier();
      const screenSize = Size(390, 844);
      const safeArea = EdgeInsets.only(top: 44, bottom: 34);

      notifier.onPanStart();
      expect(notifier.state.isDragging, isTrue);

      // Drag close to top-left
      notifier.onPanUpdate(const Offset(-200, -200), screenSize, safeArea, 62.0);
      notifier.onPanEnd(screenSize, safeArea, 62.0);

      expect(notifier.state.isDragging, isFalse);
      expect(notifier.state.snapGridIndex, 0); // Top-Left
      notifier.dispose();
    });

    test('Drag into dismiss zone dismisses overlay', () {
      final notifier = JackFloatingOverlayNotifier();
      const screenSize = Size(390, 844);
      const safeArea = EdgeInsets.only(top: 44, bottom: 34);

      final dismissCenter = JackFloatingOverlayNotifier.computeDismissCenter(
        screenSize: screenSize,
        safeArea: safeArea,
      );

      // Force position directly onto dismiss center
      notifier.onPanStart();
      notifier.onPanUpdate(
        Offset(dismissCenter.dx - notifier.state.bubblePosition.dx - 31,
            dismissCenter.dy - notifier.state.bubblePosition.dy - 31),
        screenSize,
        safeArea,
        62.0,
      );

      expect(notifier.state.isInDismissZone, isTrue);

      notifier.onPanEnd(screenSize, safeArea, 62.0);
      expect(notifier.state.isVisible, isFalse);
      notifier.dispose();
    });

    test('Minimize triggers explanatory system prompt', () {
      final notifier = JackFloatingOverlayNotifier();
      notifier.expand();
      expect(notifier.state.isExpanded, isTrue);

      notifier.minimize();
      expect(notifier.state.isExpanded, isFalse);
      expect(notifier.state.showExplanatoryPrompt, isTrue);
      notifier.dispose();
    });
  });

  group('JackTaskService Model Tests', () {
    test('JackTaskItem serialization and status labeling', () {
      final item = JackTaskItem(
        id: 'test_1',
        title: 'Screened Call: Alex',
        description: 'Test voice call screening',
        status: JackTaskStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        completedAt: DateTime.now(),
        resultSummary: 'Call screened successfully',
        category: 'Telephony',
      );

      final json = item.toJson();
      final roundtrip = JackTaskItem.fromJson(json);

      expect(roundtrip.id, 'test_1');
      expect(roundtrip.isDone, isTrue);
      expect(roundtrip.category, 'Telephony');
      expect(roundtrip.statusLabel, contains('Completed • 5 min ago'));
    });
  });
}
