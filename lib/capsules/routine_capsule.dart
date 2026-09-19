// lib/capsules/routine_capsule.dart
//
// Jack — Routines Capsule (jack.routines)
// Executes multi-step automation routines: Good Night, Morning, Driving, Focus.
// ─────────────────────────────────────────────────────────────────────────────
import 'core_models.dart';
import '../services/jack_transaction_runner.dart';

final JackCapsule routineCapsule = JackCapsule(
  capsuleId: 'jack.routines',
  version: '1.0.0',
  description: 'Executes multi-step device automation routines.',

  concepts: const [
    Concept(
      name: 'RoutineName',
      type: ConceptType.enumConcept,
      enumValues: ['good_night', 'good_morning', 'driving', 'focus', 'workout', 'battery_saver'],
    ),
    Concept(name: 'RoutineStepLabel', type: ConceptType.text),
    Concept(
      name: 'RoutineResult',
      type: ConceptType.structure,
      properties: {
        'routine':     ConceptType.text,
        'stepsTotal':  ConceptType.integer,
        'stepsDone':   ConceptType.integer,
        'success':     ConceptType.boolean,
        'message':     ConceptType.text,
      },
    ),
  ],

  actions: const [
    ActionModel(
      name: 'ExecuteRoutine',
      type: ActionType.commit,
      inputs: [ActionInput(name: 'routine', conceptName: 'RoutineName')],
      outputConcept: 'RoutineResult',
      requiresConfirmation: false,
    ),
    ActionModel(
      name: 'ListRoutines',
      type: ActionType.search,
      inputs: [],
      outputConcept: 'RoutineResult',
    ),
  ],

  endpoints: {
    'ExecuteRoutine': (inputs) async {
      final routine = inputs['routine'] as String? ?? 'good_night';
      final stepsData = _routineSteps[routine] ?? [];
      
      final steps = stepsData.map((data) => RoutineStep(
        stepName: data['intent'] ?? 'step',
        executePayload: data,
        rollbackPayload: data['rollback'] ?? {'intent': 'none'},
      )).toList();

      final pipeline = RoutineTransactionPipeline(
        routineId: routine,
        steps: steps,
      );

      final result = await pipeline.executeAtomic();
      
      return {
        'routine':    routine,
        'stepsTotal': result['stepsTotal'],
        'stepsDone':  result['stepsDone'],
        'success':    result['success'],
        'message':    result['message'],
      };
    },
    'ListRoutines': (inputs) async {
      return {
        'routine':    'all',
        'stepsTotal': 6,
        'stepsDone':  6,
        'success':    true,
        'message':    'Good Night, Morning, Driving, Focus, Workout, Battery Saver',
      };
    },
  },

  views: [
    BixbyViewTemplate(
      targetConcept: 'RoutineResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'Routine Complete',
      speechTemplate: 'Routine executed.',
      layout: [
        const TitleAreaComponent(title: 'Routine Executed', subtitle: 'All steps applied'),
        CompoundCardComponent(children: [
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'bolt'),
            slot2: CellSlot(type: 'title-area', title: 'Routine Steps', subtitle: 'Multi-action sequence'),
            slot3: CellSlot(type: 'badge', label: 'DONE', style: 'success'),
          ),
          const DividerComponent(),
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'moon'),
            slot2: CellSlot(type: 'title-area', title: 'Do Not Disturb', subtitle: 'Enabled'),
            slot3: CellSlot(type: 'badge', label: 'ON', style: 'success'),
          ),
          const DividerComponent(),
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'sun.min'),
            slot2: CellSlot(type: 'title-area', title: 'Brightness', subtitle: 'Dimmed to 10%'),
            slot3: CellSlot(type: 'text', value: '10%'),
          ),
          const DividerComponent(),
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'alarm'),
            slot2: CellSlot(type: 'title-area', title: 'Wake Alarm', subtitle: 'Scheduled'),
            slot3: CellSlot(type: 'badge', label: 'SET', style: 'info'),
          ),
          const DividerComponent(),
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'bluetooth.slash'),
            slot2: CellSlot(type: 'title-area', title: 'Bluetooth', subtitle: 'Turned off'),
            slot3: CellSlot(type: 'badge', label: 'OFF', style: 'warning'),
          ),
        ]),
        const SparklineComponent(value: 1.0, label: 'Completion', color: 'green'),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Undo routine'),
        ConversationDriver(template: 'Set alarm for 7 AM'),
        ConversationDriver(template: 'Show active routines'),
        ConversationDriver(template: 'What routines are available?'),
      ],
    ),
  ],
);

// Multi-step routine definitions with compensating rollbacks
const _routineSteps = <String, List<Map<String, dynamic>>>{
  'good_night': [
    {'intent': 'dnd:on',         'params': {}, 'rollback': {'intent': 'dnd:off', 'params': {}}},
    {'intent': 'brightness',     'params': {'level': 10}, 'rollback': {'intent': 'brightness', 'params': {'level': 50}}},
    {'intent': 'set_alarm',      'params': {'hour': 7, 'minute': 0, 'label': 'Good Morning'}, 'rollback': {'intent': 'none', 'params': {}}},
    {'intent': 'bluetooth:off',  'params': {}, 'rollback': {'intent': 'bluetooth:on', 'params': {}}},
    {'intent': 'volume',         'params': {'level': 0}, 'rollback': {'intent': 'volume', 'params': {'level': 50}}},
  ],
  'good_morning': [
    {'intent': 'dnd:off',        'params': {}, 'rollback': {'intent': 'dnd:on', 'params': {}}},
    {'intent': 'brightness',     'params': {'level': 80}, 'rollback': {'intent': 'brightness', 'params': {'level': 10}}},
    {'intent': 'bluetooth:on',   'params': {}, 'rollback': {'intent': 'bluetooth:off', 'params': {}}},
    {'intent': 'volume',         'params': {'level': 70}, 'rollback': {'intent': 'volume', 'params': {'level': 0}}},
  ],
  'driving': [
    {'intent': 'dnd:on',         'params': {}, 'rollback': {'intent': 'dnd:off', 'params': {}}},
    {'intent': 'bluetooth:on',   'params': {}, 'rollback': {'intent': 'bluetooth:off', 'params': {}}},
    {'intent': 'brightness',     'params': {'level': 100}, 'rollback': {'intent': 'brightness', 'params': {'level': 50}}},
    {'intent': 'launch',         'params': {'package': 'com.google.android.apps.maps'}, 'rollback': {'intent': 'none', 'params': {}}},
  ],
  'focus': [
    {'intent': 'dnd:on',         'params': {}, 'rollback': {'intent': 'dnd:off', 'params': {}}},
    {'intent': 'volume',         'params': {'level': 0}, 'rollback': {'intent': 'volume', 'params': {'level': 50}}},
    {'intent': 'brightness',     'params': {'level': 50}, 'rollback': {'intent': 'brightness', 'params': {'level': 100}}},
  ],
  'workout': [
    {'intent': 'bluetooth:on',   'params': {}, 'rollback': {'intent': 'bluetooth:off', 'params': {}}},
    {'intent': 'volume',         'params': {'level': 90}, 'rollback': {'intent': 'volume', 'params': {'level': 50}}},
    {'intent': 'launch',         'params': {'package': 'com.spotify.music'}, 'rollback': {'intent': 'none', 'params': {}}},
  ],
  'battery_saver': [
    {'intent': 'bluetooth:off',  'params': {}, 'rollback': {'intent': 'bluetooth:on', 'params': {}}},
    {'intent': 'wifi:off',       'params': {}, 'rollback': {'intent': 'wifi:on', 'params': {}}},
    {'intent': 'brightness',     'params': {'level': 20}, 'rollback': {'intent': 'brightness', 'params': {'level': 60}}},
    {'intent': 'volume',         'params': {'level': 30}, 'rollback': {'intent': 'volume', 'params': {'level': 70}}},
  ],
};
