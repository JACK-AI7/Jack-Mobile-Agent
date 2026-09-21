import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/agents_provider.dart';
import '../services/api/jack_api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedTabIndex = 0; // 0 for Agents, 1 for Workflows

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildPillSwitch(),
            Expanded(
              child: _selectedTabIndex == 0
                  ? RefreshIndicator(
                      color: AppColors.accentCyan,
                      backgroundColor: AppColors.surfaceElevated,
                      onRefresh: () async => ref.invalidate(agentsProvider),
                      child: agentsAsync.when(
                        data: (agents) {
                          if (agents.isEmpty) {
                            return _buildEmptyState('No agents yet. Create your first agent.');
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            itemCount: agents.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final a = agents[index];
                              return GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentCyan.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                                      ),
                                      child: const Icon(Icons.smart_toy_rounded, color: AppColors.accentCyan),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.name,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            a.description.isNotEmpty ? a.description : 'Custom agent',
                                            style: GoogleFonts.inter(
                                              color: Colors.white54,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              OutlinedButton(
                                                onPressed: () {
                                                  context.push('/chat', extra: 'Run agent: ${a.name}');
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.accentCyan,
                                                  side: BorderSide(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: const Text('Run', style: TextStyle(fontSize: 12)),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.7), size: 20),
                                                onPressed: () async {
                                                  try {
                                                    await ref.read(apiClientProvider).deleteAgent(a.id);
                                                    ref.invalidate(agentsProvider);
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
                                                    }
                                                  }
                                                },
                                                constraints: const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
                        error: (e, st) => Center(child: Text('Error loading agents', style: GoogleFonts.inter(color: AppColors.error))),
                      ),
                    )
                  : _buildEmptyState('No workflows yet.'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAgentDialog(context, ref),
        backgroundColor: AppColors.accentCyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text('New Agent', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Text(
            message,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Library',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your agents & workflows',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildTabItem(title: 'Agents', index: 0),
          _buildTabItem(title: 'Workflows', index: 1),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.accentCyan : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateAgentDialog(BuildContext context, WidgetRef ref) {
    final promptCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Agent', style: GoogleFonts.cormorantGaramond(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: promptCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe what this agent should do...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (promptCtrl.text.isNotEmpty) {
                      try {
                        await ref.read(apiClientProvider).createAgent(promptCtrl.text);
                        ref.invalidate(agentsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to create')));
                      }
                    }
                  },
                  child: Text('Create Agent', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
