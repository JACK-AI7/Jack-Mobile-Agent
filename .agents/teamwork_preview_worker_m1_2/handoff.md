# Milestone 1 Implementation Handoff: UI Alignment, Layout & Orb Physics

**Date**: 2026-08-24  
**Author**: Worker Subagent (`teamwork_preview_worker_m1_2`)  
**Scope**: `lib/screens/onboarding_screen.dart`, `lib/screens/dashboard_screen.dart`, `lib/router/app_router.dart`, `lib/widgets/wave_painters.dart`, `lib/widgets/neon_mic_button.dart`, `lib/widgets/shared_widgets.dart`, `lib/widgets/uiverse_orb.dart`, `shaders/glow.frag`, and `test/m1_ui_test.dart`.

---

## 1. Observation

Direct observations before and after modifications:

1. **`lib/screens/onboarding_screen.dart`**:
   - *Before*: Contained an unconstrained static `Column` requiring $\ge 734\text{px}$ vertical height, causing `RenderFlex overflowed by XX pixels on bottom` on smaller mobile viewports ($320\times 480$ / $360\times 640$) or scaled accessibility fonts. Contained deprecated `.withOpacity(...)` calls.
   - *After*: Wrapped `Column` in `LayoutBuilder` + `SingleChildScrollView(physics: BouncingScrollPhysics())` + `ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight))` + `IntrinsicHeight`. Deprecations replaced with `.withValues(alpha: ...)`. Zero layout overflows.

2. **`lib/router/app_router.dart`**:
   - *Before*: Missing declaration for `AppRoutes.callLog` and route for `/call-log`, causing GoRouter runtime crash when users tapped "Call History" in `_ProfileBottomSheet`.
   - *After*: Declared `static const String callLog = '/call-log'` in `AppRoutes` and registered `GoRoute(path: AppRoutes.callLog, builder: (context, state) => const CallLogScreen())` with `import '../screens/call_log_screen.dart';`.

3. **`lib/screens/dashboard_screen.dart`**:
   - *Before*:
     - `_Image2Orb` had static idle scale ($1.0$), lacked idle breathing physics, hardcoded static pastel colors regardless of agent status, and wrapped gradients in `Transform.rotate` causing extra UI render layers every frame.
     - `_DynamicWidgetRenderer` was positioned at `bottom: 110` colliding directly with the centered transcript / orb on standard screens.
   - *After*:
     - `_Image2Orb` now implements state-reactive glowing palettes:
       * `AgentStatus.listening`: Electric Blue (`0xFF3B82F6`)
       * `AgentStatus.thinking`: Neon Purple (`0xFF9D4EDD`)
       * `AgentStatus.executingOS`: Neon Orange / Red (`0xFFFF2A5F`)
       * `AgentStatus.complete`: Terminal Green (`0xFF00FF88`)
       * `AgentStatus.idle`: Soft Pink & Purple Glow (`0xFFF9A8D4`, `0xFFD8B4FE`)
     - Implemented dynamic idle breathing physics: `1.0 + math.sin(_ctrl.value * 2 * math.pi) * 0.03` when idle, and energized pulse `1.05 + math.sin(_ctrl.value * math.pi * 4) * 0.05` when active.
     - Optimized GPU gradient rotation with `SweepGradient(transform: GradientRotation(rotation), ...)`.
     - Guarded `_DynamicWidgetRenderer` within `Positioned.fill(top: 56, bottom: 84)` and flexible spacing so dynamic cards sit gracefully below transcript without overlapping the orb or bottom mic bar.
     - Replaced all `.withOpacity(...)` with `.withValues(alpha: ...)`.

4. **`lib/widgets/wave_painters.dart`**:
   - *Before*: `GeminiAppleGlow` ran a frame `Ticker` invoking `setState()` at 60/120fps, causing constant widget subtree invalidations.
   - *After*: Replaced `Ticker` and `setState` with `AnimationController` passed to `CustomPainter(repaint: animation)`. `ShaderGlowPainter` repaints directly on GPU without rebuilding the widget tree.

5. **`shaders/glow.frag`**:
   - *Before*: Line 25 had non-premultiplied RGB calculation: `fragColor = vec4(finalColor * (1.0 - border), (1.0 - border) * 0.8);` causing white/discolored halo artifacts along translucent border edges.
   - *After*: Corrected to `float alpha = (1.0 - border) * 0.8; fragColor = vec4(finalColor * alpha, alpha);`.

6. **Deprecations & Deduplications**:
   - `lib/widgets/neon_mic_button.dart`: Renamed typo parameter `pulseSacle` $\to$ `pulseScale`.
   - `lib/widgets/shared_widgets.dart`: Removed duplicate `NeonMicButton` declaration and added `export 'neon_mic_button.dart';`.
   - `lib/widgets/uiverse_orb.dart`: Replaced `.withOpacity(...)` with `.withValues(alpha: ...)` and updated `Matrix4.scale` to `Matrix4.scaleByDouble(boost, boost, boost, 1.0)`.

---

## 2. Logic Chain

1. **Responsive Scroll**:
   - Encapsulating the unconstrained `Column` within `SingleChildScrollView` and `IntrinsicHeight` ensures Flutter allows vertical scrolling whenever available viewport height is smaller than intrinsic element height, while expanding to full height on taller displays.
2. **GoRouter Reliability**:
   - Registering `AppRoutes.callLog` satisfies `context.push('/call-log')` calls in `dashboard_screen.dart`, preventing runtime routing exceptions.
3. **GPU Orb Rendering & Smooth Physics**:
   - Using `GradientRotation` applies matrix transformations in the fragment shader rather than creating intermediate rasterization layers.
   - Continuous sine oscillation `sin(2 * pi * t)` delivers organic idle breathing, and status-driven color palettes provide instant visual feedback to user voice/execution states.
4. **CustomPainter Repaint Separation**:
   - Using `Listenable` animation repainting in `CustomPainter(repaint: animation)` bypasses Flutter element tree reconciliation on every frame, eliminating frame drops.
5. **Premultiplied Alpha Correctness**:
   - Multiplying RGB by alpha matching the alpha channel in `shaders/glow.frag` ensures Skia/Impeller blend functions output correct translucent color values without bright halo fringes.

---

## 3. Caveats

- Milestone 1 specifically owns UI, routing, and shaders. Background services and LLM provider logic (`agent_state_provider.dart`, `websocket_service.dart`, `MainActivity.kt`) are scoped to subsequent milestones (M2 & M3).
- No other caveats.

---

## 4. Conclusion

Milestone 1 is complete, fully implemented, verified, and adheres to the architecture standards. All 8 owned files compile with zero issues, zero warnings, zero deprecations, and all 4 widget tests pass.

---

## 5. Verification Method

Independent verification commands:

1. **Analyzer Verification**:
   ```powershell
   flutter analyze lib/screens/onboarding_screen.dart lib/screens/dashboard_screen.dart lib/router/app_router.dart lib/widgets/wave_painters.dart lib/widgets/neon_mic_button.dart lib/widgets/shared_widgets.dart lib/widgets/uiverse_orb.dart test/m1_ui_test.dart
   ```
   *Expected Output*: `No issues found!` (Exit code 0).

2. **Automated Unit & Widget Tests**:
   ```powershell
   flutter test test/m1_ui_test.dart
   ```
   *Expected Output*: `All tests passed! 00:02 +4: All tests passed!` (Exit code 0).
