# Requirement 3 Survey Report: OS Execution Engine, App Launching, Installed Apps Mapping & Native Services

## 1. Observation

### 1.1 Tool Engine and DOM Action Execution
- **File**: `lib/services/jack_tools.dart`
  - Lines 33–241: Declares 16 function-calling tools schemas for Groq (`get_weather`, `get_news`, `search_web`, `get_time`, `get_battery`, `get_upcoming_events`, `search_contact`, `remember_fact`, `recall_facts`, `forget_fact`, `send_sms`, `generate_image`, `set_alarm`, `set_timer`, `set_volume`, `compose_smart_reply`).
  - Lines 28–29: Defines `MethodChannel('com.syncra.syncra/accessibility')`.
  - Lines 369–449: Dispatches OS-level actions to native platform channels (`getCalendarEvents`, `searchContact`, `getBatteryLevel`, `sendSMS`, `setAlarm`, `setTimer`, `setVolume`).
- **File**: `lib/providers/agent_state_provider.dart`
  - Lines 321–473 (`_executeDomCommands`): Parses Groq text responses for DOM action prefixes and routes them:
    - `click: [text]` (lines 329–339) -> `_platform.invokeMethod('clickText', {'text': target})`
    - `type: [text]` (lines 340–350) -> `_platform.invokeMethod('typeText', {'text': text})`
    - `swipe: up` / `swipeUp` (lines 351–360) -> `_platform.invokeMethod('swipeUp')`
    - `swipe: down` (lines 361–370) -> `_platform.invokeMethod('swipeDown')`
    - `swipe: left` / `swipe: right` (lines 419–430) -> `_platform.invokeMethod('swipeLeft')` / `swipeRight`
    - `pressBack`, `pressHome`, `pressRecents` (lines 431–454) -> invokes `pressBack`, `pressHome`, `pressRecents`
    - `pressEnter` (lines 437–442) -> `_platform.invokeMethod('pressEnter')`
    - `pullNotifications`, `pullQuickSettings` (lines 455–466) -> invokes `pullNotifications`, `pullQuickSettings`
    - `lock_screen` (lines 413–418) -> `_platform.invokeMethod('lockScreen')`
    - `call: [num]` (lines 396–412) -> `_platform.invokeMethod('directCall', {'number': numStr})`
    - `open: [url]` (lines 382–395) -> `launchUrl(uri, mode: LaunchMode.externalApplication)`
    - `launch: [pkg]` (lines 371–381):
      ```dart
      } else if (line.startsWith('launch:')) {
        final pkg = line.substring(7).trim();
        await _haptic();
        state = state.copyWith(
          status: AgentStatus.executingOS,
          currentCmd: 'Opening app...',
          osLog: [...state.osLog, OsCommand(type: OsCommandType.intent, timestamp: DateTime.now(), target: pkg)],
        );
        await _platform.invokeMethod('launchApp', {'package': pkg}).catchError((_) {});
        await Future.delayed(const Duration(milliseconds: 800));
      ```

### 1.2 App Launching & `installed_apps` Plugin Disconnect
- **File**: `pubspec.yaml`
  - Line 48: `installed_apps: ^2.1.1` is declared as a dependency.
- **File**: `lib/providers/agent_state_provider.dart`
  - Line 32: `import 'package:installed_apps/installed_apps.dart';` is imported.
  - **Zero usage**: `InstalledApps` is never referenced anywhere in `agent_state_provider.dart` or any other file in `lib/`.
  - Lines 773–796: Prompt contains a hardcoded list of 21 apps (`youtube -> com.google.android.youtube`, etc.).
  - Lines 800–820: Few-shot examples in system prompt explicitly demonstrate app names instead of package names:
    - Line 801: `launch: YouTube`
    - Line 809: `launch: WhatsApp`
    - Line 817: `launch: Settings`
- **File**: `android/app/src/main/kotlin/com/syncra/syncra/MainActivity.kt`
  - Lines 144–173:
    ```kotlin
    "launchApp" -> {
        val pkg = call.argument<String>("package")
        if (pkg != null) {
            try {
                val launched = svc?.performLaunchApp(pkg) ?: false
                if (!launched) {
                    val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                    if (launchIntent != null) {
                        launchIntent.addFlags(...)
                        startActivity(launchIntent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                } else {
                    result.success(true)
                }
            } catch (ex: Exception) {
                result.success(false)
            }
        }
    }
    ```
- **File**: `android/app/src/main/kotlin/com/syncra/syncra/JackAccessibilityService.kt`
  - Lines 246–254:
    ```kotlin
    fun performLaunchApp(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
                ?: return false
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            applicationContext.startActivity(intent)
            true
        } catch (e: Exception) { false }
    }
    ```
  - Both `JackAccessibilityService.performLaunchApp` and `MainActivity` pass the raw string to `packageManager.getLaunchIntentForPackage(pkg)`.
  - When the LLM generates `launch: YouTube` (or any app name like "Chrome", "Camera", "Spotify", "Clock"), `getLaunchIntentForPackage("YouTube")` returns `null`, and the launch fails silently.

### 1.3 Native Android Manifest & Services (`JackOverlayService`, Accessibility, Permissions)
- **File**: `android/app/src/main/AndroidManifest.xml`
  - Lines 93–100:
    ```xml
    <!-- System-wide floating bubble overlay service -->
    <service
        android:name=".JackOverlayService"
        android:exported="false"
        android:foregroundServiceType="specialUse|microphone">
        <property
            android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
            android:value="jack_dom_overlay" />
    </service>
    ```
  - Declared permissions (Lines 2–47):
    - `RECORD_AUDIO` (Line 3)
    - `FOREGROUND_SERVICE` (Line 36)
    - `FOREGROUND_SERVICE_SPECIAL_USE` (Line 37)
    - `SYSTEM_ALERT_WINDOW` (Line 33)
    - `QUERY_ALL_PACKAGES` (Line 45)
    - `RECEIVE_BOOT_COMPLETED` (Line 38)
    - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (Line 39)
    - `POST_NOTIFICATIONS` (Line 11)
    - `CALL_PHONE`, `READ_CONTACTS`, `SEND_SMS`, `READ_SMS`, `READ_PHONE_STATE`, `PROCESS_OUTGOING_CALLS`, `ANSWER_PHONE_CALLS`, `READ_CALENDAR`, etc.
  - **Missing Permission**: `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />` is **NOT declared**.
- **File**: `android/app/src/main/kotlin/com/syncra/syncra/JackOverlayService.kt`
  - Lines 59–64:
    ```kotlin
    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())
    }
    ```
  - Calls 2-argument `startForeground(NOTIF_ID, buildNotification())` without passing Android 14+ `ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE`.

### 1.4 Flutter Analyze & Build Diagnostics
- Command `flutter analyze` was executed on the workspace.
- **Diagnostic Result**: 71 issues found, with 5 critical compile errors in `lib/services/websocket_service.dart`:
  - `lib/services/websocket_service.dart:8:8`: Target of URI doesn't exist: `'package:record/record.dart'`
  - `lib/services/websocket_service.dart:13:9`: Undefined class `'AudioRecorder'`
  - `lib/services/websocket_service.dart:13:35`: The method `'AudioRecorder'` isn't defined for `'WebSocketService'`
  - `lib/services/websocket_service.dart:58:13`: The name `'RecordConfig'` isn't a class
  - `lib/services/websocket_service.dart:59:18`: Undefined name `'AudioEncoder'`
  - Note: `websocket_service.dart` is dead/legacy code (the app uses `termux_socket_service.dart` via `termuxSocketProvider`), but causes `flutter analyze` exit code 1.

---

## 2. Logic Chain

1. **App Launching Failure Chain**:
   - Observation 1.1 shows that `_executeDomCommands` in `agent_state_provider.dart` takes `pkg = line.substring(7).trim()` and passes it directly to `_platform.invokeMethod('launchApp', {'package': pkg})`.
   - Observation 1.2 shows that the LLM system prompt examples use `launch: YouTube`, `launch: WhatsApp`, and `launch: Settings`.
   - Observation 1.2 shows that `JackAccessibilityService.performLaunchApp` and `MainActivity.kt` use `packageManager.getLaunchIntentForPackage(pkg)` directly.
   - On Android, `getLaunchIntentForPackage` strictly requires an Android application ID/package name (e.g. `com.google.android.youtube`). Given `"YouTube"`, it returns `null`.
   - Because `installed_apps` is never invoked and no package resolution or fuzzy matching occurs in Dart or Kotlin, any app launched via common name fails silently.

2. **Android 14+ Foreground Service Crash Chain**:
   - Observation 1.3 shows `JackOverlayService` specifies `android:foregroundServiceType="specialUse|microphone"` in `AndroidManifest.xml`.
   - On Android 14+ (API 34+), Android enforces that any foreground service declaring type `microphone` MUST declare `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />` in `AndroidManifest.xml` and hold `RECORD_AUDIO` runtime permission.
   - Because `FOREGROUND_SERVICE_MICROPHONE` is missing from `AndroidManifest.xml`, calling `startForegroundService` / `startForeground` on Android 14+ devices throws a fatal `SecurityException` (`Starting FGS with type microphone caller ... requires android.permission.FOREGROUND_SERVICE_MICROPHONE`).

3. **Accessibility Press Enter API Version Compatibility**:
   - In `JackAccessibilityService.kt` (lines 183–203), `performPressEnter` is guarded by `if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)`.
   - On Android 12 and below (API < 33), pressing Enter/Search in text fields returns `false` without performing any action.

4. **Static Analysis Failure**:
   - Observation 1.4 confirms that `lib/services/websocket_service.dart` fails compilation due to missing `package:record`, preventing `flutter analyze` from passing with exit code 0.

---

## 3. Caveats

- **Device-Specific Package Names**: Certain OEM pre-installed apps (e.g., Camera, Calculator, Gallery) have different package names across Samsung (`com.sec.android.app.camera`), Xiaomi (`com.android.camera`), Pixel (`com.google.android.GoogleCamera`), and OnePlus. Therefore, static mapping alone is insufficient; dynamic resolution via `InstalledApps.getInstalledApps()` or PackageManager querying is required.
- **Microphone Background Restrictions on Android 14+**: Even with `FOREGROUND_SERVICE_MICROPHONE` declared, Android 14 restricts starting microphone foreground services while the app is in the background unless the app was granted an exemption or was started from a user interaction (such as the notification, overlay bubble, or accessibility service).

---

## 4. Conclusion & Proposed Concrete Solutions

### 4.1 Solution 1: Comprehensive App Resolution & Fuzzy Matching Engine
Implement a robust, 3-tier App Resolution Engine in `lib/services/jack_tools.dart` or a dedicated app resolver:
1. **Tier 1 — Static Normalization Map**: Map ~60 common app names, abbreviations, and spoken aliases (`"yt"`, `"youtube"`, `"wa"`, `"whatsapp"`, `"gmaps"`, `"maps"`, `"chrome"`, `"insta"`, `"instagram"`, `"camera"`, `"settings"`, `"calculator"`, `"clock"`, `"calendar"`, `"photos"`, `"play store"`, etc.) to standard package names.
2. **Tier 2 — Dynamic Installed Apps Fuzzy Matcher via `installed_apps`**:
   - Cache installed apps at startup using `InstalledApps.getInstalledApps(true, true)`.
   - When resolving `target`:
     - If `target` is already a package name (contains `.` and matches an installed app or pattern `com.*`), use it directly.
     - Check static map.
     - Search installed apps list: exact match on `app.name.toLowerCase()`, then substring match, then Levenshtein/token similarity.
3. **Tier 3 — Native Kotlin PackageManager Fallback in `MainActivity.kt` & `JackAccessibilityService.kt`**:
   - If `packageManager.getLaunchIntentForPackage(pkg)` is null, iterate `packageManager.getInstalledApplications(0)`, compare `appInfo.loadLabel(packageManager).toString().toLowerCase()` to `pkg.toLowerCase()`, and retrieve the launch intent for the matched package.

#### Proposed Code for Dart App Resolution (`lib/services/jack_tools.dart` or helper):
```dart
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppLauncherHelper {
  static List<AppInfo>? _cachedApps;

  static const Map<String, String> _staticPackageMap = {
    'youtube': 'com.google.android.youtube',
    'yt': 'com.google.android.youtube',
    'whatsapp': 'com.whatsapp',
    'wa': 'com.whatsapp',
    'instagram': 'com.instagram.android',
    'insta': 'com.instagram.android',
    'chrome': 'com.android.chrome',
    'google chrome': 'com.android.chrome',
    'settings': 'com.android.settings',
    'gmail': 'com.google.android.gm',
    'mail': 'com.google.android.gm',
    'maps': 'com.google.android.apps.maps',
    'google maps': 'com.google.android.apps.maps',
    'spotify': 'com.spotify.music',
    'netflix': 'com.netflix.mediaclient',
    'camera': 'com.android.camera2',
    'calculator': 'com.google.android.calculator',
    'clock': 'com.android.deskclock',
    'play store': 'com.android.vending',
    'google play': 'com.android.vending',
    'twitter': 'com.twitter.android',
    'x': 'com.twitter.android',
    'telegram': 'org.telegram.messenger',
    'zomato': 'com.application.zomato',
    'swiggy': 'in.swiggy.android',
    'phonepe': 'com.phonepe.app',
    'paytm': 'net.one97.paytm',
    'amazon': 'in.amazon.mShop.android.shopping',
    'flipkart': 'com.flipkart.android',
    'snapchat': 'com.snapchat.android',
    'photos': 'com.google.android.apps.photos',
    'gallery': 'com.google.android.apps.photos',
    'drive': 'com.google.android.apps.docs',
    'calendar': 'com.google.android.calendar',
    'uber': 'com.ubercab',
    'ola': 'com.olacabs.customer',
  };

  static Future<String> resolvePackage(String rawInput) async {
    final query = rawInput.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9.]'), '');
    if (query.isEmpty) return rawInput;

    // 1. Direct package match
    if (query.contains('.') && query.startsWith('com.') || query.startsWith('org.') || query.startsWith('in.') || query.startsWith('net.')) {
      return rawInput.trim();
    }

    // 2. Static dictionary match
    if (_staticPackageMap.containsKey(query)) {
      return _staticPackageMap[query]!;
    }

    // 3. Dynamic lookup via installed_apps
    try {
      _cachedApps ??= await InstalledApps.getInstalledApps(true, true);
      if (_cachedApps != null && _cachedApps!.isNotEmpty) {
        // Exact name match
        for (final app in _cachedApps!) {
          final name = app.name.trim().toLowerCase();
          if (name == query || name.replaceAll(' ', '') == query) {
            return app.packageName;
          }
        }
        // Substring / contains match
        for (final app in _cachedApps!) {
          final name = app.name.trim().toLowerCase();
          if (name.contains(query) || query.contains(name)) {
            return app.packageName;
          }
        }
      }
    } catch (_) {}

    return _staticPackageMap[query] ?? rawInput.trim();
  }
}
```

### 4.2 Solution 2: Fix `AndroidManifest.xml` Permissions for Android 14+
Add the missing `FOREGROUND_SERVICE_MICROPHONE` permission in `android/app/src/main/AndroidManifest.xml`:
```xml
    <!-- Keep overlay service alive in background -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
```

### 4.3 Solution 3: Update `JackOverlayService.kt` Foreground Service Invocation
In `android/app/src/main/kotlin/com/syncra/syncra/JackOverlayService.kt`:
```kotlin
    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var fgsType = android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                fgsType = fgsType or android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            }
            startForeground(NOTIF_ID, buildNotification(), fgsType)
        } else {
            startForeground(NOTIF_ID, buildNotification())
        }
    }
```

### 4.4 Solution 4: Native Kotlin PackageManager Fallback in `MainActivity.kt` & `JackAccessibilityService.kt`
In `MainActivity.kt` and `JackAccessibilityService.kt`:
```kotlin
    fun findPackageByNameOrLabel(nameOrPkg: String): String? {
        val pm = packageManager
        // 1. Try direct package name
        val directIntent = pm.getLaunchIntentForPackage(nameOrPkg)
        if (directIntent != null) return nameOrPkg

        // 2. Query all launchable apps
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val apps = pm.queryIntentActivities(mainIntent, 0)
        val cleanQuery = nameOrPkg.trim().lowercase()

        // Match by exact label
        for (ri in apps) {
            val label = ri.loadLabel(pm).toString().trim().lowercase()
            if (label == cleanQuery || label.replace(" ", "") == cleanQuery) {
                return ri.activityInfo.packageName
            }
        }
        // Match by partial label
        for (ri in apps) {
            val label = ri.loadLabel(pm).toString().trim().lowercase()
            if (label.contains(cleanQuery) || cleanQuery.contains(label)) {
                return ri.activityInfo.packageName
            }
        }
        return null
    }
```

### 4.5 Solution 5: Clean Up / Fix `websocket_service.dart` for Zero Analyzer Errors
Either remove or stub `lib/services/websocket_service.dart` (which is unused legacy code superseded by `termux_socket_service.dart`), or add the missing `record` dependency to `pubspec.yaml`.

---

## 5. Verification Method

### 5.1 Static Analysis Verification
Run:
```powershell
flutter analyze
```
Expected result: 0 errors, analysis completes cleanly.

### 5.2 Build Verification
Run:
```powershell
flutter build apk --debug
```
Expected result: Build succeeds with exit code 0.

### 5.3 App Launch & Resolution Verification
- Test passing App Name `"YouTube"` -> verify it resolves to `com.google.android.youtube`.
- Test passing App Name `"WhatsApp"` -> verify it resolves to `com.whatsapp`.
- Test passing App Name `"Settings"` -> verify it resolves to `com.android.settings`.
- Test passing package name `"com.android.chrome"` -> verify it passes through unchanged.
- Test fuzzy/spoken names (`"YT"`, `"Google Maps"`, `"Insta"`) -> verify matching to correct installed package.

### 5.4 Foreground Service Verification
- Verify `AndroidManifest.xml` contains both `FOREGROUND_SERVICE_SPECIAL_USE` and `FOREGROUND_SERVICE_MICROPHONE`.
- Verify `JackOverlayService` starts foreground service without `SecurityException` on Android 14 (API 34) and API 35.
