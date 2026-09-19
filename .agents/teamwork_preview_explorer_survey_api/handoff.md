# Comprehensive Survey Report: Requirement 2 (API & Token Validation, Live Groq Models & Agent Failsafes)

## 1. Observation

### 1.1 Groq Model Identifiers Across the Codebase
- **`lib/providers/agent_state_provider.dart`**:
  - Line 102: `static const _primaryModel = 'llama-3.3-70b-versatile';` (Live active model)
  - Line 103: `static const _backupModel = 'llama-3.1-8b-instant';` (Live active model)
  - Line 274: in `_quickGroq`: `'model': 'llama-3.3-70b-versatile',` (Live active model)
  - Lines 722, 733: uses `_primaryModel` and `_backupModel` in `_llmPost`.
  - **Outdated / Misleading Comments**:
    - Line 6: `// Groq qwen/qwen3.6-27b (primary) / openai/gpt-oss-120b (fallback)`
    - Lines 85–87:
      ```dart
      // llama-3.3-70b-versatile is DECOMMISSIONED — switching to Groq's recommended:
      //   Primary  : Qwen3.6 27B     → qwen/qwen3.6-27b
      //   Backup   : GPT OSS 120B    → openai/gpt-oss-120b
      ```
    - Line 688: `// NOTE: We ALWAYS use the text model (qwen3.6-27b) for the main action loop`
    - Line 713: `// Try primary model: qwen/qwen3.6-27b (supports tools)`
    - Line 725: `// Auto-fallback to GPT OSS 120B if Qwen fails`
- **`lib/models/agent_models.dart`**:
  - Line 200: `title: 'Groq Cloud (Llama 3.1 & Whisper)',` (Should mention Llama 3.3 / Llama 3.1).
- **Deprecated Model Scan**:
  - Zero active occurrences of deprecated models (`llama3-70b-8192`, `llama3-8b-8192`, `mixtral-8x7b-32768`, `gemma-7b-it`) found in executable code.

### 1.2 API Key, Token Validation, Header & Timeout Configuration
- **API Key Management (`agent_state_provider.dart`)**:
  - Lines 90–96: Defines a pool of 5 Groq API keys (`_groqKeys`).
  - Line 98: `String get _randomKey => _groqKeys[Random().nextInt(_groqKeys.length)];`
  - **No Key Rotation on Rate-Limit/Error**:
    - Lines 714–735: `_llmPost` receives a single key `key`. If `_primaryModel` throws 429 / 401, the fallback to `_backupModel` uses the identical failing key without cycling.
    - Lines 999–1013: On `DioException` with status code 429, the code speaks `"Too many requests, trying again in a moment."`, delays 3 seconds, and immediately restarts speech listening (`await startListening()`). The original user command is dropped and never retried with another key from `_groqKeys`.
- **Header Formatting (`agent_state_provider.dart`)**:
  - Lines 707–711:
    ```dart
    final headers = {
      'Authorization': 'Bearer $key',
      'HTTP-Referer': 'https://jack-ai.app',
      'X-Title': 'Jack AI Agent',
    };
    ```
    Missing explicit `'Content-Type': 'application/json'`.
- **Timeout Configurations**:
  - `_quickGroq`: `sendTimeout: 8s`, `receiveTimeout: 12s` (Adequate).
  - `_llmPost`: primary `sendTimeout: 18s`, `receiveTimeout: 35s`; backup `sendTimeout: 20s`, `receiveTimeout: 40s` (Adequate).
  - `JackTools._dio`: `connectTimeout: 8s`, `receiveTimeout: 12s` (Adequate).

### 1.3 Agent Execution Loops, Parsing, and Silent Fail / "Done" Risks
- **Issue 1: `<think>` Tag Stripping Timing Causes Silent Fail and False "Done!" Speech**:
  - Lines 935–938:
    ```dart
    if (fullResponse.trim().isEmpty) fullResponse = 'Done.';

    // Strip <think>...</think> tags if present
    fullResponse = fullResponse.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
    ```
    If an LLM response contains only reasoning tags (e.g. `<think>Thinking about opening WhatsApp...</think>`), `fullResponse` is non-empty at line 935. At line 938, `replaceAll` strips the tag, leaving `fullResponse == ""`.
    Then line 945: `_executeDomCommands("")` produces empty string `""`.
    Then line 990: `if (toSpeak.isEmpty) toSpeak = 'Done!';`
    **Result**: The agent executes zero DOM commands, speaks "Done!", and exits silently.
- **Issue 2: Unsafe Response Extraction Crash Risk**:
  - Lines 877–880:
    ```dart
    final resMessage = res.data['choices'][0]['message'] as Map<String, dynamic>;
    final rawToolCalls = resMessage['tool_calls'];
    final textContent = resMessage['content'] as String? ?? '';
    ```
    If `res.data` is malformed, not a Map, or `choices` is empty, `res.data['choices'][0]` throws `RangeError` / `NoSuchMethodError`, aborting to `catch (e)`.
- **Issue 3: Loss of `tool_call_id` in Tool Exception Breaks 2nd Groq Synthesis Call (HTTP 400)**:
  - Lines 887–901:
    ```dart
    for (final tc in rawToolCalls) {
      try {
        final fnName   = tc['function']['name'] as String? ?? '';
        final argsRaw  = tc['function']['arguments'] as String? ?? '{}';
        final fnArgs   = (jsonDecode(argsRaw) as Map?)?.cast<String, dynamic>() ?? {};
        final toolResult = await JackTools.call(fnName, fnArgs);
        toolResultMsgs.add({
          'role': 'tool',
          'tool_call_id': tc['id'] as String? ?? '',
          'content': toolResult,
        });
      } catch (e) {
        toolResultMsgs.add({'role': 'tool', 'tool_call_id': '', 'content': 'Error: $e'});
      }
    }
    ```
    In `catch (e)`, `tool_call_id` is set to `''`. OpenAI/Groq API requires each tool message to have a non-empty `tool_call_id` matching an ID in the assistant's `tool_calls`. Passing `''` triggers HTTP 400 Bad Request on the synthesis call (`res2`).
- **Issue 4: System Prompt Example Contradiction & Missing App Name-to-Package Resolver**:
  - In system prompt (`agent_state_provider.dart` lines 801, 809, 817):
    Prompt examples use `launch: YouTube`, `launch: WhatsApp`, `launch: Settings`.
    However, Android `MainActivity.kt` line 152 does `packageManager.getLaunchIntentForPackage(pkg)` which requires an exact package name (e.g. `com.google.android.youtube`).
    `import 'package:installed_apps/installed_apps.dart';` exists on line 32 of `agent_state_provider.dart`, but `InstalledApps` is never called.
    When the model outputs `launch: YouTube`, `launchApp` returns `false`, no app opens, and the agent says "Done!".
- **Issue 5: Infinite Microphone Restart on Permanent Errors**:
  - Lines 1022 & 1031: On any unhandled exception or network failure, `await startListening()` is unconditionally invoked after 600ms. In a noisy environment or when TTS echoes, this triggers an infinite loop of failed calls.

### 1.4 Flutter Analyze / Compilation Blocker
- Running `flutter analyze` revealed 5 compilation errors in `lib/services/websocket_service.dart`:
  - `lib/services/websocket_service.dart:8:8`: `Target of URI doesn't exist: 'package:record/record.dart'`
  - `lib/services/websocket_service.dart:13:9`: `Undefined class 'AudioRecorder'`
  - `lib/services/websocket_service.dart:13:35`: `The method 'AudioRecorder' isn't defined`
  - `lib/services/websocket_service.dart:58:13`: `The name 'RecordConfig' isn't a class`
  - `lib/services/websocket_service.dart:59:18`: `Undefined identifier 'AudioEncoder'`
  - Note: `websocket_service.dart` is legacy/unused (the app uses `termux_socket_service.dart`), but its existence fails `flutter analyze`.

---

## 2. Logic Chain

1. **Model Selection**:
   - `_primaryModel` is configured as `'llama-3.3-70b-versatile'` and `_backupModel` is `'llama-3.1-8b-instant'`.
   - Both are active, valid Groq production models.
   - However, legacy comments in `agent_state_provider.dart` claiming `llama-3.3-70b-versatile` was decommissioned in favor of `qwen3.6-27b` create confusion for maintainers and future agent operations.
2. **API Reliability**:
   - Groq API free/standard tiers enforce rate limits (RPM/TPM).
   - Currently, a single `_randomKey` is selected at the start of `_callGroq`. When rate-limited (HTTP 429), the request is aborted without attempting other keys in `_groqKeys`.
   - Implementing a key rotation / retry wrapper in `_llmPost` guarantees maximum uptime and prevents user requests from being silently dropped.
3. **Execution Failsafes**:
   - Checking for empty text *after* stripping `<think>` tags and trimming whitespace ensures that thinking-only responses do not masquerade as valid completions.
   - Preserving `tc['id']` regardless of parameter parsing errors prevents Groq HTTP 400 errors during tool synthesis.
   - Providing automatic fuzzy package resolution (mapping spoken names like "youtube" to `com.google.android.youtube` via known maps and `InstalledApps`) guarantees that DOM `launch:` actions succeed even when the LLM outputs casual app names.

---

## 3. Caveats

- **No Caveats**: All relevant files (`lib/providers/agent_state_provider.dart`, `lib/services/jack_tools.dart`, `lib/models/agent_models.dart`, `lib/services/websocket_service.dart`, and `android/app/src/main/kotlin/com/syncra/syncra/MainActivity.kt`) were thoroughly inspected.

---

## 4. Conclusion & Recommended Concrete Fixes

### Recommended Action Plan:
1. **Model & Documentation Cleanliness**:
   - Update `lib/models/agent_models.dart` line 200 title to `'Groq Cloud (Llama 3.3 & Llama 3.1)'`.
   - Clean up misleading comments in `lib/providers/agent_state_provider.dart` (lines 6, 85–87, 688, 713, 725) to accurately state that `llama-3.3-70b-versatile` is Primary and `llama-3.1-8b-instant` is Backup.

2. **Key Rotation & Header Standardization**:
   - Update `_llmPost` to support key rotation: if key $i$ returns 429 or 401, immediately retry with the next key in `_groqKeys`.
   - Add `'Content-Type': 'application/json'` to request headers in `_llmPost`.
   - In `_quickGroq`, add fallback key/backup model if the primary fails.

3. **Agent Failsafe & "Done" Loop Elimination**:
   - In `_callGroq`:
     - Safely parse `res.data` with validation checks before accessing `res.data['choices'][0]['message']`.
     - In tool loop, extract `final tcId = tc['id'] as String? ?? 'call_${DateTime.now().millisecondsSinceEpoch}';` outside the try-catch to guarantee non-empty `tool_call_id`.
     - Place regex tag removal (`<think>[\s\S]*?</think>`) *before* testing if `fullResponse` is empty.
     - If `fullResponse` is empty after cleaning, fallback to a meaningful spoken response (e.g. `"I completed your request."` or query the screen) rather than silently returning `"Done!"`.
   - In system prompt:
     - Update prompt examples (lines 801, 809, 817) to use canonical package names (`launch: com.google.android.youtube`, `launch: com.whatsapp`, `launch: com.android.settings`).
   - In `_executeDomCommands`:
     - Add app-name-to-package resolution before calling `launchApp`:
       ```dart
       String resolvedPkg = pkg;
       if (!resolvedPkg.contains('.')) {
         final known = {
           'youtube': 'com.google.android.youtube',
           'whatsapp': 'com.whatsapp',
           'instagram': 'com.instagram.android',
           'chrome': 'com.android.chrome',
           'settings': 'com.android.settings',
           'spotify': 'com.spotify.music',
           'gmail': 'com.google.android.gm',
           'maps': 'com.google.android.apps.maps',
         };
         resolvedPkg = known[pkg.toLowerCase()] ?? pkg;
         if (!resolvedPkg.contains('.')) {
           final apps = await InstalledApps.getInstalledApps(true, true);
           final match = apps.firstWhere(
             (a) => a.name.toLowerCase().contains(pkg.toLowerCase()),
             orElse: () => AppInfo(),
           );
           if (match.packageName != null && match.packageName!.isNotEmpty) {
             resolvedPkg = match.packageName!;
           }
         }
       }
       ```

4. **Fix Flutter Analyze Compilation Error**:
   - Clean up `lib/services/websocket_service.dart` by removing the unresolved `package:record` imports/calls or updating it to match the project's microphone architecture.

---

## 5. Verification Method

1. **Verify Live Groq Models & Model Strings**:
   - Search:
     ```powershell
     Get-ChildItem -Path "lib" -Recurse -File | Select-String -Pattern "(llama|groq|model)"
     ```
   - Confirm only `llama-3.3-70b-versatile` and `llama-3.1-8b-instant` are configured.
2. **Verify Static Analysis**:
   - Command:
     ```powershell
     flutter analyze
     ```
   - Confirm 0 errors found.
3. **Verify Tool Call & Package Launch Logic**:
   - Check `_callGroq` execution flow with mocked/live tool responses and app launch strings to ensure `tool_call_id` is never blank and app names resolve to valid package IDs.
