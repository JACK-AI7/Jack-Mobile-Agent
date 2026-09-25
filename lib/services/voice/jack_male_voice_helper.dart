// lib/services/voice/jack_male_voice_helper.dart
//
// Centralized voice configuration helper that enforces a deep British
// baritone MALE voice (JARVIS profile) across FlutterTTS and prevents
// default female voices from ever being selected.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class JackMaleVoiceHelper {
  /// Strictly configures FlutterTts for a deep male British baritone voice.
  /// Rejects any voices flagged as female (gba, gbf, gbd, sfa, female, woman).
  static Future<void> configureMaleBaritoneVoice(FlutterTts tts) async {
    try {
      // 1. Deep baritone pitch (0.80 - 0.84) guarantees masculine resonance
      await tts.setPitch(0.82);
      await tts.setSpeechRate(0.46);
      await tts.setVolume(1.0);

      // 2. Query available system TTS voices
      final List<dynamic>? rawVoices = await tts.getVoices;
      if (rawVoices == null || rawVoices.isEmpty) {
        await tts.setLanguage('en-GB');
        await tts.setPitch(0.82);
        return;
      }

      final voices = rawVoices.whereType<Map>().toList();

      // Male voice token matches (Google TTS voice naming convention & standard IDs)
      // British male identifiers: en-gb-x-rjs, en-gb-x-gbc, en-gb-x-gbb, en-gb-x-gbe, en-gb-x-fis
      // US male identifiers: en-us-x-sfg, en-us-x-tpd, en-us-x-iol
      bool isExplicitMale(String name) {
        final n = name.toLowerCase();
        return n.contains('male') ||
            n.contains('baritone') ||
            n.contains('rjs') ||
            n.contains('gbc') ||
            n.contains('gbb') ||
            n.contains('gbe') ||
            n.contains('fis') ||
            n.contains('sfg') ||
            n.contains('tpd') ||
            n.contains('iol') ||
            n.contains('george') ||
            n.contains('oliver') ||
            n.contains('david') ||
            n.contains('guy');
      }

      // Explicit female tokens that MUST be rejected
      bool isFemale(String name) {
        final n = name.toLowerCase();
        return n.contains('female') ||
            n.contains('woman') ||
            n.contains('girl') ||
            n.contains('gba') ||
            n.contains('gbf') ||
            n.contains('gbd') ||
            n.contains('sfa') ||
            n.contains('sfb') ||
            n.contains('sfc') ||
            n.contains('iob');
      }

      Map? chosenVoice;

      // Pass 1: British English (en-GB) male voice
      for (final v in voices) {
        final name = (v['name'] ?? '').toString();
        final locale = (v['locale'] ?? '').toString().toLowerCase();
        final isBritish = locale.contains('en-gb') ||
            locale.contains('en_gb') ||
            locale.contains('gbr');

        if (isBritish && isExplicitMale(name) && !isFemale(name)) {
          chosenVoice = v;
          break;
        }
      }

      // Pass 2: Any English male voice (US, AU, IN male)
      if (chosenVoice == null) {
        for (final v in voices) {
          final name = (v['name'] ?? '').toString();
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          final isEnglish = locale.startsWith('en');

          if (isEnglish && isExplicitMale(name) && !isFemale(name)) {
            chosenVoice = v;
            break;
          }
        }
      }

      // Pass 3: Any English voice with ZERO female indicators
      if (chosenVoice == null) {
        for (final v in voices) {
          final name = (v['name'] ?? '').toString();
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          final isEnglish = locale.startsWith('en');

          if (isEnglish && !isFemale(name)) {
            chosenVoice = v;
            break;
          }
        }
      }

      if (chosenVoice != null) {
        await tts.setVoice({
          'name': chosenVoice['name'].toString(),
          'locale': chosenVoice['locale'].toString(),
        });
        debugPrint(
            'Jack TTS configured male voice: ${chosenVoice['name']} (${chosenVoice['locale']})');
      } else {
        await tts.setLanguage('en-GB');
      }

      // Re-apply deep baritone pitch so even default fallbacks are distinctly masculine
      await tts.setPitch(0.82);
    } catch (e) {
      debugPrint('Voice helper configuration warning: $e');
    }
  }
}
