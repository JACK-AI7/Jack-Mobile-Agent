// lib/models/bixby_routine_model.dart
//
// Jack — Multi-Action "Quick Commands" Engine (Bixby Macros)
// Binds short trigger phrases to ordered sequential action pipelines.
// ─────────────────────────────────────────────────────────────────────────────

class QuickCommand {
  final String triggerPhrase;
  final List<JackActionStep> steps;

  const QuickCommand({
    required this.triggerPhrase,
    required this.steps,
  });
}

class JackActionStep {
  final String subsystem; // "settings", "media", "apps", "telecom", "clock", "maintenance", "display"
  final String action;
  final Map<String, dynamic> params;

  const JackActionStep({
    required this.subsystem,
    required this.action,
    required this.params,
  });
}

/// Default Presets built into Jack
final Map<String, QuickCommand> builtInBixbyMacros = {
  "good night": const QuickCommand(
    triggerPhrase: "good night",
    steps: [
      JackActionStep(subsystem: "settings", action: "DO_NOT_DISTURB", params: {"state": true}),
      JackActionStep(subsystem: "display", action: "SET_BRIGHTNESS", params: {"level": 10}),
      JackActionStep(subsystem: "clock", action: "SET_ALARM", params: {"time": "07:00", "label": "Morning"}),
      JackActionStep(subsystem: "settings", action: "BLUETOOTH", params: {"state": false}),
      JackActionStep(subsystem: "hardware", action: "TOGGLE_FLASHLIGHT", params: {"state": false}),
    ],
  ),
  "bedtime": const QuickCommand(
    triggerPhrase: "bedtime",
    steps: [
      JackActionStep(subsystem: "settings", action: "DO_NOT_DISTURB", params: {"state": true}),
      JackActionStep(subsystem: "media", action: "SET_VOLUME", params: {"level": 0, "stream": "media"}),
      JackActionStep(subsystem: "clock", action: "SET_ALARM", params: {"time": "07:00", "label": "Morning"}),
      JackActionStep(subsystem: "hardware", action: "TOGGLE_FLASHLIGHT", params: {"state": false}),
    ],
  ),
  "good morning": const QuickCommand(
    triggerPhrase: "good morning",
    steps: [
      JackActionStep(subsystem: "settings", action: "DO_NOT_DISTURB", params: {"state": false}),
      JackActionStep(subsystem: "media", action: "SET_VOLUME", params: {"level": 70, "stream": "media"}),
      JackActionStep(subsystem: "display", action: "SET_BRIGHTNESS", params: {"level": 75}),
      JackActionStep(subsystem: "settings", action: "BLUETOOTH", params: {"state": true}),
    ],
  ),
  "i'm driving": const QuickCommand(
    triggerPhrase: "i'm driving",
    steps: [
      JackActionStep(subsystem: "settings", action: "BLUETOOTH", params: {"state": true}),
      JackActionStep(subsystem: "settings", action: "DO_NOT_DISTURB", params: {"state": true}),
      JackActionStep(subsystem: "apps", action: "LAUNCH_PACKAGE", params: {"pkg": "com.google.android.apps.maps"}),
      JackActionStep(subsystem: "media", action: "SET_VOLUME", params: {"level": 85, "stream": "media"}),
    ],
  ),
  "optimize device": const QuickCommand(
    triggerPhrase: "optimize device",
    steps: [
      JackActionStep(subsystem: "maintenance", action: "CLEAR_CACHE", params: {}),
      JackActionStep(subsystem: "maintenance", action: "KILL_BACKGROUND", params: {}),
      JackActionStep(subsystem: "maintenance", action: "GET_BATTERY_STATUS", params: {}),
    ],
  ),
  "focus mode": const QuickCommand(
    triggerPhrase: "focus mode",
    steps: [
      JackActionStep(subsystem: "settings", action: "DO_NOT_DISTURB", params: {"state": true}),
      JackActionStep(subsystem: "media", action: "SET_VOLUME", params: {"level": 0, "stream": "media"}),
      JackActionStep(subsystem: "settings", action: "BLUETOOTH", params: {"state": false}),
    ],
  ),
};
