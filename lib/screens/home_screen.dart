import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/realtime/jack_orb_state.dart';
import '../services/realtime/agent_execution_controller.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello Easin!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'What do you want\nJack to do?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              Expanded(
                child: Center(
                  child: JackOrb(
                    size: 200,
                    state: orbState,
                    onTap: () {
                      // Handled by native voice input natively, no fake UI timer
                    },
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white12,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _submitSearch,
                  decoration: const InputDecoration(
                    hintText: 'Ask Jack anything...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
