// lib/providers/call_log_provider.dart
//
// Persists call log entries and exposes them to the dashboard.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call_log_model.dart';

class CallLogNotifier extends StateNotifier<List<CallLogEntry>> {
  CallLogNotifier() : super([]) {
    _load();
  }

  static const _prefKey = 'jack_call_log';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => CallLogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(state.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> addEntry(CallLogEntry entry) async {
    state = [entry, ...state];
    if (state.length > 50) state = state.take(50).toList(); // keep last 50
    await _save();
  }

  Future<void> updateSummary(String id, String summary, List<String> actions) async {
    state = state.map((e) {
      if (e.id == id) return e.copyWith(aiSummary: summary, jackActions: actions);
      return e;
    }).toList();
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}

final callLogProvider = StateNotifierProvider<CallLogNotifier, List<CallLogEntry>>(
  (_) => CallLogNotifier(),
);
