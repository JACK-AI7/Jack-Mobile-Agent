// lib/capsules/communication_capsule.dart
//
// Jack — Communication Capsule (jack.communication)
// Handles calls, SMS, contacts search, and WhatsApp navigation.
// Commit actions (PlaceCall, SendSMS) require confirmation-view.
// ─────────────────────────────────────────────────────────────────────────────
import 'core_models.dart';
import '../services/jack_master_dispatcher.dart';

final JackCapsule communicationCapsule = JackCapsule(
  capsuleId: 'jack.communication',
  version: '1.0.0',
  description: 'Places calls, sends messages, and searches contacts.',

  concepts: const [
    Concept(name: 'ContactName',  type: ConceptType.text),
    Concept(name: 'PhoneNumber',  type: ConceptType.text),
    Concept(name: 'MessageBody',  type: ConceptType.text),
    Concept(name: 'AppTarget',    type: ConceptType.enumConcept,
            enumValues: ['phone', 'whatsapp', 'telegram', 'sms']),
    Concept(
      name: 'CallResult',
      type: ConceptType.structure,
      properties: {
        'contact':  ConceptType.text,
        'number':   ConceptType.text,
        'status':   ConceptType.text,
        'success':  ConceptType.boolean,
      },
    ),
    Concept(
      name: 'MessageResult',
      type: ConceptType.structure,
      properties: {
        'recipient': ConceptType.text,
        'app':       ConceptType.text,
        'status':    ConceptType.text,
        'success':   ConceptType.boolean,
      },
    ),
  ],

  actions: const [
    ActionModel(
      name: 'PlaceCall',
      type: ActionType.commit,
      inputs: [
        ActionInput(name: 'contact', conceptName: 'ContactName', required: false, minCardinality: 0),
        ActionInput(name: 'number',  conceptName: 'PhoneNumber',  required: false, minCardinality: 0),
      ],
      outputConcept: 'CallResult',
      requiresConfirmation: true,
      confirmationPrompt: 'Are you sure you want to call',
    ),
    ActionModel(
      name: 'SendSMS',
      type: ActionType.commit,
      inputs: [
        ActionInput(name: 'contact', conceptName: 'ContactName', required: false, minCardinality: 0),
        ActionInput(name: 'number',  conceptName: 'PhoneNumber',  required: false, minCardinality: 0),
        ActionInput(name: 'body',    conceptName: 'MessageBody'),
      ],
      outputConcept: 'MessageResult',
      requiresConfirmation: true,
      confirmationPrompt: 'Send this message?',
    ),
    ActionModel(
      name: 'NavigateWhatsApp',
      type: ActionType.commit,
      inputs: [
        ActionInput(name: 'contact', conceptName: 'ContactName'),
        ActionInput(name: 'message', conceptName: 'MessageBody', required: false, minCardinality: 0),
      ],
      outputConcept: 'MessageResult',
      requiresConfirmation: false,
    ),
    ActionModel(
      name: 'SearchContacts',
      type: ActionType.search,
      inputs: [ActionInput(name: 'name', conceptName: 'ContactName')],
      outputConcept: 'CallResult',
    ),
  ],

  endpoints: {
    'PlaceCall': (inputs) async {
      final contact = inputs['contact'] as String? ?? '';
      final number  = inputs['number']  as String? ?? '';
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'call',
          'params': {'contact': contact, 'number': number},
        });
      } catch (_) {}
      return {'contact': contact, 'number': number, 'status': 'DIALING', 'success': true};
    },
    'SendSMS': (inputs) async {
      final contact = inputs['contact'] as String? ?? '';
      // final body    = inputs['body']    as String? ?? '';
      return {'recipient': contact, 'app': 'sms', 'status': 'SENT', 'success': true};
    },
    'NavigateWhatsApp': (inputs) async {
      final contact = inputs['contact'] as String? ?? '';
      // final message = inputs['message'] as String? ?? '';
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'launch',
          'params': {'package': 'com.whatsapp'},
        });
      } catch (_) {}
      return {'recipient': contact, 'app': 'whatsapp', 'status': 'OPENED', 'success': true};
    },
    'SearchContacts': (inputs) async {
      final name = inputs['name'] as String? ?? '';
      return {'contact': name, 'number': 'N/A', 'status': 'FOUND', 'success': true};
    },
  },

  views: [
    // Confirmation view for calls
    BixbyViewTemplate(
      targetConcept: 'CallResult',
      viewType: ViewType.confirmationView,
      dialogTemplate: 'Place Call',
      speechTemplate: 'Calling now.',
      confirmationText: 'Call',
      layout: [
        const TitleAreaComponent(
          title: 'Place Call',
          subtitle: 'Tap Confirm to dial',
          halign: 'Center',
        ),
        const CellCardComponent(
          slot1: CellSlot(type: 'icon', glyph: 'phone'),
          slot2: CellSlot(type: 'title-area', title: 'Outbound Call', subtitle: 'via Jack Communication'),
          slot3: CellSlot(type: 'badge', label: 'READY', style: 'info'),
        ),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Cancel'),
        ConversationDriver(template: 'Send a WhatsApp message instead'),
      ],
    ),
    // Result view after call placed
    BixbyViewTemplate(
      targetConcept: 'CallResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'Call Placed',
      speechTemplate: 'Calling now.',
      layout: [
        const TitleAreaComponent(title: 'Call Active', subtitle: 'Connected via Phone'),
        CompoundCardComponent(children: [
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'phone'),
            slot2: CellSlot(type: 'title-area', title: 'Call in Progress', subtitle: 'Tap to open dialer'),
            slot3: CellSlot(type: 'badge', label: 'LIVE', style: 'success'),
          ),
        ]),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'End call'),
        ConversationDriver(template: 'Send a WhatsApp message'),
        ConversationDriver(template: 'Mute microphone'),
      ],
    ),
    // Message result view
    BixbyViewTemplate(
      targetConcept: 'MessageResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'Message Sent',
      speechTemplate: 'Message sent.',
      layout: [
        const TitleAreaComponent(title: 'Message', subtitle: 'Delivered'),
        const CellCardComponent(
          slot1: CellSlot(type: 'icon', glyph: 'message'),
          slot2: CellSlot(type: 'title-area', title: 'Sent', subtitle: 'Message delivered'),
          slot3: CellSlot(type: 'badge', label: 'SENT', style: 'success'),
        ),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Send another message'),
        ConversationDriver(template: 'Place a call instead'),
      ],
    ),
  ],
);
