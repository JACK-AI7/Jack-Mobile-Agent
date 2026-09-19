import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const _memoryKey = 'jack_core_memory';

  static Future<List<String>> getMemories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_memoryKey) ?? [];
  }

  static Future<void> addMemory(String memory) async {
    if (memory.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final memories = prefs.getStringList(_memoryKey) ?? [];
    if (!memories.contains(memory)) {
      memories.add(memory);
      await prefs.setStringList(_memoryKey, memories);
    }
  }

  static Future<void> clearMemories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_memoryKey);
  }
}
