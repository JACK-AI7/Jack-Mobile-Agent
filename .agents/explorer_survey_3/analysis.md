# Analysis Report: Native ML Capabilities, Data-Loss Prevention (DLP) Hooks & Architecture Modernization

**Project**: Jack Mobile Agent  
**Explorer**: Survey Explorer 3  
**Date**: 2026-08-25  
**Target Environment**: Flutter 3.44.4 • Dart 3.12.2 • Android AGP 9.0.1 • Kotlin 2.3.20 • compileSdk 37

---

## 1. Executive Summary

The Jack Mobile Agent is an autonomous, voice-driven Flutter + Android OS agent combining real-time speech interaction, cloud LLM reasoning (Groq Llama-3.3-70b/3.1-8b), and native Android Accessibility/Overlay automation.

This survey provides an authoritative architectural analysis and concrete rebuild blueprint for two foundational pillars:
1. **Native ML Capabilities**: Establishing on-device intelligence (local intent classification, offline speech/audio VAD, OCR screen grounding, entity extraction, and local SLM/embedding search) to eliminate cloud latency, reduce API token burn, protect user privacy, and maintain high agent responsiveness even in offline/degraded network states.
2. **Data-Loss Prevention (DLP) & Safe Persistence Hooks**: Replacing fragile unencrypted `SharedPreferences` JSON blobs with a transactional, ACID-compliant, encrypted storage architecture (`drift` / `sqflite` + `flutter_secure_storage`), automated disaster recovery / backup / export hooks, crash-safe state replay, PII redaction, and Human-in-the-Loop (HIL) accidental deletion/destructive action interceptors.

---

## 2. Current Architecture & Codebase Audit

### 2.1 Current Persistence & Memory Layer
| Component | Implementation File | Current Storage Pattern | Vulnerabilities / DLP Risks |
| :--- | :--- | :--- | :--- |
| **Core Memories** | `lib/services/memory_service.dart` | `SharedPreferences.getStringList('jack_core_memory')` | Unencrypted, unindexed, vulnerable to concurrent write clobbering, no schema or versioning. |
| **Call Logs** | `lib/providers/call_log_provider.dart` | Single JSON string in `SharedPreferences.setString('jack_call_log', jsonEncode(...))` | Atomic crash failure: if the app is killed during serialization, entire call history is corrupted/lost. Hardcoded 50-item FIFO cap. |
| **Chat History** | `lib/providers/agent_state_provider.dart` | Single JSON string in `SharedPreferences.setString('jack_chat_history', jsonEncode(...))` | High write frequency per turn; serialized string rewrites entire history on every message, risking data corruption. |
| **Facts & Preferences** | `lib/services/jack_tools.dart` | JSON map in `SharedPreferences.setString('jack_memory_facts', jsonEncode(...))` | Plain-text storage of sensitive personal information (contact names, addresses, private notes). |
| **Deletion Logic** | `clearMemories()`, `clearHistory()`, `forget_fact()` | Instant hard deletion (`prefs.remove(...)`) | **Zero confirmation, zero undo, zero soft-delete/tombstone**. Accidental user triggers permanently destroy user data. |

### 2.2 Current AI & Machine Learning Layer
- **Cloud-Only Execution**: The agent currently delegates 100% of reasoning, intent classification, and tool decisions to cloud Groq endpoints (`llama-3.3-70b-versatile` and `llama-3.1-8b-instant`).
- **Heavy ML Past Removal**: `pubspec.yaml` contains the comment: `# (Removed heavy ML packages that require extra native setup — Groq handles all AI)`.
- **Latency & Reliability Overhead**: Simple on-device tasks (such as "turn on flashlight", "set volume to 80%", "open WhatsApp", "call Mom", or date/time queries) require full round-trip network hops, token consumption, and rate-limit risks on Groq API keys.
- **Screen Understanding**: The app captures screen bitmaps via platform channel (`captureScreen`), but lacks on-device OCR/grounding, sending large payloads or missing local UI coordinate parsing.
- **OpenCL / GPU Hooks Prepared**: `AndroidManifest.xml` already defines `libOpenCL.so`, `libOpenCL-pixel.so`, `libOpenCL-car.so`, indicating ready support for GPU-accelerated local tensor runtimes.

---

## 3. Native ML Capabilities: Evaluation & Architecture

### 3.1 Comparison of On-Device ML Packages for Flutter
| Solution / Package | Supported Capabilities | Min SDK | AGP 9 / Dart 3.12 Compatibility | Performance / Size Tradeoff | Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`google_mlkit_commons` + `google_mlkit_text_recognition` + `google_mlkit_entity_extraction` + `google_mlkit_smart_reply`** | On-device OCR, Entity parsing (dates, flight numbers, phone numbers, addresses), Smart Replies | 21+ | **Excellent**: Backed by Google Play Services ML Kit models. Zero native C++ build friction. | Tiny APK footprint (~2MB); models downloaded dynamically by Play Services; ultra-low CPU/memory usage. | **HIGH (Tier 1 & 2 Core)** |
| **`tflite_flutter` (v0.10.4 / v0.11.0)** | Custom TensorFlow Lite models, Quantized INT8/FP16 models, GPU Delegate, NNAPI, XNNPACK, embeddings | 21+ | **Good**: Uses `dart:ffi` to bind `libtensorflowlite_c.so`. Requires bundling `.so` binaries for `arm64-v8a` & `armeabi-v7a`. | ~15-25MB APK increase. Highly flexible for specialized intent classification or vector embeddings (e.g. MobileBERT / MiniLM). | **HIGH (Custom Embeddings & Offline Intent Engine)** |
| **Google AI Edge / MediaPipe LLM Inference (`mediapipe_genai`)** | On-device SLM execution (Gemma-2B, Gemma-2-2B, TinyLlama 1.1B, Phi-2, Qwen-1.5) | 24+ | **Moderate**: Requires native Android JNI wrapper or experimental Flutter plugin. Model weights 1.2GB - 2.5GB. | Heavy resource footprint (1.5GB+ RAM, requires modern NPU/GPU). Best as an optional modular download rather than default bundled asset. | **MODERATE (Future Modular Extension)** |
| **`flutter_sherpa_onnx` / `onnxruntime`** | Offline Speech-to-Text (Whisper / Sherpa), Voice Activity Detection (Silero VAD), Local Intent ONNX | 21+ | **Good**: Direct ONNX runtime FFI bindings with multi-platform acceleration. | Models range from 15MB (Silero VAD + Small STT) to 150MB (Whisper Tiny). | **HIGH (Offline Speech & VAD)** |

### 3.2 4-Tier Hybrid AI Execution Engine
To maximize speed, reliability, and cost-efficiency, Jack should adopt a 4-tier hybrid execution pipeline:

```
                      ┌──────────────────────────────────────────────┐
                      │             User Spoken / Typed Input        │
                      └──────────────────────┬───────────────────────┘
                                             │
                                             ▼
                 ┌─────────────────────────────────────────────────────────┐
                 │  TIER 1: Native Fast Intent Classifier & Local Rules    │
                 │  - Regex / On-device ML Intent Matcher                  │
                 │  - Direct device actions: Volume, Alarm, Timer, Apps    │
                 │  - 0ms network latency • 100% Offline Reliable          │
                 └───────────────────────────┬─────────────────────────────┘
                                             │ [If complex / conversational]
                                             ▼
                 ┌─────────────────────────────────────────────────────────┐
                 │  TIER 2: On-Device Vision & Screen Grounding (ML Kit)   │
                 │  - Native OCR on Accessibility/Captured Screen Frame    │
                 │  - Entity Extraction (Phone, DateTime, URLs, Addresses) │
                 │  - Extracts exact UI text & bounds coordinates          │
                 └───────────────────────────┬─────────────────────────────┘
                                             │ [Injects extracted context]
                                             ▼
                 ┌─────────────────────────────────────────────────────────┐
                 │  TIER 3: Cloud LLM Orchestration (Groq Versatile)       │
                 │  - llama-3.3-70b-versatile (primary)                    │
                 │  - Multi-step reasoning, tool execution, natural reply  │
                 │  - llama-3.1-8b-instant (fallback on rate limit/429)    │
                 └───────────────────────────┬─────────────────────────────┘
                                             │
                                             ▼
                 ┌─────────────────────────────────────────────────────────┐
                 │  TIER 4: On-Device Semantic Memory & Vector Search      │
                 │  - Local TFLite/ONNX Embeddings (MiniLM-L6)             │
                 │  - Vector cosine similarity over encrypted local SQLite │
                 │  - Fast recall of personal facts, contacts, logs        │
                 └─────────────────────────────────────────────────────────┘
```

---

## 4. Data-Loss Prevention (DLP) & Safe Persistence

### 4.1 Storage Engine Evaluation for DLP
| Storage Engine | ACID Transactions | Encryption Support | Crash Resilience (WAL) | Querying & FTS | Migration Tooling | Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`drift` (`drift_flutter` + `sqlite3_flutter_libs`)** | **Full ACID** (`db.transaction`) | **Yes** (via `sqlcipher_flutter_libs`) | **Excellent** (SQLite WAL mode journaling) | **Full SQL + FTS5** | **Automated schema migrations** with verification tests | **PRIMARY RECOMMENDATION for structured persistence** |
| **`sqflite` (`sqflite` + `sqflite_sqlcipher`)** | **Full ACID** (`db.transaction`, `batch`) | **Yes** (via `sqflite_sqlcipher`) | **Excellent** (Native SQLite engine) | **Standard SQL** | Manual `onUpgrade` script handlers | **STRONG ALTERNATIVE (Minimal dependency footprint)** |
| **`flutter_secure_storage`** | N/A (Key-Value) | **Yes** (Android KeyStore + EncryptedSharedPreferences AES-256 GCM) | **High** | Basic Key/Value | Key versioning | **MANDATORY for Secrets, API Keys & DB Master Key** |
| **`shared_preferences`** | **No** (Eventual async flush) | **No** (Plain XML/Protobuf) | **Poor** for structured data | None | None | **STRICTLY RESTRICTED to trivial UI flags (theme, font scale)** |
| **`isar` (v3 / v4 community)** | Full ACID | Yes (AES-256) | High | Binary indexed | Manual | **Caveat**: AGP 9 / Kotlin 2.3 binary linker risks on modern Android compileSdk 37 |

### 4.2 Comprehensive DLP Architecture Design

```
                                  JACK DLP ARCHITECTURE
 ┌───────────────────────────────────────────────────────────────────────────────────────┐
 │                               SECURE ENCLAVE LAYER                                    │
 │  flutter_secure_storage (Android KeyStore Hardware-backed AES-256 GCM)                │
 │  - Groq Multi-API Keys Pool                                                           │
 │  - Database Master Encryption Key (SQLCipher Seed)                                    │
 │  - User Identity & Auth Credentials                                                   │
 └──────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
                                            ▼
 ┌───────────────────────────────────────────────────────────────────────────────────────┐
 │                       TRANSACTIONAL PERSISTENCE ENGINE (ACID)                         │
 │  drift / sqflite in WAL Mode (Write-Ahead Logging) + Foreign Keys + Soft-Delete       │
 │                                                                                       │
 │  Tables:                                                                              │
 │  • call_logs: [id, contact_name, phone_number, type, timestamp, duration, summary,    │
 │                actions_json, is_deleted, deleted_at, sync_version]                    │
 │  • chat_messages: [id, session_id, role, content, tool_calls_json, timestamp,          │
 │                    is_deleted, deleted_at]                                            │
 │  • user_facts: [id, fact_key, fact_value, category, confidence, created_at,           │
 │                 updated_at, is_deleted, deleted_at, is_sensitive]                     │
 │  • os_audit_trail: [id, command_type, target, element, status, result, timestamp]     │
 │  • recovery_journal: [id, action_type, payload_json, state, timestamp]               │
 └──────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
                                            ▼
 ┌───────────────────────────────────────────────────────────────────────────────────────┐
 │                          DLP HOOKS & SAFETY INTERCEPTORS                              │
 │                                                                                       │
 │  1. Accidental Deletion Guard (HIL & Soft Delete):                                    │
 │     - Destructive operations marked as `is_deleted = 1` with 30-day retention        │
 │     - Two-stage confirmation (Voice/UI dialog) before irreversible purge              │
 │     - Instant "Undo" toast / voice callback buffer                                    │
 │                                                                                       │
 │  2. PII Sanitization & Redaction Hook:                                                │
 │     - Intercepts outgoing LLM payloads and logs                                       │
 │     - Redacts Credit Cards (Luhn), OTPs, Passwords, SSNs, and Auth Tokens             │
 │                                                                                       │
 │  3. Crash Recovery & State Replay Hook:                                               │
 │     - Checkpoints active multi-step workflows to `recovery_journal`                   │
 │     - At startup, detects uncommitted states and offers auto-resume / rollback        │
 │                                                                                       │
 │  4. Encrypted Snapshot Backup & Export / Restore Service:                             │
 │     - Generates AES-256 encrypted JSON/Zip archive with SHA-256 verification hash    │
 │     - Full import validation with schema version migration                            │
 └───────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Compatibility Matrix & SDK Constraints

### 5.1 Environment Constraints Matrix
| Parameter | Current Project Setting | Required / Tested Safe Range | Verification & Notes |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | 3.44.4 (stable) | >= 3.22.0 < 4.0.0 | Verified clean `flutter analyze` and modern Dart 3.12 sound null-safety. |
| **Dart SDK** | 3.12.2 | ^3.12.0 | Full pattern matching, switch expressions, records, and class modifiers supported. |
| **Android AGP** | 9.0.1 (`com.android.application`) | 8.2.0 - 9.0.1 | Requires modern namespace declarations (already present: `namespace = "com.syncra.syncra"`). |
| **Kotlin Plugin** | 2.3.20 (`org.jetbrains.kotlin.android`) | 2.0.0 - 2.3.20 | Kotlin 2.x language features and JVM 17 target compatibility verified. |
| **Android compileSdk** | 37 | 34 - 37 | Android 15/16 preview. All plugins must avoid deprecated Android build flags. |
| **Android minSdk** | `flutter.minSdkVersion` (21) | 21 - 24 | `flutter_secure_storage` prefers 23+ (falls back gracefully to KeyStore on 21-22). ML Kit text recognition requires 21+. |
| **Java Compatibility** | Java 17 (`JavaVersion.VERSION_17`) | Java 17 | Verified matching `jvmTarget = JVM_17`. |

---

## 6. Concrete Package Recommendations for `pubspec.yaml`

To implement the Native ML capabilities and DLP hooks while ensuring zero dependency conflicts and seamless compilation on Flutter 3.44.4 / AGP 9.0.1, the following dependency specification is recommended:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ── Architecture & State Management ──────────────────────────────────────────
  flutter_riverpod: ^2.6.1
  go_router: ^17.5.0

  # ── DLP & Transaction-Safe Persistence ───────────────────────────────────────
  # Primary ACID relational storage with SQLite WAL mode
  sqflite: ^2.4.2
  sqflite_common_ffi: ^2.3.4+4
  path: ^1.9.1
  path_provider: ^2.1.6
  
  # Secure Enclave (Hardware-backed encrypted storage for keys & secrets)
  flutter_secure_storage: ^9.2.4

  # Cryptographic utilities for backup verification and encryption
  crypto: ^3.0.6
  encrypt: ^5.0.3

  # Lightweight non-critical UI settings only
  shared_preferences: ^2.3.5

  # ── Native ML & On-Device Intelligence ───────────────────────────────────────
  # Fast on-device OCR for screen grounding & text extraction
  google_mlkit_text_recognition: ^0.15.0
  
  # On-device entity parsing (dates, flight numbers, addresses, phone numbers)
  google_mlkit_entity_extraction: ^0.15.0
  
  # On-device smart reply generation
  google_mlkit_smart_reply: ^0.15.0

  # On-device TensorFlow Lite runtime (embeddings / custom intent models)
  tflite_flutter: ^0.10.4

  # ── Voice, Speech & Networking ───────────────────────────────────────────────
  speech_to_text: ^7.4.0
  flutter_tts: ^4.2.5
  dio: ^5.11.0
  dio_smart_retry: ^6.0.0
  web_socket_channel: ^3.0.3
  connectivity_plus: ^6.1.4
  intl: ^0.20.2
  url_launcher: ^6.3.1
  permission_handler: ^13.0.0
  installed_apps: ^2.1.1
  workmanager: ^0.10.9

  # ── UI Enhancements & Shaders ───────────────────────────────────────────────
  cupertino_icons: ^1.0.8
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.2
  lottie: ^3.3.1
```

---

## 7. Concrete Service Interfaces & Code Blueprints

### 7.1 DLP Database & Safe Persistence Service Interface (`lib/services/dlp_storage_service.dart`)

```dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/call_log_model.dart';

abstract class IDlpStorageService {
  Future<void> initialize();
  
  // Call Logs (ACID Transactional)
  Future<void> saveCallLog(CallLogEntry entry);
  Future<List<CallLogEntry>> getCallLogs({bool includeDeleted = false, int limit = 50});
  Future<void> softDeleteCallLog(String id);
  Future<void> restoreCallLog(String id);
  Future<void> purgeDeletedCallLogs({Duration retention = const Duration(days: 30)});

  // User Memory & Facts (Encrypted / Structured)
  Future<void> setFact(String key, String value, {bool isSensitive = false});
  Future<String?> getFact(String key);
  Future<Map<String, String>> getAllFacts({bool includeDeleted = false});
  Future<void> softDeleteFact(String key);
  Future<void> undoLastDelete();

  // Chat History & Turn Logs
  Future<void> appendChatMessage(String role, String content, {String? toolCallsJson});
  Future<List<Map<String, dynamic>>> getRecentChatHistory({int limit = 20});
  Future<void> softDeleteChatHistory();

  // Backup & Disaster Recovery
  Future<String> exportEncryptedBackup(String secretKey);
  Future<bool> restoreFromEncryptedBackup(String backupJson, String secretKey);
}

class DlpStorageService implements IDlpStorageService {
  Database? _db;
  static const int _dbVersion = 1;
  static const String _dbName = 'jack_agent_secure.db';

  @override
  Future<void> initialize() async {
    if (_db != null) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enable Write-Ahead Logging for high crash-resilience and concurrency
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE call_logs (
            id TEXT PRIMARY KEY,
            contact_name TEXT,
            phone_number TEXT,
            type TEXT,
            start_time TEXT,
            duration INTEGER,
            ai_summary TEXT,
            jack_actions TEXT,
            is_deleted INTEGER DEFAULT 0,
            deleted_at TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE user_facts (
            fact_key TEXT PRIMARY KEY,
            fact_value TEXT,
            is_sensitive INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT,
            is_deleted INTEGER DEFAULT 0,
            deleted_at TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT,
            content TEXT,
            tool_calls TEXT,
            created_at TEXT,
            is_deleted INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE dlp_audit_journal (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_name TEXT,
            payload_json TEXT,
            timestamp TEXT
          );
        ''');
      },
    );
  }

  @override
  Future<void> saveCallLog(CallLogEntry entry) async {
    final db = _db!;
    await db.transaction((txn) async {
      await txn.insert(
        'call_logs',
        {
          'id': entry.id,
          'contact_name': entry.contactName,
          'phone_number': entry.phoneNumber,
          'type': entry.type.name,
          'start_time': entry.startTime.toIso8601String(),
          'duration': entry.duration?.inSeconds,
          'ai_summary': entry.aiSummary,
          'jack_actions': jsonEncode(entry.jackActions),
          'is_deleted': 0,
          'deleted_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<List<CallLogEntry>> getCallLogs({bool includeDeleted = false, int limit = 50}) async {
    final db = _db!;
    final where = includeDeleted ? null : 'is_deleted = 0';
    final rows = await db.query(
      'call_logs',
      where: where,
      orderBy: 'start_time DESC',
      limit: limit,
    );

    return rows.map((r) => CallLogEntry(
      id: r['id'] as String,
      contactName: r['contact_name'] as String? ?? '',
      phoneNumber: r['phone_number'] as String? ?? '',
      type: CallLogType.values.firstWhere(
        (e) => e.name == r['type'],
        orElse: () => CallLogType.incoming,
      ),
      startTime: DateTime.parse(r['start_time'] as String),
      duration: r['duration'] != null ? Duration(seconds: r['duration'] as int) : null,
      aiSummary: r['ai_summary'] as String?,
      jackActions: r['jack_actions'] != null
          ? (jsonDecode(r['jack_actions'] as String) as List).cast<String>()
          : [],
    )).toList();
  }

  @override
  Future<void> softDeleteCallLog(String id) async {
    final db = _db!;
    await db.update(
      'call_logs',
      {'is_deleted': 1, 'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restoreCallLog(String id) async {
    final db = _db!;
    await db.update(
      'call_logs',
      {'is_deleted': 0, 'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> purgeDeletedCallLogs({Duration retention = const Duration(days: 30)}) async {
    final db = _db!;
    final cutoff = DateTime.now().subtract(retention).toIso8601String();
    await db.delete('call_logs', where: 'is_deleted = 1 AND deleted_at < ?', whereArgs: [cutoff]);
  }

  @override
  Future<void> setFact(String key, String value, {bool isSensitive = false}) async {
    final db = _db!;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'user_facts',
      {
        'fact_key': key,
        'fact_value': value,
        'is_sensitive': isSensitive ? 1 : 0,
        'created_at': now,
        'updated_at': now,
        'is_deleted': 0,
        'deleted_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getFact(String key) async {
    final db = _db!;
    final res = await db.query(
      'user_facts',
      where: 'fact_key = ? AND is_deleted = 0',
      whereArgs: [key],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['fact_value'] as String?;
  }

  @override
  Future<Map<String, String>> getAllFacts({bool includeDeleted = false}) async {
    final db = _db!;
    final where = includeDeleted ? null : 'is_deleted = 0';
    final rows = await db.query('user_facts', where: where);
    return {
      for (final r in rows) r['fact_key'] as String: r['fact_value'] as String,
    };
  }

  @override
  Future<void> softDeleteFact(String key) async {
    final db = _db!;
    await db.update(
      'user_facts',
      {'is_deleted': 1, 'deleted_at': DateTime.now().toIso8601String()},
      where: 'fact_key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> undoLastDelete() async {
    final db = _db!;
    await db.rawUpdate('''
      UPDATE user_facts 
      SET is_deleted = 0, deleted_at = NULL 
      WHERE fact_key = (
        SELECT fact_key FROM user_facts 
        WHERE is_deleted = 1 
        ORDER BY deleted_at DESC 
        LIMIT 1
      )
    ''');
  }

  @override
  Future<void> appendChatMessage(String role, String content, {String? toolCallsJson}) async {
    final db = _db!;
    await db.insert('chat_messages', {
      'role': role,
      'content': content,
      'tool_calls': toolCallsJson,
      'created_at': DateTime.now().toIso8601String(),
      'is_deleted': 0,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentChatHistory({int limit = 20}) async {
    final db = _db!;
    final rows = await db.query(
      'chat_messages',
      where: 'is_deleted = 0',
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.reversed.toList();
  }

  @override
  Future<void> softDeleteChatHistory() async {
    final db = _db!;
    await db.update('chat_messages', {'is_deleted': 1});
  }

  @override
  Future<String> exportEncryptedBackup(String secretKey) async {
    final facts = await getAllFacts();
    final logs = await getCallLogs();
    final payload = {
      'version': _dbVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'facts': facts,
      'call_logs': logs.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(payload); // In production, encrypt using AES-256
  }

  @override
  Future<bool> restoreFromEncryptedBackup(String backupJson, String secretKey) async {
    try {
      final data = jsonDecode(backupJson) as Map<String, dynamic>;
      final facts = (data['facts'] as Map<String, dynamic>?) ?? {};
      final logs = (data['call_logs'] as List?) ?? [];

      for (final e in facts.entries) {
        await setFact(e.key, e.value.toString());
      }
      for (final item in logs) {
        await saveCallLog(CallLogEntry.fromJson(item as Map<String, dynamic>));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

---

### 7.2 Native ML Screen Grounding & OCR Service (`lib/services/native_ml_service.dart`)

```dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

class NativeMlService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final EntityExtractor _entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);

  /// Extract all on-screen UI text and bounding box centroids from captured screen bytes.
  Future<List<ScreenElement>> extractScreenElements(Uint8List imageBytes, int width, int height) async {
    final inputImage = InputImage.fromBytes(
      bytes: imageBytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );

    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    final elements = <ScreenElement>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        elements.add(ScreenElement(
          text: line.text,
          centerX: line.boundingBox.center.dx,
          centerY: line.boundingBox.center.dy,
          confidence: line.confidence,
        ));
      }
    }
    return elements;
  }

  /// Extract structured entities (dates, phone numbers, addresses, flight numbers) locally.
  Future<List<ExtractedEntity>> extractEntities(String text) async {
    final annotations = await _entityExtractor.annotate(text);
    final results = <ExtractedEntity>[];

    for (final annotation in annotations) {
      for (final entity in annotation.entities) {
        results.add(ExtractedEntity(
          rawText: annotation.text,
          type: entity.type.name,
          schema: entity.rawValue,
        ));
      }
    }
    return results;
  }

  void dispose() {
    _textRecognizer.close();
    _entityExtractor.close();
  }
}

class ScreenElement {
  final String text;
  final double centerX;
  final double centerY;
  final double? confidence;

  ScreenElement({required this.text, required this.centerX, required this.centerY, this.confidence});
}

class ExtractedEntity {
  final String rawText;
  final String type;
  final dynamic schema;

  ExtractedEntity({required this.rawText, required this.type, this.schema});
}
```

---

### 7.3 Accidental Deletion & Destructive Action Interceptor (`lib/services/dlp_guard_interceptor.dart`)

```dart
enum ActionRiskLevel { safe, stateModifying, destructive }

class DlpGuardInterceptor {
  /// Classifies agent tools or user voice commands by risk profile.
  static ActionRiskLevel evaluateRisk(String actionName, Map<String, dynamic> params) {
    switch (actionName) {
      case 'clear_memories':
      case 'clear_history':
      case 'forget_fact':
      case 'delete_call_log':
      case 'send_sms':
      case 'directCall':
      case 'lock_screen':
        return ActionRiskLevel.destructive;

      case 'set_alarm':
      case 'set_timer':
      case 'remember_fact':
      case 'set_volume':
        return ActionRiskLevel.stateModifying;

      case 'get_weather':
      case 'get_news':
      case 'search_web':
      case 'get_time':
      case 'get_battery':
      case 'recall_facts':
      default:
        return ActionRiskLevel.safe;
    }
  }

  /// PII Sanitizer: Mask confidential numbers / passwords before logging or external API transmission.
  static String sanitizePii(String input) {
    var sanitized = input;
    // Credit card numbers (13-19 digits)
    sanitized = sanitized.replaceAll(RegExp(r'\b(?:\d[ -]*?){13,19}\b'), '[REDACTED_CARD]');
    // 6-digit OTP codes
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{6}\b'), '[REDACTED_OTP]');
    // Email addresses
    sanitized = sanitized.replaceAll(RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'), '[REDACTED_EMAIL]');
    return sanitized;
  }
}
```

---

## 8. Architecture Rebuild Strategy & Phased Migration Plan

### 8.1 Zero-Downtime Migration Steps
1. **Phase 1 (DLP Safe Storage Baseline)**:
   - Introduce `sqflite` + `flutter_secure_storage`.
   - Implement `DlpStorageService` with automatic migration that reads any existing legacy `SharedPreferences` keys (`jack_call_log`, `jack_memory_facts`, `jack_chat_history`) on first run, imports them into SQLite tables, and flags them as migrated.
   - Refactor `CallLogNotifier`, `MemoryService`, and `AgentStateNotifier` to read/write via `DlpStorageService`.
2. **Phase 2 (Accidental Deletion & PII Guard)**:
   - Wire `DlpGuardInterceptor` into `AgentStateNotifier._executeDomCommands` and `JackTools.call`.
   - Add Human-In-The-Loop voice/dialog prompt for destructive actions (`forget_fact`, `clearAll`).
   - Implement 30-day soft delete and instantaneous "Undo" capability.
3. **Phase 3 (Native ML Integration)**:
   - Integrate `google_mlkit_text_recognition` and `google_mlkit_entity_extraction`.
   - Pre-process captured screen frames on-device to supply OCR coordinates directly to `JackAccessibilityService`, eliminating blind coordinate guessing.
   - Add Tier 1 local rule engine in `AgentStateNotifier.processText` to instantly handle device controls (alarms, timers, volume, app launches) without calling Groq.

---

## 9. Conclusion
Implementing this Native ML + DLP architecture elevates Jack from a cloud-tethered prototype to a resilient, enterprise-grade, privacy-first mobile AI assistant. All recommended packages are thoroughly evaluated for compatibility with Flutter 3.44.4, Dart 3.12.2, Android AGP 9.0.1, and compileSdk 37.
