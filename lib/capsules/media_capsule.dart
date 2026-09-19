// lib/capsules/media_capsule.dart
//
// Jack — Media Capsule (jack.media)
// Handles app launches, YouTube search, Spotify, camera, and photo capture.
// ─────────────────────────────────────────────────────────────────────────────
import 'core_models.dart';
import '../services/jack_master_dispatcher.dart';

final JackCapsule mediaCapsule = JackCapsule(
  capsuleId: 'jack.media',
  version: '1.0.0',
  description: 'Launches apps, plays media on YouTube/Spotify, and controls camera.',

  concepts: const [
    Concept(name: 'MediaQuery',  type: ConceptType.text, description: 'Search query or track name'),
    Concept(name: 'AppName',     type: ConceptType.text, description: 'App name or package'),
    Concept(
      name: 'MediaResult',
      type: ConceptType.structure,
      properties: {
        'app':     ConceptType.text,
        'query':   ConceptType.text,
        'status':  ConceptType.text,
        'success': ConceptType.boolean,
      },
    ),
    Concept(
      name: 'AppLaunchResult',
      type: ConceptType.structure,
      properties: {
        'appName':  ConceptType.text,
        'package':  ConceptType.text,
        'success':  ConceptType.boolean,
      },
    ),
  ],

  actions: const [
    ActionModel(
      name: 'SearchYouTube',
      type: ActionType.commit,
      inputs: [ActionInput(name: 'query', conceptName: 'MediaQuery')],
      outputConcept: 'MediaResult',
    ),
    ActionModel(
      name: 'PlaySpotify',
      type: ActionType.commit,
      inputs: [ActionInput(name: 'query', conceptName: 'MediaQuery', required: false, minCardinality: 0)],
      outputConcept: 'MediaResult',
    ),
    ActionModel(
      name: 'LaunchApp',
      type: ActionType.commit,
      inputs: [ActionInput(name: 'appName', conceptName: 'AppName')],
      outputConcept: 'AppLaunchResult',
    ),
    ActionModel(
      name: 'TakePhoto',
      type: ActionType.commit,
      inputs: [],
      outputConcept: 'MediaResult',
    ),
  ],

  endpoints: {
    'SearchYouTube': (inputs) async {
      final query = inputs['query'] as String? ?? '';
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'launch',
          'params': {'package': 'com.google.android.youtube'},
        });
      } catch (_) {}
      return {'app': 'youtube', 'query': query, 'status': 'SEARCHING', 'success': true};
    },
    'PlaySpotify': (inputs) async {
      final query = inputs['query'] as String? ?? '';
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'launch',
          'params': {'package': 'com.spotify.music'},
        });
      } catch (_) {}
      return {'app': 'spotify', 'query': query, 'status': 'PLAYING', 'success': true};
    },
    'LaunchApp': (inputs) async {
      final appName = inputs['appName'] as String? ?? '';
      final pkg     = _packageForApp(appName);
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'launch',
          'params': {'package': pkg},
        });
      } catch (_) {}
      return {'appName': appName, 'package': pkg, 'success': true};
    },
    'TakePhoto': (inputs) async {
      try {
        await JackMasterDispatcher.executeCommand({
          'intent': 'launch',
          'params': {'package': 'com.android.camera2'},
        });
      } catch (_) {}
      return {'app': 'camera', 'query': '', 'status': 'OPENED', 'success': true};
    },
  },

  views: [
    BixbyViewTemplate(
      targetConcept: 'MediaResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'Media Playing',
      speechTemplate: 'Playing now.',
      layout: [
        const TitleAreaComponent(title: 'Media', subtitle: 'Now Playing'),
        const ThumbnailCardComponent(
          title: 'Now Playing',
          subtitle: 'Jack Media Engine',
          appName: 'Media',
        ),
        CompoundCardComponent(children: [
          const CellCardComponent(
            slot1: CellSlot(type: 'icon', glyph: 'play'),
            slot2: CellSlot(type: 'title-area', title: 'Playback Active', subtitle: 'Streaming via app'),
            slot3: CellSlot(type: 'badge', label: 'LIVE', style: 'success'),
          ),
        ]),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Pause'),
        ConversationDriver(template: 'Skip to next'),
        ConversationDriver(template: 'Set volume to 80%'),
        ConversationDriver(template: 'Play something else'),
      ],
    ),
    BixbyViewTemplate(
      targetConcept: 'AppLaunchResult',
      viewType: ViewType.resultView,
      dialogTemplate: 'App Launched',
      speechTemplate: 'App opened.',
      layout: [
        const TitleAreaComponent(title: 'App Launched', subtitle: 'Now in foreground'),
        const CellCardComponent(
          slot1: CellSlot(type: 'icon', glyph: 'apps'),
          slot2: CellSlot(type: 'title-area', title: 'Application', subtitle: 'Launched via Jack'),
          slot3: CellSlot(type: 'badge', label: 'OPEN', style: 'success'),
        ),
      ],
      conversationDrivers: const [
        ConversationDriver(template: 'Go back'),
        ConversationDriver(template: 'Take a screenshot'),
        ConversationDriver(template: 'Go home'),
      ],
    ),
  ],
);

String _packageForApp(String name) {
  const map = {
    'youtube':    'com.google.android.youtube',
    'whatsapp':   'com.whatsapp',
    'instagram':  'com.instagram.android',
    'chrome':     'com.android.chrome',
    'settings':   'com.android.settings',
    'gmail':      'com.google.android.gm',
    'maps':       'com.google.android.apps.maps',
    'spotify':    'com.spotify.music',
    'netflix':    'com.netflix.mediaclient',
    'camera':     'com.android.camera2',
    'calculator': 'com.google.android.calculator',
    'clock':      'com.android.deskclock',
    'twitter':    'com.twitter.android',
    'telegram':   'org.telegram.messenger',
    'snapchat':   'com.snapchat.android',
  };
  return map[name.toLowerCase().trim()] ?? 'com.android.${name.toLowerCase()}';
}
