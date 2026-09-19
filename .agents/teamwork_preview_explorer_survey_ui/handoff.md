# Survey Report: Requirement 1 (UI Alignment & Orb Physics)

**Date**: 2026-08-24  
**Author**: Explorer Subagent (`teamwork_preview_explorer_survey_ui`)  
**Scope**: `lib/screens/dashboard_screen.dart`, `lib/screens/onboarding_screen.dart`, `lib/widgets/uiverse_orb.dart`, `lib/widgets/wave_painters.dart`, `lib/widgets/neon_mic_button.dart`, `lib/widgets/gradient_border.dart`, `lib/widgets/shared_widgets.dart`, `lib/router/app_router.dart`, and `shaders/glow.frag`.

---

## 1. Observation

Direct code observations, exact file locations, and verbatim snippets:

### A. Layout Overflow and Responsiveness
1. **`lib/screens/onboarding_screen.dart` (Lines 13–143)**:
   ```dart
   Scaffold(
     backgroundColor: Colors.black,
     body: SafeArea(
       child: Column(
         children: [
           const SizedBox(height: 60),
           const _SmallGlowOrb(), // 160px + 40px blur
           const SizedBox(height: 24),
           Container(...), // Pill: 36px
           const SizedBox(height: 48),
           Padding(..., child: Text('EFFORTLESS\nCONTROL\nWITH JACK', ...)), // ~132px
           const SizedBox(height: 24),
           Padding(..., child: Text('At Jack, we believe...', ...)), // ~42px
           const SizedBox(height: 32),
           Row(...), // Dots: 6px
           const Spacer(),
           Padding(..., child: GestureDetector(child: Container(...))), // Button: 56px
           const SizedBox(height: 16),
           Padding(..., child: GestureDetector(child: Container(...))), // Button: 56px
           const SizedBox(height: 48),
         ],
       ),
     ),
   );
   ```
   - **Static Height Requirement**: The fixed vertical elements sum to $60 + 160 + 24 + 36 + 48 + 132 + 24 + 42 + 32 + 56 + 16 + 56 + 48 = \mathbf{734\text{ px}}$.
   - **Absence of Scroll / Flexible Constraints**: There is no `SingleChildScrollView` or `LayoutBuilder`. On devices with available screen height $< 734\text{ px}$ (or with Android accessibility font scaling enabled), Flutter will trigger an unhandled `RenderFlex overflowed by XX pixels on the bottom`.

2. **`lib/screens/dashboard_screen.dart` (Lines 34–94)**:
   ```dart
   SafeArea(
     child: Stack(
       children: [
         Positioned(top: 12, left: 20, right: 20, child: Row(...)),
         Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               GestureDetector(child: const _Image2Orb(size: 240)),
               const SizedBox(height: 48),
               Text('Jack', ...),
               const SizedBox(height: 8),
               Padding(..., child: Text(agent.transcript.isNotEmpty ? agent.transcript : ...)),
             ],
           ),
         ),
         if (agent.activeWidget != null)
           Positioned(
             bottom: 110, left: 20, right: 20,
             child: _DynamicWidgetRenderer(widgetType: agent.activeWidget!),
           ),
         Positioned(left: 16, right: 16, bottom: 20, child: _BottomMicBar()),
       ],
     ),
   )
   ```
   - **Z-Index and Vertical Clashing**: The Center Column height is $240\text{px} + 48\text{px} + 44\text{px} + 8\text{px} + 40\text{px} = 380\text{px}$. On a 700px viewport, the column extends down to $y = 540\text{px}$.
   - When `agent.activeWidget != null`, `Positioned(bottom: 110)` spans $y = 500\text{px} \dots 590\text{px}$, directly obscuring the transcript and subtitle text.

---

### B. Routing & Navigation Runtime Crash
1. **`lib/screens/dashboard_screen.dart` (Line 269)**:
   ```dart
   _SheetTile(
     icon: Icons.history_rounded,
     label: 'Call History',
     onTap: () { Navigator.pop(context); context.push('/call-log'); },
   )
   ```
2. **`lib/router/app_router.dart` (Lines 19–51)**:
   ```dart
   final goRouter = GoRouter(
     initialLocation: AppRoutes.dashboard,
     routes: [
       GoRoute(path: AppRoutes.root, builder: (context, state) => const OnboardingScreen()),
       GoRoute(path: AppRoutes.dashboard, pageBuilder: ...),
       GoRoute(path: AppRoutes.taskResult, pageBuilder: ...),
     ],
   );
   ```
   - `/call-log` is **missing** from `app_router.dart`. Tapping "Call History" in the profile modal throws `GoException: no routes for location: /call-log`.

---

### C. Glowing Orb Physics, Shaders, and Custom Painters
1. **`lib/screens/dashboard_screen.dart` (`_Image2Orb`, Lines 120–231)**:
   - **Physics & Animation**:
     ```dart
     final rotation = _ctrl.value * 2 * math.pi;
     final scale = isActive ? 1.05 + math.sin(_ctrl.value * math.pi * 4) * 0.05 : 1.0;
     ```
     - When `isActive == false` (`idle`), `scale = 1.0` is completely static without idle breathing.
     - When `isActive` switches from `false` to `true`, the scale abruptly jumps from 1.0 to 1.05+ without curve smoothing or spring physics.
     - Hardcoded static colors (`SweepGradient` with `0xFFFF9A9E`, `0xFFFECFEF`, `0xFFA18CD1`, `0xFFFBC2EB`) never reflect agent status (`listening`, `thinking`, `executingOS`, `error`, `complete`).
   - **Layer Performance**:
     - Line 174 uses `Transform.rotate(angle: rotation, child: Container(decoration: BoxDecoration(gradient: SweepGradient(...))))`. This creates a transform layer on every animation tick. Using `SweepGradient(transform: GradientRotation(rotation))` rotates the shader matrix directly on GPU without layer allocations.

2. **`lib/widgets/wave_painters.dart` (`GeminiAppleGlow`, Lines 153–167 & `ShaderGlowPainter`)**:
   - **Ticker `setState` 60/120fps Rebuilds**:
     ```dart
     _ticker = createTicker((elapsed) {
       setState(() {
         _elapsedTime = elapsed.inMilliseconds / 1000.0;
       });
     })..start();
     ```
     Calling `setState()` on every frame invalidates and rebuilds the entire widget subtree instead of delegating repainting to `CustomPainter`.
   - **Premultiplied Alpha Artifacts in `shaders/glow.frag` (Line 25)**:
     ```glsl
     fragColor = vec4(finalColor * (1.0 - border), (1.0 - border) * 0.8);
     ```
     The RGB output is multiplied by `(1.0 - border)` while alpha is `(1.0 - border) * 0.8`. In Skia/Impeller, non-premultiplied RGB produces a bright/discolored fringe along translucent edges.

3. **`lib/widgets/uiverse_orb.dart` (`_GooeyBall`, Lines 301–333 & `_SpinRing`, Line 237)**:
   - **Clipping / Jagged Vertex Artifacts**:
     `final double inner = size * (100.0 / 64.0);` creates a container 1.56x larger than the circular ball. Because Flutter does not implement CSS SVG gooey filter matrices (`feColorMatrix`), the vertices of `_PolyClipper` poke out of the circle as sharp non-liquid polygons.
   - **Deprecated Matrix4 API**:
     Line 237: `..scale(boost)` is deprecated in modern Flutter / vector_math (`Use scaleByVector3, scaleByVector4, or scaleByDouble instead`).

---

### D. Duplicate Widgets and Code Inconsistencies
1. **Duplicate `NeonMicButton`**:
   - `lib/widgets/neon_mic_button.dart` (Line 9) defines `NeonMicButton` with typo `pulseSacle` (Line 23).
   - `lib/widgets/shared_widgets.dart` (Line 10) defines another `NeonMicButton` without pulse animation or `onTap`.
2. **Deprecated `.withOpacity()` Calls**:
   - 13 instances across `dashboard_screen.dart`, `onboarding_screen.dart`, `uiverse_orb.dart`, and `call_log_screen.dart` produce compile-time linter warnings (`Use .withValues(alpha: ...) to avoid precision loss`).

---

## 2. Logic Chain

1. **Premise**: Mobile applications must support varying screen heights (from 600px to 900px+), landscape/split-screen orientations, and accessibility text scaling without crashing.
   - **Deduction from Obs A.1**: `OnboardingScreen` uses an unconstrained `Column` with a static height requirement of 734px. When rendered on smaller displays or scaled fonts, Flutter cannot shrink the elements and raises a `RenderFlex` overflow exception.
   - **Proposed Fix**: Encapsulate the `Column` inside a `SingleChildScrollView` wrapped in a `ConstrainedBox` with `minHeight: constraints.maxHeight` and `IntrinsicHeight` via `LayoutBuilder`.

2. **Premise**: Screen navigation through GoRouter requires every route invoked by `context.push` or `context.go` to be declared in the routing table.
   - **Deduction from Obs B.1 & B.2**: `_ProfileBottomSheet` pushes `/call-log`, but `app_router.dart` only defines `/`, `/dashboard`, and `/task-result`. This causes a runtime crash when opening Call History.
   - **Proposed Fix**: Declare `AppRoutes.callLog = '/call-log'` and register `GoRoute(path: AppRoutes.callLog, builder: (_, __) => const CallLogScreen())` in `app_router.dart`.

3. **Premise**: UI animations should be 60/120fps butter-smooth, reactive to state, and computationally lightweight without unnecessary widget rebuilds or rasterizer halo artifacts.
   - **Deduction from Obs C.1 & C.2**:
     - `_Image2Orb` lacks idle breathing and state reactivity. Adding an idle pulse curve and interpolating glow colors according to `AgentStatus` (listening = blue/cyan, thinking = purple, executing = orange/magenta) makes the orb dynamic.
     - `GeminiAppleGlow` uses `setState()` inside a `Ticker`. Replacing `setState` with passing an `AnimationController` to `CustomPainter(repaint: controller)` eliminates unnecessary widget tree rebuilds.
     - `shaders/glow.frag` premultiplied alpha fix `vec4(finalColor * alpha, alpha)` prevents edge color artifacts.

4. **Premise**: Duplicate widget declarations cause maintenance confusion and linter warnings.
   - **Deduction from Obs D.1 & D.2**: Unify `NeonMicButton`, fix typo `pulseSacle` $\to$ `pulseScale`, and replace deprecated `.withOpacity(x)` with `.withValues(alpha: x)`.

---

## 3. Caveats

- **No Caveats on Read-Only Analysis**: Code exploration was exhaustive across all UI files in `lib/screens/`, `lib/widgets/`, `lib/theme/`, `lib/router/`, and `shaders/`.
- Note: `websocket_service.dart` has an unrelated compile error (`package:record` import) which is within the scope of Requirement 2 / 3 explorers and implementers.

---

## 4. Conclusion & Recommended Concrete Fixes

### A. Recommended Concrete Code Changes

#### 1. `lib/screens/onboarding_screen.dart` — Safe Scrollable Responsive Layout
```dart
// Wrap the body in a LayoutBuilder + SingleChildScrollView to guarantee ZERO bottom overflow:
body: SafeArea(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const _SmallGlowOrb(),
                const SizedBox(height: 20),
                // Pill ...
                const SizedBox(height: 32),
                // Title Text ...
                const SizedBox(height: 16),
                // Subtitle Text ...
                const SizedBox(height: 24),
                // Pager Dots ...
                const Spacer(),
                const SizedBox(height: 16),
                // Sign Up & Sign In buttons ...
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  ),
)
```

#### 2. `lib/router/app_router.dart` — Register Missing Route
```dart
class AppRoutes {
  AppRoutes._();
  static const String root       = '/';
  static const String dashboard  = '/dashboard';
  static const String taskResult = '/task-result';
  static const String callLog    = '/call-log';
}

// In goRouter:
GoRoute(
  path: AppRoutes.callLog,
  builder: (context, state) => const CallLogScreen(),
),
```

#### 3. `lib/screens/dashboard_screen.dart` — Dynamic Orb Physics & Layout Guard
- Implement idle breathing pulse: `sin(t * 2 * pi) * 0.03 + 1.0` in idle mode.
- Interpolate glow color dynamically based on `agent.status`:
  - `listening`: `Color(0xFF3B82F6)` (Electric Blue)
  - `thinking`: `Color(0xFF9D4EDD)` (Neon Purple)
  - `executingOS`: `Color(0xFFFF2A5F)` (Neon Red / Orange)
  - `complete`: `Color(0xFF00FF88)` (Terminal Green)
- In `_BottomMicBar` and dynamic cards, ensure `_DynamicWidgetRenderer` integrates cleanly into a scrollable/flex column rather than colliding with the center orb.

#### 4. `lib/widgets/wave_painters.dart` & `shaders/glow.frag` — Performance & Alpha Fix
- Replace `setState` ticker with `AnimationController` passed to `CustomPaint(painter: ShaderGlowPainter(..., repaint: controller))`.
- Update `shaders/glow.frag` Line 25:
  ```glsl
  float alpha = (1.0 - border) * 0.8;
  fragColor = vec4(finalColor * alpha, alpha);
  ```

#### 5. Deprecations & Cleanups
- Replace all `.withOpacity(val)` with `.withValues(alpha: val)`.
- Consolidate duplicate `NeonMicButton` into `lib/widgets/neon_mic_button.dart` and fix parameter typo `pulseSacle` $\to$ `pulseScale`.

---

## 5. Verification Method

To independently verify these findings:

1. **Verify Static Layout Heights & Overflow**:
   - Inspect `lib/screens/onboarding_screen.dart` lines 13–143. Calculate sum of vertical heights ($734\text{px}$). Run an emulator or Flutter test with logical size `360x640` to trigger bottom overflow.
2. **Verify Missing Route**:
   - Inspect `lib/screens/dashboard_screen.dart` line 269 (`context.push('/call-log')`) vs `lib/router/app_router.dart`. Notice absence of `/call-log`.
3. **Verify Deprecations & Build**:
   - Run `flutter analyze` to observe the 71 linter issues, including deprecated `.withOpacity` and `Matrix4.scale`.
