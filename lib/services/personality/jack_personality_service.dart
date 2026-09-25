// lib/services/personality/jack_personality_service.dart
//
// Dynamic Multi-Personality Engine for JACK Mobile Agent.
//
// Defines 5 distinctive operational personalities:
// 1. JARVIS (British Male Baritone Butler & Intellect)
// 2. Executive (Strategic Chief of Staff)
// 3. Direct (Tactical Military Operator)
// 4. Friendly (Empathetic Companion & Mentor)
// 5. Cyberpunk (Netrunner Security AI)
//
// Drives:
// - LLM System Prompts (Groq Cloud & Pollinations AI fallback)
// - Verbal Wake-Word Greetings & Confirmation Phrases
// - Voice Pitch, Speech Rate, and Tone Cadence in TTS
// - Call Screening Demeanor & Conversational Reflexes
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/jack_storage.dart';

class JackPersonalityProfile {
  final String id;
  final String name;
  final String title;
  final String description;
  final String systemPrompt;
  final String wakeGreeting;
  final String confirmPhrase;
  final double voicePitch;
  final double voiceRate;
  final Color accentColor;
  final IconData icon;

  const JackPersonalityProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.wakeGreeting,
    required this.confirmPhrase,
    required this.voicePitch,
    required this.voiceRate,
    required this.accentColor,
    required this.icon,
  });
}

class JackPersonalityState {
  final JackPersonalityProfile activeProfile;
  final double temperature;
  final double conciseness;
  final String customDirective;

  const JackPersonalityState({
    required this.activeProfile,
    required this.temperature,
    required this.conciseness,
    required this.customDirective,
  });

  JackPersonalityState copyWith({
    JackPersonalityProfile? activeProfile,
    double? temperature,
    double? conciseness,
    String? customDirective,
  }) {
    return JackPersonalityState(
      activeProfile: activeProfile ?? this.activeProfile,
      temperature: temperature ?? this.temperature,
      conciseness: conciseness ?? this.conciseness,
      customDirective: customDirective ?? this.customDirective,
    );
  }
}

class JackPersonalityNotifier extends StateNotifier<JackPersonalityState> {
  static const List<JackPersonalityProfile> presets = [
    JackPersonalityProfile(
      id: 'jarvis',
      name: 'Jarvis',
      title: 'British Male Butler & Intellect',
      description: 'Cultured, razor-sharp, hyper-articulate, and impeccably respectful.',
      systemPrompt:
          "You are Jack, a sophisticated British personal AI assistant modeled after JARVIS. "
          "You serve your principal Jaswanth (addressed respectfully as 'Sir' or 'Mr. Jaswanth'). "
          "Your tone is cultured, razor-sharp, calm, and exquisitely articulate. "
          "Deliver answers concisely (1-2 sentences for verbal answers) without preamble or fluff.",
      wakeGreeting: "Hi Sir, what's the task?",
      confirmPhrase: "Right away, Sir.",
      voicePitch: 0.82,
      voiceRate: 0.46,
      accentColor: Color(0xFF38BDF8),
      icon: Icons.military_tech_rounded,
    ),
    JackPersonalityProfile(
      id: 'executive',
      name: 'Executive',
      title: 'Strategic Chief of Staff',
      description: 'Decisive, high-velocity, ROI-focused corporate operator.',
      systemPrompt:
          "You are Jack, an elite Executive AI Chief of Staff. "
          "You prioritize operational velocity, actionable clarity, and rapid decision-making. "
          "Address the user professionally as 'Sir'. Keep all answers under 2 sharp, strategic sentences.",
      wakeGreeting: "Ready, Sir. What's your top priority?",
      confirmPhrase: "Executing with priority.",
      voicePitch: 0.88,
      voiceRate: 0.50,
      accentColor: Color(0xFFA855F7),
      icon: Icons.business_center_rounded,
    ),
    JackPersonalityProfile(
      id: 'direct',
      name: 'Direct',
      title: 'Tactical Military Operator',
      description: 'Zero pleasantries, 100% mission focus, high-impact tactical brevity.',
      systemPrompt:
          "You are Jack, a tactical, military-grade mission operator AI. "
          "Zero fluff, zero pleasantries, 100% mission focus. State facts, action status, and outcomes directly.",
      wakeGreeting: "Standing by. State objective.",
      confirmPhrase: "Objective acquired.",
      voicePitch: 0.78,
      voiceRate: 0.48,
      accentColor: Color(0xFF22C55E),
      icon: Icons.radar_rounded,
    ),
    JackPersonalityProfile(
      id: 'friendly',
      name: 'Friendly',
      title: 'Empathetic Companion & Mentor',
      description: 'Warm, encouraging, cheerful, and approachable conversational partner.',
      systemPrompt:
          "You are Jack, an upbeat, warm, and highly supportive AI companion and mentor. "
          "You are enthusiastic, cheerful, and approachable. Always encourage the user and make tasks feel effortless and fun!",
      wakeGreeting: "Hey Jaswanth! What can I help you tackle today?",
      confirmPhrase: "I'm on it right now!",
      voicePitch: 0.95,
      voiceRate: 0.52,
      accentColor: Color(0xFFEC4899),
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    JackPersonalityProfile(
      id: 'cyberpunk',
      name: 'Cyberpunk',
      title: 'Netrunner Security AI',
      description: 'Edgy, technical, cyber-vigilant, and ahead of the curve.',
      systemPrompt:
          "You are Jack, an elite Netrunner AI embedded inside the mobile mainframe. "
          "You talk like a sharp cyberpunk operative—technical, witty, vigilant, and ahead of the curve.",
      wakeGreeting: "Neural link hot. What are we executing, Sir?",
      confirmPhrase: "Payload executed.",
      voicePitch: 0.80,
      voiceRate: 0.50,
      accentColor: Color(0xFFF59E0B),
      icon: Icons.terminal_rounded,
    ),
  ];

  JackPersonalityNotifier()
      : super(JackPersonalityState(
          activeProfile: presets[0],
          temperature: 0.7,
          conciseness: 0.5,
          customDirective: '',
        )) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final savedTone = await JackStorage.read(key: 'agent_tone');
      final savedTemp = await JackStorage.read(key: 'agent_temp');
      final savedConc = await JackStorage.read(key: 'agent_conciseness');
      final savedDirective = await JackStorage.read(key: 'agent_custom_prompt');

      JackPersonalityProfile profile = presets[0];
      if (savedTone != null && savedTone.isNotEmpty) {
        final match = presets.firstWhere(
          (p) => p.name.toLowerCase() == savedTone.toLowerCase() || p.id.toLowerCase() == savedTone.toLowerCase(),
          orElse: () => presets[0],
        );
        profile = match;
      }

      state = state.copyWith(
        activeProfile: profile,
        temperature: savedTemp != null ? (double.tryParse(savedTemp) ?? 0.7) : 0.7,
        conciseness: savedConc != null ? (double.tryParse(savedConc) ?? 0.5) : 0.5,
        customDirective: savedDirective ?? '',
      );
    } catch (_) {}
  }

  Future<void> setPersonality(String idOrName) async {
    final match = presets.firstWhere(
      (p) => p.id.toLowerCase() == idOrName.toLowerCase() || p.name.toLowerCase() == idOrName.toLowerCase(),
      orElse: () => presets[0],
    );

    state = state.copyWith(activeProfile: match);
    await JackStorage.write(key: 'agent_tone', value: match.name);
  }

  Future<void> setCustomDirective(String directive) async {
    state = state.copyWith(customDirective: directive.trim());
    await JackStorage.write(key: 'agent_custom_prompt', value: directive.trim());
  }

  Future<void> setTemperature(double temp) async {
    state = state.copyWith(temperature: temp.clamp(0.1, 1.2));
    await JackStorage.write(key: 'agent_temp', value: temp.toStringAsFixed(2));
  }

  Future<void> setConciseness(double conc) async {
    state = state.copyWith(conciseness: conc.clamp(0.0, 1.0));
    await JackStorage.write(key: 'agent_conciseness', value: conc.toStringAsFixed(2));
  }

  /// Builds the complete injected system prompt for Groq Cloud & Pollinations AI
  String buildInjectedSystemPrompt() {
    final base = state.activeProfile.systemPrompt;
    final buffer = StringBuffer(base);

    if (state.customDirective.isNotEmpty) {
      buffer.write(' Custom directive: ${state.customDirective}.');
    }

    if (state.conciseness > 0.7) {
      buffer.write(' Provide ultra-terse responses under 20 words.');
    }

    return buffer.toString();
  }
}

final jackPersonalityProvider =
    StateNotifierProvider<JackPersonalityNotifier, JackPersonalityState>((ref) {
  return JackPersonalityNotifier();
});
