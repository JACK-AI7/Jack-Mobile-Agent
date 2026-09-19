# Project: Jack Mobile Agent Enhancement & Verification

## Architecture
Jack Mobile Agent is a Flutter + Android OS AI assistant with:
- **Presentation Layer (Flutter)**: `dashboard_screen.dart`, `onboarding_screen.dart`, custom shaders (`shaders/glow.frag`), and glowing mesh orbs (`_Image2Orb`, `uiverse_orb.dart`, `wave_painters.dart`).
- **Agent & Reasoning Layer**: `AgentStateNotifier` (`agent_state_provider.dart`) interfacing with Groq LLM API (`llama-3.3-70b-versatile` primary, `llama-3.1-8b-instant` fallback) using function-calling tools (`jack_tools.dart`).
- **OS Execution & Accessibility Layer**: Native Android platform channels (`com.syncra.syncra/accessibility`) communicating with `MainActivity.kt`, `JackAccessibilityService.kt`, and `JackOverlayService.kt` for UI DOM automation (clicks, text input, gestures, app launching) and system overlay bubble with background microphone capabilities.
- **App Resolution Engine**: 3-tier hybrid resolver mapping spoken app names/aliases to package IDs via static mapping, `installed_apps` plugin, and native Android `PackageManager`.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Onboarding Overflow & Responsive Layout | Prevent RenderFlex overflow on small screens / large font scaling using LayoutBuilder + SingleChildScrollView | M1 | Survey R1 |
| 2 | Route Registration for /call-log | Register `/call-log` route in `app_router.dart` to prevent runtime crash | M1 | Survey R1 |
| 3 | State-Reactive Orb Physics & Idle Breathing | Add idle breathing pulse, state-reactive color transitions (listening, thinking, executing, complete), GPU gradient rotation | M1 | Survey R1 |
| 4 | Shader Premultiplied Alpha & CustomPainter Optimization | Fix `glow.frag` alpha edge artifacts and eliminate 60/120fps setState widget rebuilds in `wave_painters.dart` | M1 | Survey R1 |
| 5 | Clean Deprecations & Deduplicate Widgets | Unify `NeonMicButton`, fix `pulseScale` typo, replace deprecated `.withOpacity` and `Matrix4.scale` | M1 | Survey R1 |
| 6 | Groq Model Standardization | Enforce `llama-3.3-70b-versatile` (primary) and `llama-3.1-8b-instant` (backup); purge misleading comments | M2 | Survey R2 |
| 7 | Multi-Key API Rotation & Header Standardization | Rotate across `_groqKeys` on 429/401; add explicit JSON Content-Type headers | M2 | Survey R2 |
| 8 | Agent Failsafes & Silent Fail / 'Done' Prevention | Fix `<think>` stripping order, preserve `tool_call_id` on exceptions, safe response indexing | M2 | Survey R2 |
| 9 | Compile Error Resolution in Legacy Files | Fix/clean `lib/services/websocket_service.dart` to resolve 5 compile errors | M2 | Survey R2 |
| 10 | 3-Tier App Name to Package Resolver | Map spoken app names (YouTube, WhatsApp, Settings) to package IDs via static dict, `installed_apps`, and native fallback | M3 | Survey R3 |
| 11 | Android 14+ FGS Microphone Permission & Flags | Add `FOREGROUND_SERVICE_MICROPHONE` to AndroidManifest.xml and explicit `startForeground` service type flags in `JackOverlayService.kt` | M3 | Survey R3 |
| 12 | Native Kotlin PackageManager Fallback | Implement fallback query in `MainActivity.kt` and `JackAccessibilityService.kt` for package resolution by app label | M3 | Survey R3 |
| 13 | Comprehensive Verification, Analysis & Build | Verify zero analyzer errors (`flutter analyze`), unit tests, compile verification, and APK build readiness | M4 | Acceptance Criteria |
| 14 | Forensic Audit & Integrity Attestation | Independent forensic audit to guarantee zero cheating, zero hardcoding, and genuine logic | M4 | Project Rules |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | UI Alignment, Layout & Orb Physics (R1) | Onboarding scroll, GoRouter `/call-log`, reactive orb physics, shader alpha, UI deprecations | none | PLANNED |
| 2 | API Reliability, Live Groq Models & Failsafes (R2) | Groq model configs, key rotation, failsafe execution, safe tool IDs, websocket_service clean | none | PLANNED |
| 3 | OS Execution Engine, Installed Apps & Native Services (R3) | AppLauncherHelper 3-tier resolver, AndroidManifest permissions, JackOverlayService Android 14+ FGS flags | M2 | PLANNED |
| 4 | Final Verification, Full Analysis, APK Build & Forensic Audit | Unit tests, `flutter analyze`, compilation/build verification, reviewer/challenger gate, forensic audit | M1, M2, M3 | PLANNED |

## Interface Contracts
### AppLauncherHelper ↔ AgentStateNotifier (`_executeDomCommands`)
- `Future<String> AppLauncherHelper.resolvePackage(String rawInput)`
- Input: `String` (e.g. `"YouTube"`, `"WhatsApp"`, `"com.android.chrome"`, `"insta"`)
- Output: `String` resolved package name (e.g. `"com.google.android.youtube"`, `"com.whatsapp"`, `"com.android.chrome"`, `"com.instagram.android"`)

### Groq API Client ↔ Tool Calling
- `_llmPost(Map<String, dynamic> body)`
- Headers: `Authorization: Bearer <key>`, `Content-Type: application/json`
- Key cycling on 429/401 across `_groqKeys`.
- Returns validated `Response` or falls back to backup model with alternate key.

### Native Android Channels ↔ Flutter
- Channel: `com.syncra.syncra/accessibility`
- Methods: `launchApp(package)`, `clickText(text)`, `typeText(text)`, `swipeUp`, `swipeDown`, `swipeLeft`, `swipeRight`, `pressBack`, `pressHome`, `pressRecents`, `pressEnter`, `lockScreen`, `directCall(number)`.

## Code Layout
- `lib/screens/`: UI Screens (`dashboard_screen.dart`, `onboarding_screen.dart`, `call_log_screen.dart`, `task_result_screen.dart`)
- `lib/widgets/`: Reusable UI widgets, painters, orbs (`uiverse_orb.dart`, `wave_painters.dart`, `neon_mic_button.dart`, `gradient_border.dart`, `shared_widgets.dart`)
- `lib/providers/`: State management (`agent_state_provider.dart`)
- `lib/services/`: Tools and background services (`jack_tools.dart`, `app_launcher_helper.dart`, `termux_socket_service.dart`, `audio_handler.dart`)
- `lib/router/`: Navigation (`app_router.dart`)
- `lib/models/`: Data models (`agent_models.dart`)
- `shaders/`: GLSL shaders (`glow.frag`)
- `android/app/src/main/`: Native Android manifest and Kotlin services (`MainActivity.kt`, `JackAccessibilityService.kt`, `JackOverlayService.kt`)
- `test/`: Unit & widget test suites
