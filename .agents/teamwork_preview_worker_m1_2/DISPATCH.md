## 2026-08-24T16:19:39Z
You are a replacement Worker subagent implementing Milestone 1: UI Alignment, Layout & Orb Physics (Requirement 1).

Your working directory is: c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_worker_m1_2

MANDATORY FIRST STEP:
1. Read the original request at c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\ORIGINAL_REQUEST.md.
2. Read the project scope at c:\Users\bjasw\Downloads\jack-mobile-agent\PROJECT.md.
3. Read the detailed survey report at c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_explorer_survey_ui\handoff.md.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Scope & Exclusively Owned Files:
- `lib/screens/onboarding_screen.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/router/app_router.dart`
- `lib/widgets/wave_painters.dart`
- `lib/widgets/neon_mic_button.dart`
- `lib/widgets/shared_widgets.dart`
- `lib/widgets/uiverse_orb.dart`
- `shaders/glow.frag`

Tasks to Implement:
1. `onboarding_screen.dart`: Replace the static, overflowing column with a responsive, scrollable container (`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox` + `IntrinsicHeight`) ensuring zero `RenderFlex` bottom overflow on small screens / large font scaling.
2. `app_router.dart`: Add `AppRoutes.callLog = '/call-log'` and register `GoRoute(path: AppRoutes.callLog, builder: (context, state) => const CallLogScreen())` with proper import (`import '../screens/call_log_screen.dart';`) so clicking "Call History" in `dashboard_screen.dart` does not crash GoRouter.
3. `dashboard_screen.dart`:
   - Enhance glowing mesh orb (`_Image2Orb`): Add dynamic idle breathing physics (smooth sine curve), state-reactive glow colors and transitions matching `agent.status` (listening: electric blue `0xFF3B82F6`, thinking: neon purple `0xFF9D4EDD`, executingOS: neon orange/red `0xFFFF2A5F`, complete: terminal green `0xFF00FF88`), and GPU gradient rotation.
   - Guard `_DynamicWidgetRenderer` layout to avoid clipping/overlapping center elements.
4. `wave_painters.dart`: Optimize `GeminiAppleGlow` by passing animation repaints to `CustomPainter(repaint: controller)` instead of calling `setState()` at 60/120fps on a Ticker.
5. `shaders/glow.frag`: Fix premultiplied alpha math on line 25 (`float alpha = (1.0 - border) * 0.8; fragColor = vec4(finalColor * alpha, alpha);`) to eliminate edge fringing/halo artifacts.
6. Clean up deprecations: Replace `.withOpacity(...)` with `.withValues(alpha: ...)` across modified UI files, fix parameter typo `pulseSacle` -> `pulseScale` in `neon_mic_button.dart`, and eliminate duplicate `NeonMicButton` in `shared_widgets.dart`.

Verification:
- Run `flutter analyze` or compilation check.
- Document all modified files, diffs, and verification commands in `c:\Users\bjasw\Downloads\jack-mobile-agent\.agents\teamwork_preview_worker_m1_2\handoff.md`.

Update progress.md in your directory as you work. Send parent a message upon completion.
