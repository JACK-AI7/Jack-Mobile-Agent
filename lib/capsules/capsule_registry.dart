// lib/capsules/capsule_registry.dart
//
// Jack — Central Bixby Capsule Registry
// Registers and dispatches actions to the appropriate Bixby capsule.
// ─────────────────────────────────────────────────────────────────────────────
import 'core_models.dart';
import 'system_control_capsule.dart';
import 'alarm_capsule.dart';
import 'communication_capsule.dart';
import 'media_capsule.dart';
import 'routine_capsule.dart';

class JackCapsuleRegistry {
  static final Map<String, JackCapsule> _registry = {};

  /// Bootstraps the capsule library. Call once at app startup.
  static void initialize() {
    register(systemControlCapsule);
    register(alarmCapsule);
    register(communicationCapsule);
    register(mediaCapsule);
    register(routineCapsule);
  }

  static void register(JackCapsule capsule) {
    _registry[capsule.capsuleId] = capsule;
  }

  /// Resolves an action name to its endpoint and returns a unified CapsuleDispatchResult
  /// containing the executed data and the BixbyViewTemplate to render.
  static Future<CapsuleDispatchResult?> dispatch({
    required String actionName,
    required Map<String, dynamic> inputs,
    String? preferredCapsuleId,
  }) async {
    JackCapsule? targetCapsule;

    if (preferredCapsuleId != null && _registry.containsKey(preferredCapsuleId)) {
      targetCapsule = _registry[preferredCapsuleId];
    } else {
      // Find the first capsule that has this action
      for (final capsule in _registry.values) {
        if (capsule.actions.any((a) => a.name == actionName)) {
          targetCapsule = capsule;
          break;
        }
      }
    }

    if (targetCapsule == null) return null;

    final actionModel = targetCapsule.actions.firstWhere(
      (a) => a.name == actionName,
      orElse: () => targetCapsule!.actions.first,
    );

    final endpoint = targetCapsule.endpoints[actionName];
    Map<String, dynamic> executionResult = {};
    if (endpoint != null) {
      executionResult = await endpoint(inputs);
    }

    BixbyViewTemplate? viewTemplate;

    if (executionResult['status'] == 'AWAITING_INPUT') {
      viewTemplate = BixbyViewTemplate(
        targetConcept: executionResult['target_concept'] ?? 'Input',
        viewType: ViewType.inputView,
        dialogTemplate: executionResult['dialog_template'] ?? 'Please select an option',
        speechTemplate: executionResult['dialog_template'] ?? 'Please select an option',
        layout: [], // Handled by BixbyInputViewRenderer
        inputOptions: [
          // We will pass the raw options inside the executionResult so the widget can read them
        ],
        conversationDrivers: [
          const ConversationDriver(template: 'Cancel', query: 'Cancel')
        ]
      );
    } else {
      // Resolve matching view template based on the action's output concept
      viewTemplate = targetCapsule.views.firstWhere(
        (v) => v.targetConcept == actionModel.outputConcept,
        orElse: () => targetCapsule!.views.first,
      );
    }

    return CapsuleDispatchResult(
      capsuleId: targetCapsule.capsuleId,
      actionName: actionName,
      result: executionResult,
      viewTemplate: viewTemplate,
      speechText: viewTemplate.speechTemplate,
      dialogText: viewTemplate.dialogTemplate,
    );
  }
}
