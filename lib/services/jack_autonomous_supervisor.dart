// lib/services/jack_autonomous_supervisor.dart
//
// Jack — State-Verification & Self-Healing Loop (Closed-Loop Trajectory)
// Perceive → Act → Verify architecture with automatic popup/modal recovery
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'jack_controller.dart';

class JackAutonomousSupervisor {
  JackAutonomousSupervisor._();

  static const int maxRetries = 3;

  /// Common system / promo modal dismiss labels
  static const List<String> commonDismissers = [
    "Not now",
    "Not Now",
    "Skip",
    "Close",
    "Cancel",
    "Dismiss",
    "Later",
    "Maybe later",
    "No thanks",
    "Accept all",
    "Continue",
    "Allow",
    "OK",
  ];

  /// Executes a goal with automatic self-healing, stall recovery, and state verification.
  static Future<bool> executeWithVerification({
    required String goalDescription,
    required Future<bool> Function() action,
    required Future<bool> Function() verifySuccess,
    Duration settleDuration = const Duration(milliseconds: 650),
  }) async {
    debugPrint('[JackSupervisor] Beginning verified task: "$goalDescription"');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('[JackSupervisor] Attempt $attempt of $maxRetries for "$goalDescription"');

      // 1. Execute action
      final executed = await action();
      if (!executed) {
        debugPrint('[JackSupervisor] Action execution failed on attempt $attempt, handling stall...');
        await handleStall(attempt);
        continue;
      }

      // 2. Wait for UI animation/transition to settle
      await Future.delayed(settleDuration);

      // 3. Verify if target state was achieved
      final isVerified = await verifySuccess();
      if (isVerified) {
        debugPrint('[JackSupervisor] State verified for "$goalDescription" on attempt $attempt');
        return true; // Step succeeded
      }

      // 4. Self-heal: Dismiss unexpected dialogs, soft keyboard, or back-press if stuck
      debugPrint('[JackSupervisor] State not verified, running self-healing sequence...');
      await dismissUnexpectedModals();
      await Future.delayed(const Duration(milliseconds: 350));

      // Re-verify after dismiss
      if (await verifySuccess()) {
        return true;
      }

      await handleStall(attempt);
    }

    debugPrint('[JackSupervisor] Exceeded max retries ($maxRetries) for "$goalDescription"');
    return false; // Escalate to user or planner
  }

  /// Handles stalled UI state by dismissing keyboard or nudging scroll
  static Future<void> handleStall(int attempt) async {
    // Attempt 1: Dismiss soft keyboard with BACK
    await JackController.triggerGlobal("BACK");
    await Future.delayed(const Duration(milliseconds: 300));

    if (attempt >= 2) {
      // Attempt 2+: Nudge scroll up slightly to reveal hidden clickable controls
      await JackController.swipe(
        startX: 540,
        startY: 1400,
        endX: 540,
        endY: 1000,
        durationMs: 250,
      );
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  /// Scans active screen for common popup dismissers and taps the first found
  static Future<bool> dismissUnexpectedModals() async {
    for (final text in commonDismissers) {
      final clicked = await JackController.clickElement(text: text);
      if (clicked) {
        debugPrint('[JackSupervisor] Auto-dismissed blocker modal with "$text"');
        await Future.delayed(const Duration(milliseconds: 400));
        return true;
      }
    }
    return false;
  }

  /// Takes an instantaneous snapshot hash of the screen elements
  static Future<int> getScreenContentHash() async {
    try {
      final nodes = await JackController.inspectScreen();
      final texts = nodes
          .map((n) => '${n['id']}:${n['text']}')
          .where((s) => s.length > 1)
          .join('|');
      return texts.hashCode;
    } catch (_) {
      return 0;
    }
  }
}
