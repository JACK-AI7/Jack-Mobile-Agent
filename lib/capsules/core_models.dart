// lib/capsules/core_models.dart
//
// Jack — Bixby Capsule Engine: Core Type System
// Based on Samsung Bixby Developer Platform specification (bixbydevelopers.com)
//
// Architecture mirrors official Bixby .model.bxb, .action.bxb, .view.bxb files:
//   • Concepts  → typed domain data (primitives, structures, enums)
//   • Actions   → state verbs (search, fetch, commit, calculation)
//   • Views     → declarative layout templates (result, confirmation, input)
//   • Dialog    → NL voice templates separate from visual card text
//   • Capsule   → composable unit bundling all of the above
// ─────────────────────────────────────────────────────────────────────────────

// ══════════════════════════════════════════════════════════════════════════════
// 1. CONCEPTS — Typed Domain Data Schema
// ══════════════════════════════════════════════════════════════════════════════

enum ConceptType {
  text,
  integer,
  decimal,
  boolean,
  structure,  // compound typed object
  enumConcept, // fixed-value enumeration
  geo,        // lat/lon geographic point
  dateTime,   // ISO-8601 datetime
  duration,   // millisecond duration
  media,      // binary image/audio blob reference
}

class Concept {
  final String name;
  final ConceptType type;
  final Map<String, ConceptType>? properties; // for ConceptType.structure
  final List<String>? enumValues;             // for ConceptType.enumConcept
  final String? description;

  const Concept({
    required this.name,
    required this.type,
    this.properties,
    this.enumValues,
    this.description,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. ACTIONS — Execution State Verbs
// ══════════════════════════════════════════════════════════════════════════════

enum ActionType {
  /// Read-only fetch from device or service (no side effects)
  fetch,
  /// Structured query/search returning a list result
  search,
  /// Pure mathematical or logical transformation
  calculation,
  /// Mutates system state or sends data externally (requires confirmation gate)
  commit,
}

class ActionInput {
  final String name;
  final String conceptName;
  final bool required;
  final int minCardinality; // 0 = optional, 1 = required
  final int maxCardinality; // 1 = single, -1 = unbounded list

  const ActionInput({
    required this.name,
    required this.conceptName,
    this.required = true,
    this.minCardinality = 1,
    this.maxCardinality = 1,
  });
}

class ActionModel {
  final String name;
  final ActionType type;
  final List<ActionInput> inputs;
  final String outputConcept;
  final bool requiresConfirmation;
  final String? confirmationPrompt; // shown in confirmation-view
  final String? description;

  const ActionModel({
    required this.name,
    required this.type,
    required this.inputs,
    required this.outputConcept,
    this.requiresConfirmation = false,
    this.confirmationPrompt,
    this.description,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. BIXBY VIEWS — Declarative Layout Components
// ══════════════════════════════════════════════════════════════════════════════

enum ViewType {
  resultView,       // Default: shown after successful execution
  confirmationView, // Human-in-the-loop safety gate before commit actions
  inputView,        // Disambiguation: missing required concept
}

/// Base sealed class for all Bixby layout components
/// (mirrors layout > section > content in .view.bxb)
sealed class BixbyLayoutComponent {
  const BixbyLayoutComponent();
}

/// title-area: Top anchor card with primary title and optional subtitle
class TitleAreaComponent extends BixbyLayoutComponent {
  final String title;
  final String? subtitle;
  final String? halign; // 'Start' | 'Center' | 'End'

  const TitleAreaComponent({
    required this.title,
    this.subtitle,
    this.halign = 'Start',
  });
}

/// compound-card: High-density container grouping multiple cells with dividers
class CompoundCardComponent extends BixbyLayoutComponent {
  final List<BixbyLayoutComponent> children;

  const CompoundCardComponent({required this.children});
}

/// Slot definition for cell-card
class CellSlot {
  final String type; // 'icon', 'title-area', 'text', 'badge', 'switch', 'image'
  final String? glyph;    // SF symbol or Material icon name
  final String? title;
  final String? subtitle;
  final String? value;
  final String? label;
  final String? style;    // 'success' | 'warning' | 'error' | 'info'
  final bool? switchValue;

  const CellSlot({
    required this.type,
    this.glyph,
    this.title,
    this.subtitle,
    this.value,
    this.label,
    this.style,
    this.switchValue,
  });
}

/// cell-card: Three-slot horizontal layout (leading icon, body, trailing value)
class CellCardComponent extends BixbyLayoutComponent {
  final CellSlot slot1; // Leading: icon / thumbnail
  final CellSlot slot2; // Body: title-area with title + subtitle
  final CellSlot? slot3; // Trailing: badge / value / switch state

  const CellCardComponent({
    required this.slot1,
    required this.slot2,
    this.slot3,
  });
}

/// thumbnail-card: Media-heavy card with image and overlay text
class ThumbnailCardComponent extends BixbyLayoutComponent {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final String? appName;

  const ThumbnailCardComponent({
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.appName,
  });
}

/// paragraph: Styled body text block
class ParagraphComponent extends BixbyLayoutComponent {
  final String text;
  final double? fontSize;

  const ParagraphComponent({required this.text, this.fontSize});
}

/// single-line: Compact one-liner text with key + optional value
class SingleLineComponent extends BixbyLayoutComponent {
  final String text;
  final String? trailingValue;

  const SingleLineComponent({required this.text, this.trailingValue});
}

/// partitioned: N-column data grid (e.g., weather row or telemetry strip)
class PartitionedComponent extends BixbyLayoutComponent {
  final List<Map<String, String>> columns; // [{label, value, unit}]

  const PartitionedComponent({required this.columns});
}

/// divider: Visual separator between cells inside compound-card
class DividerComponent extends BixbyLayoutComponent {
  const DividerComponent();
}

/// sparkline: Mini progress/trend line (battery level, timer countdown)
class SparklineComponent extends BixbyLayoutComponent {
  final double value;   // 0.0 → 1.0
  final String label;
  final String? unit;
  final String color; // 'green' | 'amber' | 'red' | 'cyan'

  const SparklineComponent({
    required this.value,
    required this.label,
    this.unit,
    this.color = 'cyan',
  });
}

/// attribution-link: Small source reference link
class AttributionLinkComponent extends BixbyLayoutComponent {
  final String label;
  final String url;

  const AttributionLinkComponent({required this.label, required this.url});
}

// ── Conversation Drivers ──────────────────────────────────────────────────────
class ConversationDriver {
  final String template; // The query text shown on the pill
  final String? query;   // Overrides template if different from display text

  const ConversationDriver({required this.template, this.query});

  String get effectiveQuery => query ?? template;
}

// ── Full View Template ────────────────────────────────────────────────────────
class BixbyViewTemplate {
  final String targetConcept;         // Which concept output this renders
  final ViewType viewType;
  final List<BixbyLayoutComponent> layout; // layout > section > content
  final List<ConversationDriver> conversationDrivers;
  final String dialogTemplate;         // On-screen card title/label
  final String speechTemplate;         // Spoken TTS string (≤15 words for reflex)
  final String? confirmationText;      // For confirmation-view CTA button
  final List<String>? inputOptions;    // For input-view disambiguation list

  const BixbyViewTemplate({
    required this.targetConcept,
    this.viewType = ViewType.resultView,
    required this.layout,
    this.conversationDrivers = const [],
    required this.dialogTemplate,
    required this.speechTemplate,
    this.confirmationText,
    this.inputOptions,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. CAPSULE CONTAINER — The Bixby Capsule Standard
// ══════════════════════════════════════════════════════════════════════════════

typedef CapsuleEndpoint = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> inputs);

class JackCapsule {
  final String capsuleId;  // e.g. "jack.systemControl"
  final String version;    // e.g. "1.0.0"
  final String description;
  final List<Concept> concepts;
  final List<ActionModel> actions;
  final Map<String, CapsuleEndpoint> endpoints; // actionName → async executor
  final List<BixbyViewTemplate> views;

  const JackCapsule({
    required this.capsuleId,
    required this.version,
    required this.description,
    required this.concepts,
    required this.actions,
    required this.endpoints,
    required this.views,
  });
}

// ── Dispatch Result ───────────────────────────────────────────────────────────
class CapsuleDispatchResult {
  final String capsuleId;
  final String actionName;
  final Map<String, dynamic> result;
  final BixbyViewTemplate viewTemplate;
  final String speechText;
  final String dialogText;

  const CapsuleDispatchResult({
    required this.capsuleId,
    required this.actionName,
    required this.result,
    required this.viewTemplate,
    required this.speechText,
    required this.dialogText,
  });
}
