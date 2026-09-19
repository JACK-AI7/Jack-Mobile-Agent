## 2026-08-24T16:19:39Z

You are a replacement Worker subagent implementing Milestone 2: API Reliability, Live Groq Models & Failsafes (Requirement 2 & Analyzer Blocker).

Your working directory is: c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_worker_m2_2

MANDATORY FIRST STEP:
1. Read the original request at c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\ORIGINAL_REQUEST.md.
2. Read the project scope at c:\Users\bjasw\Downloads\jack-mobile-agent\PROJECT.md.
3. Read the detailed survey report at c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_explorer_survey_api\handoff.md.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Scope & Exclusively Owned Files:
- `lib/providers/agent_state_provider.dart`
- `lib/models/agent_models.dart`
- `lib/services/websocket_service.dart`

Tasks to Implement:
1. Model Standardization & Comment Cleanliness:
   - Ensure `_primaryModel` is strictly `'llama-3.3-70b-versatile'` and `_backupModel` is `'llama-3.1-8b-instant'`.
   - Update `lib/models/agent_models.dart` line 200 title to `'Groq Cloud (Llama 3.3 & Llama 3.1)'`.
   - Purge all outdated/misleading comments in `agent_state_provider.dart` (lines 6, 85-87, 688, 713, 725) claiming `llama-3.3-70b-versatile` is decommissioned or referencing `qwen` / `gpt-oss`.
2. Multi-Key API Rotation & Header Standardization:
   - In `_llmPost`, implement intelligent key rotation: on HTTP 429 (rate limit) or 401, cycle to the next key in `_groqKeys` and retry rather than dropping user commands.
   - Add `'Content-Type': 'application/json'` to request headers in `_llmPost` and `_quickGroq`.
   - Add backup model fallback with key rotation in `_quickGroq`.
3. Agent Failsafes & Silent Fail / 'Done' Loop Elimination:
   - In `_callGroq`:
     - Safely validate `res.data` before indexing `res.data['choices'][0]['message']`.
     - Extract `tcId = tc['id'] as String? ?? 'call_${DateTime.now().millisecondsSinceEpoch}'` outside the try-catch block so `tool_call_id` is NEVER empty `''` (which causes Groq HTTP 400 on synthesis call).
     - Move `<think>[\s\S]*?</think>` regex removal *before* checking if response is empty.
     - If response is empty after stripping reasoning, provide a sensible spoken fallback rather than speaking "Done!" with 0 actions.
4. Resolve `websocket_service.dart` Analyzer Compilation Errors:
   - Fix `lib/services/websocket_service.dart` so it compiles cleanly without missing package references (or stub/clean it safely so `flutter analyze` produces 0 errors).

Verification:
- Run `flutter analyze` to verify compilation and zero analyzer errors.
- Document all modified files, diffs, and verification commands in `c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_worker_m2_2\handoff.md`.

Update progress.md in your directory as you work. Send parent a message upon completion.
