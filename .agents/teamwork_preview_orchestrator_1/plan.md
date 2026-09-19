# Execution Plan - Jack Mobile Agent Review & Bug Fixing

## Objective
A comprehensive, multi-agent code review, alignment check, and bug-fixing pass on the `jack-mobile-agent` Flutter codebase to guarantee zero issues and perfect Android OS execution across R1 (UI & Orb physics), R2 (API & Token validation / live Groq models & failsafes), and R3 (OS Execution Engine, installed_apps mapping, JackOverlayService microphone foreground service).

## Phases
1. **Phase 0: Survey & Mapping**
   - Spawn 3 Explorers:
     - Explorer 1 (UI & Orb Physics): Focus on `dashboard_screen.dart`, `onboarding_screen.dart`, mesh orb animations, gradients, layout overflow prevention, responsive design.
     - Explorer 2 (API & Models & Failsafes): Focus on `agent_state_provider.dart`, `jack_tools.dart`, Groq API client, model versions (`llama-3.3-70b-versatile`, `llama-3.1-8b-instant`), error handling, failsafes for silent fails / "Done" loops.
     - Explorer 3 (OS Execution Engine & Android Services): Focus on Android DOM execution logic, `installed_apps` plugin mapping spoken app names to package names, AndroidManifest.xml, `JackOverlayService` foreground service configuration (`specialUse|microphone`).
2. **Phase 1: Synthesis & PROJECT.md**
   - Aggregate explorer findings into `PROJECT.md` with Feature Inventory, Architecture, Code Layout, and Milestones.
3. **Phase 2: Milestone Implementation & Verification**
   - Dispatch workers for each milestone.
   - Run unit/integration tests and `flutter analyze` / compilation verification.
4. **Phase 3: Review, Challenger & Forensic Audit**
   - Reviewers, Challengers, and Forensic Auditor for integrity verification.
5. **Phase 4: Synthesis & Final Handoff**
