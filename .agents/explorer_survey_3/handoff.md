# Handoff Report: Survey Explorer 3 (Native ML & Data-Loss Prevention)

## 1. Observation

### 1.1 Environment & Platform Toolchain
- **Flutter SDK**: `Flutter 3.44.4 • channel stable • Tools • Dart 3.12.2` (Verified via `flutter --version`).
- **Android Gradle Plugin & Kotlin**: `com.android.application` version `9.0.1`, `org.jetbrains.kotlin.android` version `2.3.20` (`android/settings.gradle.kts:22-23`).
- **Target SDK & Compilers**: `compileSdk = 37`, `JavaVersion.VERSION_17`, `JvmTarget.JVM_17` (`android/app/build.gradle.kts:9, 13-14, 41`).
- **Current Analysis Status**: `flutter analyze` runs cleanly with `No issues found! (ran in 41.6s)`.
- **Existing GPU Acceleration Declarations**: `android/app/src/main/AndroidManifest.xml:135-138` already declares native OpenCL support:
  ```xml
  <uses-native-library android:name="libvndksupport.so" android:required="false"/>
  <uses-native-library android:name="libOpenCL.so" android:required="false"/>
  <uses-native-library android:name="libOpenCL-car.so" android:required="false"/>
  <uses-native-library android:name="libOpenCL-pixel.so" android:required="false"/>
  ```

### 1.2 Storage & Persistence Vulnerabilities Observed
- **Call Log Persistence** (`lib/providers/call_log_provider.dart:30-35`):
  ```dart
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(state.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
  ```
  *Risk*: Entire call history is serialized as a single plain-text JSON string in `SharedPreferences`. A crash during write or string corruption destroys all entries. Hardcoded limit of 50 entries.
- **Memory & Facts Persistence** (`lib/services/memory_service.dart:11-19`, `lib/services/jack_tools.dart:464-472`):
  Stored as unencrypted string lists / JSON dictionaries in `SharedPreferences`. No schema, no versioning, no concurrent write locking.
- **Chat History** (`lib/providers/agent_state_provider.dart:187-193`):
  Rewrites entire JSON chat history string on every conversational turn via `SharedPreferences.setString(_prefKey, encoded)`.
- **Destructive Deletion Risk**:
  `CallLogNotifier.clearAll()` (`lib/providers/call_log_provider.dart:51-55`), `JackTools._forgetFact()` (`lib/services/jack_tools.dart:483-491`), and `AgentStateNotifier.clearHistory()` execute instantaneous, irreversible hard deletions with zero confirmation, zero soft-delete tombstones, and zero undo buffers.

### 1.3 Machine Learning Layer Observed
- `pubspec.yaml:41-43`:
  ```yaml
  # ── Local AI / ML ────────────────────────────────────────────────────────────
  # (Removed heavy ML packages that require extra native setup — Groq handles all AI)
  ```
  All reasoning, intent handling, and tool decisions currently depend 100% on cloud Groq API calls. Device-level commands (volume, alarm, timer, app launching) endure unnecessary network latency and rate-limit risks.

---

## 2. Logic Chain

1. **Premise 1 (Storage Fragility)**: `SharedPreferences` is designed for simple key-value UI preferences, not ACID-compliant transactional persistence or relational collections. Storing serialized JSON arrays of business data (`call_logs`, `chat_history`, `user_facts`) creates critical single-point failure vectors where crashes or serialization errors result in total data loss.
2. **Premise 2 (DLP & Safety Requirements)**: An enterprise mobile AI assistant must support ACID transactions, crash recovery (Write-Ahead Logging), encryption-at-rest for sensitive user data, PII masking, soft deletion with 30-day retention, and Human-In-The-Loop (HIL) confirmations before destructive commands.
3. **Premise 3 (Toolchain Compatibility)**: Flutter 3.44.4 / Dart 3.12.2 and AGP 9.0.1 / compileSdk 37 require packages that do not rely on deprecated Android v1 embedding, outdated NDK build scripts, or unmaintained native binaries. `sqflite` (2.4.2) + `flutter_secure_storage` (9.2.4) provide the most stable, battle-tested, zero-conflict foundation for transactional persistence and key storage.
4. **Premise 4 (Native ML Viability)**: Google ML Kit packages (`google_mlkit_text_recognition`, `google_mlkit_entity_extraction`, `google_mlkit_smart_reply`) utilize dynamic Google Play Services runtimes, adding minimal APK size (~2MB) with zero C++ compilation friction on AGP 9.0.1. Coupled with `tflite_flutter` (0.10.4) for custom embeddings, Jack can achieve a 4-tier hybrid execution pipeline (Tier 1: Fast local rules; Tier 2: Screen OCR grounding; Tier 3: Cloud Groq LLM; Tier 4: Local vector memory).
5. **Conclusion**: Migrating Jack's storage to `DlpStorageService` (SQLite WAL + SecureStorage) and introducing `NativeMlService` (ML Kit + TFLite) achieves full Data-Loss Prevention compliance and local AI capabilities without breaking existing UI or OS automation layers.

---

## 3. Caveats

1. **Large Local SLM Weights (Gemma 2B / Phi-2)**: Bundling full 1.5GB+ GGUF/TFLite model weights directly in the APK is impractical for standard distribution and should be treated as an optional on-demand downloadable module (via `flutter_riverpod` download manager) rather than a default asset.
2. **Android KeyStore Hardware Variations**: On older emulators or non-standard Android devices without hardware KeyStore backing, `flutter_secure_storage` automatically falls back to software-based encrypted preferences.
3. **Migration of Live User Data**: When upgrading from legacy `SharedPreferences` to SQLite, an automated migration routine must execute on initial launch to parse existing JSON strings and import them into SQLite tables before deprecating the old keys.

---

## 4. Conclusion

- **Persistence Modernization**: Replace `SharedPreferences` arrays with a transactional SQLite backend (`sqflite` ^2.4.2) configured with Write-Ahead Logging (`PRAGMA journal_mode = WAL;`) and `flutter_secure_storage` (^9.2.4) for master encryption keys and Groq API keys.
- **DLP Safety Hooks**: Introduce `DlpGuardInterceptor` with 3-tier risk evaluation (Safe, State-Modifying, Destructive), automatic PII sanitization (redacting cards, OTPs, emails), 30-day soft deletion tombstones, and instant undo capability.
- **Native ML Intelligence**: Implement `NativeMlService` leveraging `google_mlkit_text_recognition` for on-device screen grounding and `google_mlkit_entity_extraction` for entity parsing, backed by a Tier 1 local rule engine to handle device-level intents with 0ms network latency.
- **Detailed Specification**: Complete architecture schemas, package version matrix, and production code blueprints are documented in `.agents/explorer_survey_3/analysis.md`.

---

## 5. Verification Method

To independently verify the environment, compatibility, and proposed design:

1. **Static Analysis & Lint Check**:
   ```powershell
   flutter analyze
   ```
   *Expectation*: Zero analyzer errors or warnings.

2. **Package Dependency Resolution**:
   Validate proposed packages in `pubspec.yaml`:
   ```powershell
   flutter pub get
   ```
   *Expectation*: Resolves cleanly with 0 dependency version conflicts.

3. **Compilation & Native Build Verification**:
   ```powershell
   flutter build apk --debug
   ```
   *Expectation*: Compiles successfully against Android compileSdk 37 and AGP 9.0.1.

4. **Inspect Analysis Artifacts**:
   Inspect the full design blueprint at `c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\explorer_survey_3\analysis.md`.
