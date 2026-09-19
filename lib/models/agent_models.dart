// lib/models/agent_models.dart
// ─────────────────────────────────────────────────────────────────────────────
// Pure data models — zero Flutter dependencies.
// ─────────────────────────────────────────────────────────────────────────────
import '../capsules/core_models.dart';

// ─── Agent Status ─────────────────────────────────────────────────────────────
enum AgentStatus {
  idle,
  listening,
  thinking,      // backend LLM is reasoning
  executingOS,   // Termux is issuing ADB/UIAutomator2 commands
  complete,
  error,
}

// ─── OS Command types ─────────────────────────────────────────────────────────
enum OsCommandType { intent, click, type, scroll, screenshot, complete, unknown }

/// A single OS automation command received over the WebSocket.
class OsCommand {
  OsCommand({
    required this.type,
    required this.timestamp,
    this.target    = '',
    this.element   = '',
    this.text      = '',
    this.details   = '',
  });

  final OsCommandType type;
  final DateTime      timestamp;
  final String        target;   // for intent:  "com.whatsapp"
  final String        element;  // for click:   "Search Bar"
  final String        text;     // for type:    "Flights to Bangalore"
  final String        details;

  /// Human-readable status pill label.
  String get label {
    switch (type) {
      case OsCommandType.intent:
        return 'Launching ${_appName(target)}...';
      case OsCommandType.click:
        return 'Tapping $element...';
      case OsCommandType.type:
        return 'Typing query...';
      case OsCommandType.scroll:
        return 'Scrolling $element...';
      case OsCommandType.screenshot:
        return 'Capturing screen...';
      case OsCommandType.complete:
        return '✓ Done';
      case OsCommandType.unknown:
        return target.isNotEmpty ? target : 'Executing...';
    }
  }

  /// Short timestamp, e.g. "12:34:05"
  String get timeLabel {
    final t = timestamp;
    return '${_p(t.hour)}:${_p(t.minute)}:${_p(t.second)}';
  }

  static String _p(int n) => n.toString().padLeft(2, '0');

  static String _appName(String pkg) {
    const known = {
      'com.whatsapp'       : 'WhatsApp',
      'com.google.android.apps.maps': 'Maps',
      'com.android.chrome' : 'Chrome',
      'com.google.android.gm': 'Gmail',
      'com.redbus.android' : 'redBus',
      'in.abhibus'         : 'AbhiBus',
    };
    return known[pkg] ?? pkg.split('.').last;
  }

  /// Factory from a WebSocket JSON frame.
  factory OsCommand.fromJson(Map<String, dynamic> j) {
    final typeStr = j['type'] as String? ?? '';
    final type = _typeFromString(typeStr);
    return OsCommand(
      type:      type,
      timestamp: DateTime.now(),
      target:    j['target']  as String? ?? '',
      element:   j['element'] as String? ?? '',
      text:      j['text']    as String? ?? '',
      details:   j['details'] as String? ?? '',
    );
  }

  static OsCommandType _typeFromString(String s) {
    switch (s) {
      case 'intent':     return OsCommandType.intent;
      case 'click':      return OsCommandType.click;
      case 'type':       return OsCommandType.type;
      case 'scroll':     return OsCommandType.scroll;
      case 'screenshot': return OsCommandType.screenshot;
      case 'complete':   return OsCommandType.complete;
      default:           return OsCommandType.unknown;
    }
  }
}

// ─── Bus result ───────────────────────────────────────────────────────────────
class BusResult {
  const BusResult({
    required this.operator_,
    required this.departure,
    required this.price,
  });

  final String operator_;
  final String departure;
  final String price;

  factory BusResult.fromJson(Map<String, dynamic> j) => BusResult(
        operator_: j['operator'] as String? ?? '',
        departure: j['departure'] as String? ?? '',
        price:     j['price']    as String? ?? '',
      );
}

// ─── Central agent state ──────────────────────────────────────────────────────
class AgentState {
  const AgentState({
    this.status          = AgentStatus.idle,
    this.transcript      = '',
    this.action          = '',
    this.busResults      = const [],
    this.osLog           = const [],
    this.currentCmd      = '',
    this.errorMessage,
    this.activeModels    = const {'JACK Backend'},
    this.chatHistory     = const [],
    this.isPill          = false,
    this.activeWidget,
    this.bixbyCard,
    this.personalityMode = 'normal', // 'normal' | 'fun'
    this.thoughtTrace,
    this.roastCard,
    this.capsuleResult,
  });

  final AgentStatus           status;
  final String                transcript;
  final String                action;
  final String?               activeWidget;
  final BixbyCardData?        bixbyCard;
  final List<BusResult>       busResults;
  final List<OsCommand>       osLog;
  final String                currentCmd;
  final String?               errorMessage;
  final Set<String>           activeModels;
  final List<String>          chatHistory;
  final bool                  isPill;
  final String                personalityMode; // 'normal' | 'fun'
  final String?               thoughtTrace;
  final Map<String, dynamic>? roastCard;
  final CapsuleDispatchResult? capsuleResult;

  bool get isIdle        => status == AgentStatus.idle;
  bool get isListening   => status == AgentStatus.listening;
  bool get isThinking    => status == AgentStatus.thinking;
  bool get isExecutingOS => status == AgentStatus.executingOS;
  bool get isComplete    => status == AgentStatus.complete;
  bool get isFunMode     => personalityMode == 'fun';

  AgentState copyWith({
    AgentStatus?          status,
    String?               transcript,
    String?               action,
    List<BusResult>?      busResults,
    List<OsCommand>?      osLog,
    String?               currentCmd,
    String?               errorMessage,
    Set<String>?          activeModels,
    List<String>?         chatHistory,
    bool?                 isPill,
    String?               activeWidget,
    BixbyCardData?        bixbyCard,
    bool                  clearBixbyCard = false,
    String?               personalityMode,
    String?               thoughtTrace,
    bool                  clearThoughtTrace = false,
    Map<String, dynamic>? roastCard,
    bool                  clearRoastCard = false,
    CapsuleDispatchResult? capsuleResult,
    bool                  clearCapsuleResult = false,
  }) =>
      AgentState(
        status:          status          ?? this.status,
        transcript:      transcript      ?? this.transcript,
        action:          action          ?? this.action,
        busResults:      busResults      ?? this.busResults,
        osLog:           osLog           ?? this.osLog,
        currentCmd:      currentCmd      ?? this.currentCmd,
        errorMessage:    errorMessage, // null intentionally replaces
        activeModels:    activeModels    ?? this.activeModels,
        chatHistory:     chatHistory     ?? this.chatHistory,
        isPill:          isPill          ?? this.isPill,
        activeWidget:    activeWidget    ?? this.activeWidget,
        bixbyCard:       clearBixbyCard ? null : (bixbyCard ?? this.bixbyCard),
        personalityMode: personalityMode ?? this.personalityMode,
        thoughtTrace:    clearThoughtTrace ? null : (thoughtTrace ?? this.thoughtTrace),
        roastCard:       clearRoastCard ? null : (roastCard ?? this.roastCard),
        capsuleResult:   clearCapsuleResult ? null : (capsuleResult ?? this.capsuleResult),
      );
}


// ─── Bixby Card Data ─────────────────────────────────────────────────────────
class BixbyCardData {
  final String type; // 'flashlight', 'battery', 'volume', 'weather', 'alarm', 'timer', 'action', 'quick_settings'
  final String title;
  final String subtitle;
  final Map<String, dynamic> data;

  const BixbyCardData({
    required this.type,
    required this.title,
    this.subtitle = '',
    this.data = const {},
  });
}

// ─── Model definitions ────────────────────────────────────────────────────────
class ModelDef {
  const ModelDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.filename,
    required this.downloadUrl,
  });
  final String id, title, subtitle, filename, downloadUrl;
}

const List<ModelDef> kModelDefs = [
  ModelDef(
    id: 'nemotron',
    title: 'Nemotron-3 Omni (NVIDIA)',
    subtitle: 'OpenRouter · Real-Data Agent',
    filename: 'nemotron_api',
    downloadUrl: '',
  ),
  ModelDef(
    id: 'JACK Backend',
    title: 'JACK Backend Cloud (Llama 3.3 & Llama 3.1)',
    subtitle: 'API · Ultra-Fast',
    filename: 'JACK Backend_api',
    downloadUrl: '',
  ),
];
