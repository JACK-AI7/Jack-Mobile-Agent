// lib/screens/home_screen.dart
//
// JACK Agent Home Screen — pixel-perfect implementation.
// Navigation bar is rendered by the parent ShellRoute (GlassNavBar),
// so this screen owns only its own content column.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/realtime/jack_orb_state.dart';
import '../services/realtime/agent_execution_controller.dart';
import '../services/jack_auth_state.dart';
import '../theme/app_colors.dart';
import '../widgets/jack_orb.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ── Orb state mapping ──────────────────────────────────────────────────────
  static OrbState _mapJackOrbState(JackOrbState s) {
    switch (s) {
      case JackOrbState.THINKING:
      case JackOrbState.PLANNING:
        return OrbState.thinking;
      case JackOrbState.EXECUTING:
      case JackOrbState.SEARCHING:
      case JackOrbState.USING_TOOL:
      case JackOrbState.WAITING_FOR_APPROVAL:
        return OrbState.working;
      case JackOrbState.LISTENING:
        return OrbState.listening;
      case JackOrbState.SUCCESS:
        return OrbState.success;
      case JackOrbState.ERROR:
        return OrbState.error;
      default:
        return OrbState.idle;
    }
  }

  // ── Input submission ───────────────────────────────────────────────────────
  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchFocus.unfocus();
    _searchController.clear();
    context.push('/chat', extra: trimmed);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final realtimeState = ref.watch(agentExecutionProvider);
    final orbState = _mapJackOrbState(realtimeState.orbState);

    final userNameAsync = ref.watch(userNameProvider);
    final nameStr = userNameAsync.when(
      data: (name) => name?.isNotEmpty == true ? name! : 'User',
      loading: () => '...',
      error: (_, __) => 'User',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Radial background gradient (subtle violet/purple tint) ─────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.6),
                  radius: 1.1,
                  colors: [
                    Color(0xFF12082A), // deep violet tint at top-center
                    Color(0xFF07070A), // near-black mid
                    Color(0xFF05050F), // slightly deeper at edges
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // ── Greeting ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    '< Hello, $nameStr >',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Hero headline ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'What do you want\nJack to do?',
                    style: GoogleFonts.cormorantGaramond(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w400,
                      height: 1.10,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // ── JACK Orb (expands to fill remaining space above input) ──
                Expanded(
                  child: Center(
                    child: JackOrb(
                      size: 280,
                      state: orbState,
                      onTap: () {
                        // Ambient interaction — voice flow wired when available.
                      },
                    ),
                  ),
                ),

                // ── Glass chat input bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.13),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 22),

                            // ── Text field ─────────────────────────────────
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: _submitSearch,
                                decoration: InputDecoration(
                                  hintText: 'Message Jack...',
                                  hintStyle: GoogleFonts.inter(
                                    color: AppColors.textTertiary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                cursorColor: AppColors.accentCyan,
                              ),
                            ),

                            // ── Send / Mic button (animates between states) ─
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _searchController,
                              builder: (context, value, _) {
                                final hasText = value.text.trim().isNotEmpty;
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: hasText
                                      ? _BarIconButton(
                                          key: const ValueKey('send'),
                                          icon: Icons.arrow_upward_rounded,
                                          color: AppColors.accentCyan,
                                          onPressed: () =>
                                              _submitSearch(_searchController.text),
                                        )
                                      : _BarIconButton(
                                          key: const ValueKey('mic'),
                                          icon: Icons.mic_rounded,
                                          color: AppColors.textSecondary,
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Voice input coming soon',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    AppColors.surfaceElevated,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                duration: const Duration(
                                                    seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                );
                              },
                            ),

                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small circular icon button inside the input bar ──────────────────────────
class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _BarIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
