// lib/services/jack_reflex_cache.dart
//
// Jack — Fast-Path Local Reflex Router
// Bypasses LLM latency completely for deterministic voice commands
// ─────────────────────────────────────────────────────────────────────────────

class JackReflexCache {
  static final Map<Pattern, Map<String, dynamic>> _reflexRegistry = {
    // Flashlight
    RegExp(r'^(turn\s+on\s+flashlight|torch\s+on|flashlight\s+on)$', caseSensitive: false): {
      'capsule_id': 'jack.systemControl',
      'action': 'toggle_flashlight',
      'params': {'state': true},
      'speech': 'Flashlight turned on.'
    },
    RegExp(r'^(turn\s+off\s+flashlight|torch\s+off|flashlight\s+off)$', caseSensitive: false): {
      'capsule_id': 'jack.systemControl',
      'action': 'toggle_flashlight',
      'params': {'state': false},
      'speech': 'Flashlight turned off.'
    },
    // Screenshot
    RegExp(r'^(take\s+screenshot|capture\s+screen|screenshot)$', caseSensitive: false): {
      'capsule_id': 'jack.systemControl',
      'action': 'take_screenshot',
      'params': {},
      'speech': 'Capturing screenshot.'
    },
    // Lock Screen
    RegExp(r'^(lock\s+screen|lock\s+phone)$', caseSensitive: false): {
      'capsule_id': 'jack.systemControl',
      'action': 'lock_screen',
      'params': {},
      'speech': 'Device locked.'
    },
  };

  /// Evaluates query in < 2ms; returns execution payload or null
  static Map<String, dynamic>? matchReflex(String rawQuery) {
    final clean = rawQuery.trim().toLowerCase();
    for (final entry in _reflexRegistry.entries) {
      if ((entry.key as RegExp).hasMatch(clean)) {
        return entry.value;
      }
    }
    return null;
  }
}
