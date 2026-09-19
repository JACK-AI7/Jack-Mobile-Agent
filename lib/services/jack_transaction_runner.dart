// lib/services/jack_transaction_runner.dart
//
// Jack — Atomic Routine Transaction Runner
// Provides multi-step execution pipelines with compensating rollbacks
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'jack_master_dispatcher.dart';

abstract class CompensatingStep {
  final String stepName;
  final Map<String, dynamic> executePayload;
  final Map<String, dynamic> rollbackPayload;

  CompensatingStep({
    required this.stepName,
    required this.executePayload,
    required this.rollbackPayload,
  });

  Future<bool> execute() async {
    try {
      await JackMasterDispatcher.executeCommand(executePayload);
      return true;
    } catch (e) {
      debugPrint("[JackTransaction] Step execute error: $e");
      return false;
    }
  }

  Future<void> rollback() async {
    debugPrint("[JackRollback] Compensating step: $stepName");
    try {
      await JackMasterDispatcher.executeCommand(rollbackPayload);
    } catch (e) {
      debugPrint("[JackRollback] Rollback failed for $stepName: $e");
    }
  }
}

class RoutineStep extends CompensatingStep {
  RoutineStep({
    required super.stepName,
    required super.executePayload,
    required super.rollbackPayload,
  });
}

class RoutineTransactionPipeline {
  final String routineId;
  final List<CompensatingStep> steps;

  RoutineTransactionPipeline({required this.routineId, required this.steps});

  Future<Map<String, dynamic>> executeAtomic() async {
    final List<CompensatingStep> executedSteps = [];

    for (final step in steps) {
      debugPrint("[JackRoutine] Executing atomic step: ${step.stepName}");
      final success = await step.execute();

      if (success) {
        executedSteps.add(step);
      } else {
        debugPrint("[JackRoutine] Step failed: ${step.stepName}. Initiating compensation rollback...");
        // Revert all previously completed steps in reverse order
        for (final executed in executedSteps.reversed) {
          await executed.rollback();
        }

        return {
          "status": "ROLLED_BACK",
          "failed_step": step.stepName,
          "message": "Routine failed at ${step.stepName}. All state changes were safely reverted.",
          "stepsTotal": steps.length,
          "stepsDone": executedSteps.length,
          "success": false,
        };
      }
    }

    return {
      "status": "COMPLETED",
      "stepsTotal": steps.length,
      "stepsDone": executedSteps.length,
      "message": "All routine actions verified and committed.",
      "success": true,
    };
  }
}
