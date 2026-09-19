## 2026-08-24T16:33:49Z

You are a Worker subagent implementing Milestone 3: OS Execution Engine, Installed Apps Mapping & Native Services (Requirement 3).

Your working directory is: c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_worker_m3

MANDATORY FIRST STEP:
1. Read the original request at c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\ORIGINAL_REQUEST.md.
2. Read the project scope at c:\Users\bjasw\Downloads\jack-mobile-agent\PROJECT.md.
3. Read the detailed survey report at c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_explorer_survey_os\handoff.md.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Scope & Exclusively Owned Files:
- `lib/services/app_launcher_helper.dart` (create / update)
- `lib/services/jack_tools.dart`
- `lib/providers/agent_state_provider.dart` (DOM app launch command section)
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/syncra/syncra/MainActivity.kt`
- `android/app/src/main/kotlin/com/syncra/syncra/JackOverlayService.kt`
- `android/app/src/main/kotlin/com/syncra/syncra/JackAccessibilityService.kt`
- `test/m3_app_launcher_test.dart`

Tasks to Implement:
1. 3-Tier App Resolution Engine:
   - Create `lib/services/app_launcher_helper.dart` with:
     - Tier 1: Extensive static dictionary of ~60 common app names, spoken aliases, abbreviations (`"yt"`, `"youtube"`, `"wa"`, `"whatsapp"`, `"insta"`, `"instagram"`, `"chrome"`, `"settings"`, `"camera"`, `"maps"`, `"spotify"`, `"netflix"`, `"gmail"`, `"photos"`, `"clock"`, `"calculator"`, `"play store"`, `"twitter"`, `"x"`, `"telegram"`, `"uber"`, `"amazon"`, etc.) mapped to package names.
     - Tier 2: Dynamic lookup using `InstalledApps.getInstalledApps(excludeSystemApps: false, withIcon: false)`: exact name match, stripped-spaces match, partial/contains match, and package name passthrough.
     - Fast synchronous resolution method `resolvePackageSync(String query)` and async dynamic method `resolvePackage(String rawInput)`.
   - Wire `AppLauncherHelper` into `_executeDomCommands` in `agent_state_provider.dart` when handling `launch: <pkg/name>`.
2. Android 14+ (API 34+) Foreground Service & Microphone Permission:
   - In `android/app/src/main/AndroidManifest.xml`:
     - Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />` under `<manifest>`.
     - Confirm `<service android:name=".JackOverlayService" android:foregroundServiceType="specialUse|microphone">` contains `<property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="jack_dom_overlay" />`.
3. Native Kotlin Services:
   - In `JackOverlayService.kt`: Update `startForeground` in `onCreate()` to pass Android 14+ FGS type flags (`ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE` on `Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE`).
   - In `MainActivity.kt` and `JackAccessibilityService.kt`: Implement native `findPackageByNameOrLabel` fallback using `packageManager.queryIntentActivities` so if `getLaunchIntentForPackage` returns null when given a raw app name, it resolves the package from launchable activities on the device.
4. Comprehensive Automated Tests:
   - Create `test/m3_app_launcher_test.dart` covering package name passthrough, static map resolution for common apps & aliases, case-insensitivity, whitespace tolerance, and fallback behavior.

Verification:
- Run `flutter analyze` across all owned files.
- Run `flutter test test/m3_app_launcher_test.dart` and `flutter test`.
- Document all changes and verification outputs in `c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_worker_m3\handoff.md`.

Update progress.md in your directory as you work. Send parent a message upon completion.
