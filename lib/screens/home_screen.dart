import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/realtime/jack_orb_state.dart';
import '../services/realtime/agent_execution_controller.dart';
import '../services/jack_auth_state.dart';
import '../widgets/jack_orb.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    context.push('/chat', extra: query);
    _searchController.clear();
  }

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

  @override
  Widget build(BuildContext context) {
    final realtimeState = ref.watch(agentExecutionProvider);
    final orbState = _mapJackOrbState(realtimeState.orbState);
    final userName = ref.watch(userNameProvider);
    final nameStr = userName.when(
      data: (name) => name ?? 'User',
      loading: () => '...',
      error: (_, __) => 'User',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Text(
                'JACK AGENT',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hello, ',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What do you want\nJack to do?',
                  style: GoogleFonts.newsreader(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: JackOrb(
                  size: 240,
                  state: orbState,
                  onTap: () {
                    // Handled natively by accessibility service trigger
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.auto_awesome, color: Colors.white54, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _submitSearch,
                        decoration: const InputDecoration(
                          hintText: 'Ask Jack anything...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: () => _submitSearch(_searchController.text),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildQuickAction(Icons.search, 'Search'),
                  _buildQuickAction(Icons.create, 'Create'),
                  _buildQuickAction(Icons.analytics, 'Analyze'),
                  _buildQuickAction(Icons.bolt, 'Automate'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

