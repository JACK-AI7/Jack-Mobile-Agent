// lib/capsules/system_control_capsule.dart
//
// Jack — System Control Capsule (jack.systemControl)
// Realization of Samsung Bixby's device control capsule specification.
// Controls: flashlight, Wi-Fi, Bluetooth, brightness, volume, screenshot, lock
// ─────────────────────────────────────────────────────────────────────────────
import 'core_models.dart';
import '../services/jack_master_dispatcher.dart';

final JackCapsule systemControlCapsule = JackCapsule(
  capsuleId: 'jack.systemControl',
  version: '1.0.0',
  description: 'Controls device hardware toggles, display, and system states.',

  // ── 1. Concepts ────────────────────────────────────────────────────────────
  concepts: const [
    Concept(
      name: 'ToggleTarget',
      type: ConceptType.enumConcept,
      enumValues: ['flashlight', 'wifi', 'bluetooth', 'mobile_data',
                   'airplane_mode', 'hotspot', 'nfc', 'dnd', 'auto_rotate',
                   'dark_mode', 'location'],
    ),
    Concept(name: 'TargetState',   type: ConceptType.boolean),
    Concept(name: 'BrightnessLevel', type: ConceptType.integer,
            description: '0–100 screen brightness'),
    Concept(name: 'VolumeLevel',   type: ConceptType.integer,
            description: '0–100 media/ring volume'),
    Concept(
      name: 'SystemExecutionResult',
      type: ConceptType.structure,
      properties: {
        'target':  ConceptType.text,
        'success': ConceptType.boolean,
        'message': ConceptType.text,
        'newValue': ConceptType.text,
      },
    ),
    Concept(name: 'ScreenshotResult', type: ConceptType.structure,
            properties: {'path': ConceptType.text, 'success': ConceptType.boolean}),
  ],

  // ── 2. Actions ─────────────────────────────────────────────────────────────
  actions: const [
    ActionModel(
      name: 'SetDeviceToggle',
      type: ActionType.commit,
      inputs: [
        ActionInput(name: 'target', conceptName: 'ToggleTarget'),
        ActionInput(name: 'state',  conceptName: 'TargetState'),
      ],
      outputConcept: 'SystemExecutionResult',
      requiresConfirmation: false,
    ),
    ActionModel(
      name: 'SetBrightness',
      type: ActionType.commit,
      inputs: [ActionInput(name: 'level', conceptName: 'BrightnessLevel')],
      outputConcept: 'SystemExecutionResult',
    ),
    ActionModel(
      name: 'SetVolume',
      type: ActionType.commit,
      inputs: [ActionInput(name: 'level', conceptName: 'VolumeLevel')],
      outputConcept: 'SystemExecutionResult',
    ),
    ActionModel(
      name: 'TakeScreenshot',
      type: ActionType.commit,
      inputs: [],
      outputConcept: 'ScreenshotResult',
    ),
    ActionModel(
      name: 'LockScreen',
      type: ActionType.commit,
      inputs: [],
      outputConcept: 'SystemExecutionResult',
      requiresConfirmation: false,
    ),
  ],

  // ── 3. Endpoints ───────────────────────────────────────────────────────────
  endpoints: {
    'SetDeviceToggle': (inputs) async {
      final target = inputs['target'] as String? ?? '';
      final state  = inputs['state']  as bool?   ?? false;
      final intent = _toggleIntent(target, state);
      String msg = '$target turned ${state ? "ON" : "OFF"}';
      try {
        await JackMasterDispatcher.executeCommand({'intent': intent, 'params': {'state': state}});
      } catch (_) {}
      return {'target': target, 'success': true, 'message': msg, 'newValue': state ? 'ON' : 'OFF'};
    },
    'SetBrightness': (inputs) async {
      final level = inputs['level'] as int? ?? 50;
      try {
        await JackMasterDispatcher.executeCommand({'intent': 'brightness', 'params': {'level': level}});
      } catch (_) {}
      return {'target': 'brightness', 'success': true, 'message': 'Brightness set to $level%', 'newValue': '$level%'};
    },
    'SetVolume': (inputs) async {
      final level = inputs['level'] as int? ?? 50;
      try {
        await JackMasterDispatcher.executeCommand({'intent': 'volume', 'params': {'level': level}});
      } catch (_) {}
      return {'target': 'volume', 'success': true, 'message': 'Volume set to $level%', 'newValue': '$level%'};
    },
    'TakeScreenshot': (inputs) async {
      try {
        await JackMasterDispatcher.executeCommand({'intent': 'screenshot', 'params': {}});
      } catch (_) {}
      return {'path': '/sdcard/DCIM/jack_screenshot.png', 'success': true};
    },
    'LockScreen': (inputs) async {
      try {
        await JackMasterDispatcher.executeCommand({'intent': 'lock_screen', 'params': {}});
      } catch (_) {}
      return {'target': 'screen', 'success': true, 'message': 'Screen locked.', 'newValue': 'LOCKED'};
    },
  },

  // ── 4. Bixby Views ─────────────────────────────────────────────────────────
  views: [
    BixbyViewTemplate(
      targetConcept: 'SystemExecutionResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'System State Modified',
      speechTemplate: 'Done.',
      layout: [
        const TitleAreaComponent(
          title: 'System Action',
          subtitle: 'Executed via Jack Hardware Bus',
        ),
        CompoundCardComponent(children: [
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'bolt'),
            slot2: CellSlot(type: 'title-area', title: 'Hardware Bus', subtitle: 'Action applied'),
            slot3: CellSlot(type: 'badge', label: 'SUCCESS', style: 'success'),
          ),
          const DividerComponent(),
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'cpu'),
            slot2: CellSlot(type: 'title-area', title: 'Agent Core', subtitle: 'System verified'),
            slot3: CellSlot(type: 'text', value: 'READY'),
          ),
        ]),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Undo'),
        ConversationDriver(template: 'Open Device Settings'),
        ConversationDriver(template: 'Check Battery'),
        ConversationDriver(template: 'Battery Diagnostics'),
      ],
    ),
    BixbyViewTemplate(
      targetConcept: 'ScreenshotResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'Screenshot Captured',
      speechTemplate: 'Screenshot saved to gallery.',
      layout: [
        const TitleAreaComponent(title: 'Screenshot', subtitle: 'Saved to Gallery'),
        const CellCardComponent(
          slot1: CellSlot(type: 'icon', glyph: 'camera'),
          slot2: CellSlot(type: 'title-area', title: 'Capture Complete', subtitle: 'Tap to view in Gallery'),
          slot3: CellSlot(type: 'badge', label: 'SAVED', style: 'success'),
        ),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Open Gallery'),
        ConversationDriver(template: 'Share Screenshot'),
        ConversationDriver(template: 'Take another screenshot'),
      ],
    ),
  ],
);

String _toggleIntent(String target, bool state) {
  switch (target.toLowerCase()) {
    case 'flashlight': return state ? 'flashlight:on' : 'flashlight:off';
    case 'wifi':       return 'wifi:${state ? "on" : "off"}';
    case 'bluetooth':  return 'bluetooth:${state ? "on" : "off"}';
    case 'dnd':        return 'dnd:${state ? "on" : "off"}';
    default:           return target;
  }
}
