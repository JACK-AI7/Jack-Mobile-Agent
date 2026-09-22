// lib/screens/library_screen.dart
//
// 08. Library — Real agents from backend. Zero fake data.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/jack_components.dart';
import '../providers/agents_provider.dart';
import '../services/api/jack_api_client.dart';
import '../theme/app_colors.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Agents', 'Prompts', 'Workflows'];

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('research') || n.contains('search')) return Icons.explore_rounded;
    if (n.contains('content') || n.contains('write') || n.contains('edit')) return Icons.edit_note_rounded;
    if (n.contains('data') || n.contains('analys')) return Icons.bar_chart_rounded;
    if (n.contains('social') || n.contains('post') || n.contains('tweet')) return Icons.share_rounded;
    if (n.contains('custom') || n.contains('own')) return Icons.smart_toy_rounded;
    if (n.contains('email') || n.contains('mail')) return Icons.mail_rounded;
    if (n.contains('code') || n.contains('dev')) return Icons.code_rounded;
    if (n.contains('shop') || n.contains('buy') || n.contains('price')) return Icons.shopping_bag_outlined;
    return Icons.auto_awesome_rounded;
  }

  Color _colorFor(String id) {
    const colors = [
      Color(0xFF2B6BFF),
      Color(0xFF00E5FF),
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFFA855F7),
      Color(0xFF00FF88),
      Color(0xFF14B8A6),
      Color(0xFFFF3377),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final asyncAgents = ref.watch(agentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'JACK AGENT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: Colors.white70,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            onPressed: () => _showCreateAgentDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your saved agents, prompts and workflows.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Segmented Filters: [Agents] [Prompts] [Workflows]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final active = _selectedFilter == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = i);
                      },
                      child: Container(
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.accentCyan
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: Text(
                            _filters[i],
                            style: GoogleFonts.inter(
                              color: active ? Colors.black : Colors.white70,
                              fontSize: 12.5,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // ── Real Data from backend
            Expanded(
              child: asyncAgents.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading agents...',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                error: (err, _) => _buildErrorState(
                  err.toString().replaceAll('Exception: ', ''),
                ),
                data: (agents) {
                  // Prompts and Workflows tabs show empty state — only Agents is real
                  if (_selectedFilter != 0) {
                    return _buildEmptyFilterState(
                        _filters[_selectedFilter], context);
                  }
                  if (agents.isEmpty) {
                    return _buildEmptyAgentsState(context);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: agents.length,
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: JackAgentCard(
                          title: agent.name,
                          subtitle: agent.description.isNotEmpty
                              ? agent.description
                              : agent.goal,
                          icon: _iconFor(agent.name),
                          iconColor: _colorFor(agent.id),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/chat',
                                extra: 'Run agent: ${agent.name}. ${agent.goal}');
                          },
                          onLongPress: () => _showDeleteDialog(context, agent.id, agent.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load library',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.contains('Authentication')
                  ? 'Please log in again to access your library.'
                  : 'Backend is unreachable. Check your connection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => ref.invalidate(agentsProvider),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.accentCyan.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Retry',
                  style: GoogleFonts.inter(color: AppColors.accentCyan)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAgentsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy_outlined, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'No agents yet',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first AI agent in Agent Builder\nand it will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/agent-builder'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Build an Agent',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(String label, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_outlined, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'No $label saved',
              style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '$label will appear here once you create them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131124),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete $name?',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
        content: Text('This agent will be permanently removed.',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiClientProvider).deleteAgent(id);
                ref.invalidate(agentsProvider);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete agent'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateAgentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build an Agent',
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Go to Agent Builder to create and configure a new AI agent.',
              style:
                  GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/agent-builder');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Open Agent Builder',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
