# Survey & Dependency Analysis Report: Jack Mobile Agent

**Agent**: Survey Explorer 1 (`explorer_survey_1`)  
**Date**: 2026-08-25  
**Project Root**: `c:\Users\bjasw\Downloads\jack-mobile-agent`  
**Status**: Comprehensive Investigation Complete  

---

## 1. Executive Summary

A comprehensive teardown, dependency audit, Android build configuration check, and static analyzer diagnostic was conducted on the **Jack Mobile Agent** project.

### Key Highlights
- **Flutter & Dart SDK**: Flutter `3.44.4` (channel stable), Dart `3.12.2`, DevTools `2.57.0`. `pubspec.yaml` environment constraint: `sdk: ^3.12.2`.
- **Flutter Diagnostics**:
  - `flutter pub get`: **PASSED (0 errors)**.
  - `flutter analyze`: **PASSED (0 issues found)**.
  - `flutter test`: **PASSED (9/9 unit and widget tests passing)**.
- **Android Build Configuration**:
  - Gradle Wrapper: `9.1.0` (`gradle-9.1.0-all.zip`)
  - Android Gradle Plugin (AGP): `9.0.1` (Kotlin DSL `settings.gradle.kts`)
  - Kotlin Version: `2.3.20`
  - Java / JVM Target: `JavaVersion.VERSION_17` / `JVM_17`
  - Compile SDK: `37` (Android 15 / vanilla Android Q+)
  - Min SDK / Target SDK: Derived from Flutter SDK (`minSdk = flutter.minSdkVersion` [21], `targetSdk = flutter.targetSdkVersion`)
  - Gradle Configuration dry-run (`gradlew tasks --dry-run`): **BUILD SUCCESSFUL (1m 47s)**.

---

## 2. Dependency Audit & SDK Constraints

### 2.1 SDK Constraints
- **pubspec.yaml**:
  ```yaml
  environment:
    sdk: ^3.12.2
  ```
- **Active Environment**: Dart `3.12.2`, Flutter `3.44.4`. Matches the constraint exactly.

### 2.2 Declared vs. Actively Imported Dependencies

| Package | Declared Version | Resolved Version | Actively Used in `lib/` | Primary Location / Purpose | Outdated Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `flutter` | `sdk: flutter` | `0.0.0` | **Yes** | Core Flutter framework | Up to date |
| `flutter_riverpod` | `^2.6.1` | `2.6.1` | **Yes** | `lib/main.dart`, `lib/providers/*` | `3.4.2` available (breaking v3) |
| `go_router` | `^17.5.0` | `17.5.0` | **Yes** | `lib/router/app_router.dart`, `lib/screens/*` | `18.0.0` available |
| `dio` | `^5.11.0` | `5.11.0` | **Yes** | `lib/providers/agent_state_provider.dart` (Groq API client) | Up to date |
| `web_socket_channel` | `^3.0.3` | `3.0.3` | **Yes** | `lib/services/websocket_service.dart` | Up to date |
| `google_fonts` | `^6.2.1` | `6.3.3` | **Yes** | `lib/theme/app_theme.dart` (Inter / Outfit fonts) | `8.2.1` available |
| `speech_to_text` | `^7.4.0` | `7.4.0` | **Yes** | `lib/providers/agent_state_provider.dart` | Up to date |
| `flutter_tts` | `^4.2.5` | `4.2.5` | **Yes** | `lib/providers/agent_state_provider.dart` | Up to date |
| `permission_handler` | `^13.0.0` | `13.0.0` | **Yes** | `lib/screens/onboarding_screen.dart`, `lib/providers/agent_state_provider.dart` | `13.0.1` available |
| `installed_apps` | `^2.1.1` | `2.1.1` | **Yes** | `lib/services/app_launcher_helper.dart` | Up to date |
| `intl` | `^0.20.2` | `0.20.3` | **Yes** | `lib/screens/call_log_screen.dart`, `lib/models/call_log_model.dart` | Up to date |
| `path_provider` | `^2.1.6` | `2.1.6` | **Yes** | `lib/services/memory_service.dart`, `lib/providers/download_provider.dart` | Up to date |
| `shared_preferences`| `^2.3.5` | `2.5.5` | **Yes** | `lib/services/memory_service.dart`, `lib/providers/agent_state_provider.dart` | Up to date |
| `url_launcher` | `^6.3.1` | `6.3.2` | **Yes** | `lib/services/action_handler.dart`, `lib/services/app_launcher_helper.dart` | Up to date |
| `workmanager` | `^0.10.9` | `0.10.9` | **Yes** | `lib/main.dart` | Up to date |
| `cupertino_icons` | `^1.0.8` | `1.0.9` | No (Asset Font) | Asset icon font definitions | Up to date |
| `connectivity_plus` | `^6.1.4` | `6.1.5` | Declared / Unused | Network connectivity status helper | `7.3.1` available |
| `dio_smart_retry` | `^6.0.0` | `6.0.0` | Declared / Unused | Optional retry interceptor for Dio | `7.0.1` available |
| `http` | `^1.2.2` | `1.6.0` | Declared / Unused | Redundant with `dio` | Up to date |
| `path` | `^1.9.1` | `1.9.1` | Declared / Unused | String path manipulation helper | Up to date |
| `flutter_animate` | `^4.5.2` | `4.5.2` | Declared / Unused | Declarative animation wrappers | Up to date |
| `lottie` | `^3.3.1` | `3.5.1` | Declared / Unused | Vector Lottie animation renderer | Up to date |

### 2.3 Dev Dependencies
| Package | Declared Version | Resolved Version | Status |
| :--- | :--- | :--- | :--- |
| `flutter_test` | `sdk: flutter` | `0.0.0` | Used in all test files |
| `flutter_lints` | `^6.0.0` | `6.0.0` | Included in `analysis_options.yaml` |

---

## 3. Android Build Configuration Survey

### 3.1 Build & Toolchain Specifications
- **Gradle Version**: `9.1.0` (`android/gradle/wrapper/gradle-wrapper.properties`)
- **Android Gradle Plugin (AGP)**: `9.0.1` (`android/settings.gradle.kts`)
- **Kotlin Android Plugin**: `2.3.20` (`android/settings.gradle.kts`)
- **Java Toolchain**:
  - `sourceCompatibility = JavaVersion.VERSION_17`
  - `targetCompatibility = JavaVersion.VERSION_17`
  - `jvmTarget = JvmTarget.JVM_17`
- **SDK Target & Versioning**:
  - `compileSdk = 37`
  - `minSdk = flutter.minSdkVersion` (Android 5.0+, API 21)
  - `targetSdk = flutter.targetSdkVersion` (Android 14+, API 34)
  - `namespace = "com.syncra.syncra"`
  - `applicationId = "com.syncra.syncra"`

### 3.2 Kotlin / AGP 9.0 Compatibility Flags (`android/gradle.properties`)
- `android.useAndroidX=true`
- `android.newDsl=false`
- `android.builtInKotlin=false`
- `org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError`

**Context & Significance**:
AGP 9.0 introduced Built-in Kotlin (`android.builtInKotlin=true`). Several community Flutter plugins (`flutter_tts`, `installed_apps`, `speech_to_text`, `workmanager_android`) still apply the standard Kotlin Gradle Plugin (`KGP`). Setting `android.builtInKotlin=false` and `android.newDsl=false` ensures complete backwards compatibility and avoids build crashes across all native plugins.

### 3.3 Android Manifest & System Services
- **Services Declared**:
  1. `JackAccessibilityService`: Accessibility Service with `BIND_ACCESSIBILITY_SERVICE` for DOM automation (clicks, text input, gestures, app launching).
  2. `JackOverlayService`: System floating bubble overlay with `android:foregroundServiceType="specialUse|microphone"`.
  3. `JackNotificationListener`: Notification listener with `BIND_NOTIFICATION_LISTENER_SERVICE`.
  4. `JackCallReceiver`: Broadcast receiver for `PHONE_STATE` and `NEW_OUTGOING_CALL`.
  5. `BootReceiver`: Broadcast receiver for `BOOT_COMPLETED`.
- **Permissions**:
  - Full suite configured: `RECORD_AUDIO`, `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`, `QUERY_ALL_PACKAGES`, `CALL_PHONE`, `READ_CONTACTS`, `SEND_SMS`, `READ_SMS`, `READ_PHONE_STATE`, `READ_CALENDAR`.
  - Android 14+ Note: Manifest declares `foregroundServiceType="specialUse|microphone"`. To ensure full compliance with Android 14+ Foreground Service policies, ensure `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />` is present alongside `FOREGROUND_SERVICE_SPECIAL_USE`.

---

## 4. Diagnostic Execution Summary

| Command | Status | Duration / Detail | Notes / Blocker Assessment |
| :--- | :--- | :--- | :--- |
| `flutter --version` | **SUCCESS (0)** | 4.1s | Flutter 3.44.4 • Dart 3.12.2 |
| `flutter pub get` | **SUCCESS (0)** | 2.1s | All 22 dependencies resolved cleanly |
| `flutter analyze` | **SUCCESS (0)** | 137.4s | **0 issues found** across all Dart files |
| `flutter test` | **SUCCESS (0)** | 2.5s | **9/9 tests passed** (`m1_ui_test.dart`, `m2_api_reliability_test.dart`) |
| `cd android && gradlew.bat tasks --dry-run` | **SUCCESS (0)** | 107.0s | Build configuration evaluated cleanly, task graph built |

---

## 5. Catalog of Potential Blockers & Optimization Opportunities

1. **Foreground Service Microphone Permission**:
   - `JackOverlayService` uses `foregroundServiceType="specialUse|microphone"`. Adding `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />` in `AndroidManifest.xml` prevents Android 14+ runtime security exceptions when recording audio in background/overlay mode.
2. **Built-In Kotlin Migration Awareness**:
   - `gradlew` logs deprecation warnings for `org.jetbrains.kotlin.android` on AGP 9.0. Currently, `android.builtInKotlin=false` in `gradle.properties` handles this cleanly. No changes needed immediately, but maintain these properties to prevent plugin build failures.
3. **Dependency Pruning / Hygiene**:
   - `http` and `dio_smart_retry` are declared in `pubspec.yaml` but `dio` is used directly for all HTTP/Groq networking. Retaining or removing them is safe, but keeping them does not cause any compile issues.
4. **Shaders**:
   - `shaders/glow.frag` is declared in `pubspec.yaml` and compiled by Flutter shader compiler without issues.

---

## 6. Conclusion

The Jack Mobile Agent project foundation is in an exceptionally stable and clean state:
- Zero Dart compilation or analyzer errors (`flutter analyze` -> 0 issues).
- Zero dependency resolution conflicts (`flutter pub get` -> clean).
- Android Gradle toolchain (AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, Java 17, SDK 37) evaluates and builds task graphs cleanly.
- Unit and widget test suite passes 100%.
