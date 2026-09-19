## 2026-08-25T14:31:40Z
You are a specialist Worker agent for Milestone 3 of the Jack Mobile Agent project.

Working Directory: c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_worker_m3_2
Project Root: c:\Users\bjasw\Downloads\jack-mobile-agent
Authoritative User Request: c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\ORIGINAL_REQUEST.md
Master Project Plan: c:\Users\bjasw\Downloads\jack-mobile-agent\PROJECT.md
Survey Report: c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_explorer_survey_os\handoff.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Tasks:
1. Initialize your working directory with DISPATCH.md, BRIEFING.md, and progress.md.
2. Read ORIGINAL_REQUEST.md, PROJECT.md, and Survey Report.
3. Implement `lib/services/app_launcher_helper.dart`:
   - 3-tier resolution engine:
     - Tier 1: Static dictionary of 30+ common app aliases/names (youtube, whatsapp, chrome, settings, camera, spotify, maps, gmail, instagram, twitter/x, telegram, netflix, clock, calculator, contacts, messages, gallery/photos, discord, uber, reddit, tiktok, etc.) -> package IDs.
     - Tier 2: `InstalledApps.getInstalledApps(true, true)` querying on-device apps and matching by `name` or `package_name` (case-insensitive substring/exact match).
     - Tier 3: Native platform channel fallback `resolveAppPackage` querying Android `PackageManager`.
   - Methods: `Future<String> resolvePackage(String rawInput)` and `Future<bool> launchApp(String rawInput)`.
4. Wire `AppLauncherHelper` into `lib/providers/agent_state_provider.dart` (`_executeDomCommands` when handling `launch: [name/pkg]`) and `lib/services/jack_tools.dart`.
5. Update `android/app/src/main/AndroidManifest.xml`:
   - Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />`.
   - Verify `<service android:name=".JackOverlayService" ... android:foregroundServiceType="specialUse|microphone">` has `<property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="jack_dom_overlay" />`.
6. Update `android/app/src/main/kotlin/com/syncra/syncra/JackOverlayService.kt`:
   - In `onCreate()`, on Android 14+ (API 34 / Build.VERSION_CODES.UPSIDE_DOWN_CAKE), call `startForeground` with explicit foregroundServiceType flags: `ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE` (with backward compatibility for API < 34 and API < 29).
7. Update `android/app/src/main/kotlin/com/syncra/syncra/MainActivity.kt` and `JackAccessibilityService.kt`:
   - In `MainActivity.kt`, add method channel handler for `resolveAppPackage(query)` that searches installed packages via `packageManager` matching application label.
   - In `launchApp` handler, if `packageManager.getLaunchIntentForPackage(pkg)` is null, fallback to searching installed apps by label before giving up.
8. Create `test/m3_app_launcher_test.dart` testing the 3-tier resolver logic, static mapping, and edge cases.
9. Run `flutter test` and `flutter analyze`. Fix any issues to ensure 0 errors.
10. Write `handoff.md` with complete documentation, verification results, and notify via send_message.
