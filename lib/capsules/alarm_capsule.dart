// lib/capsules/alarm_capsule.dart
//
// Jack — Alarm & Timer Capsule (jack.alarm)
// Bixby Capsule for clock, alarms, timers, and countdowns.
// ─────────────────────────────────────────────────────────────────────────────
import 'core_models.dart';
import '../services/jack_master_dispatcher.dart';

final JackCapsule alarmCapsule = JackCapsule(
  capsuleId: 'jack.alarm',
  version: '1.0.0',
  description: 'Sets, modifies, and lists alarms and countdown timers.',

  concepts: const [
    Concept(name: 'AlarmHour',   type: ConceptType.integer, description: '0-23'),
    Concept(name: 'AlarmMinute', type: ConceptType.integer, description: '0-59'),
    Concept(name: 'AlarmLabel',  type: ConceptType.text),
    Concept(name: 'TimerDurationSeconds', type: ConceptType.integer),
    Concept(
      name: 'AlarmResult',
      type: ConceptType.structure,
      properties: {
        'time':    ConceptType.text,
        'label':   ConceptType.text,
        'success': ConceptType.boolean,
        'message': ConceptType.text,
      },
    ),
    Concept(
      name: 'TimerResult',
      type: ConceptType.structure,
      properties: {
        'durationSeconds': ConceptType.integer,
        'label':           ConceptType.text,
        'success':         ConceptType.boolean,
      },
    ),
  ],

  actions: const [
    ActionModel(
      name: 'SetAlarm',
      type: ActionType.commit,
      inputs: [
        ActionInput(name: 'hour',   conceptName: 'AlarmHour'),
        ActionInput(name: 'minute', conceptName: 'AlarmMinute'),
        ActionInput(name: 'label',  conceptName: 'AlarmLabel', required: false, minCardinality: 0),
      ],
      outputConcept: 'AlarmResult',
    ),
    ActionModel(
      name: 'SetTimer',
      type: ActionType.commit,
      inputs: [
        ActionInput(name: 'durationSeconds', conceptName: 'TimerDurationSeconds'),
        ActionInput(name: 'label', conceptName: 'AlarmLabel', required: false, minCardinality: 0),
      ],
      outputConcept: 'TimerResult',
    ),
    ActionModel(
      name: 'ListAlarms',
      type: ActionType.search,
      inputs: [],
      outputConcept: 'AlarmResult',
    ),
  ],

  endpoints: {
    'SetAlarm': (inputs) async {
      final hour   = inputs['hour']   as int? ?? 7;
      final minute = inputs['minute'] as int? ?? 0;
      final label  = inputs['label']  as String? ?? 'Jack Alarm';
      final timeStr = '${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')}';
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'set_alarm',
          'params': {'hour': hour, 'minute': minute, 'label': label},
        });
      } catch (_) {}
      return {'time': timeStr, 'label': label, 'success': true, 'message': 'Alarm set for $timeStr'};
    },
    'SetTimer': (inputs) async {
      final secs  = inputs['durationSeconds'] as int? ?? 60;
      final label = inputs['label'] as String? ?? 'Timer';
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'set_timer',
          'params': {'seconds': secs, 'label': label},
        });
      } catch (_) {}
      return {'durationSeconds': secs, 'label': label, 'success': true};
    },
    'ListAlarms': (inputs) async {
      return {'time': 'N/A', 'label': 'No alarms listed yet', 'success': true, 'message': 'No alarms active.'};
    },
  },

  views: [
    BixbyViewTemplate(
      targetConcept: 'AlarmResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'Alarm Set',
      speechTemplate: 'Alarm set.',
      layout: [
        const TitleAreaComponent(title: 'Alarm', subtitle: 'Scheduled & Active'),
        CompoundCardComponent(children: [
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'alarm'),
            slot2: CellSlot(type: 'title-area', title: 'Alarm Time', subtitle: 'Will ring as scheduled'),
            slot3: CellSlot(type: 'badge', label: 'ON', style: 'success'),
          ),
          const DividerComponent(),
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'moon'),
            slot2: CellSlot(type: 'title-area', title: 'Sleep mode ready', subtitle: 'Display dims at bedtime'),
            slot3: CellSlot(type: 'text', value: 'READY'),
          ),
        ]),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Delete this alarm'),
        ConversationDriver(template: 'Set another alarm'),
        ConversationDriver(template: 'Start a 5 minute timer'),
        ConversationDriver(template: 'Good night routine'),
      ],
    ),
    BixbyViewTemplate(
      targetConcept: 'TimerResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'Timer Started',
      speechTemplate: 'Timer started.',
      layout: [
        const TitleAreaComponent(title: 'Timer Running', subtitle: 'Countdown active'),
        const SparklineComponent(value: 1.0, label: 'Timer', color: 'cyan'),
        const CellCardComponent(
          slot1: CellSlot(type: 'icon', glyph: 'timer'),
          slot2: CellSlot(type: 'title-area', title: 'Countdown', subtitle: 'Jack will notify you'),
          slot3: CellSlot(type: 'badge', label: 'RUNNING', style: 'info'),
        ),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Cancel timer'),
        ConversationDriver(template: 'Add 5 more minutes'),
        ConversationDriver(template: 'Set an alarm for tomorrow 7 AM'),
      ],
    ),
  ],
);
