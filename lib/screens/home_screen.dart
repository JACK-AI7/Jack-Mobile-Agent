import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/realtime/jack_orb_state.dart';
import '../services/realtime/agent_execution_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';
import '../widgets/jack_orb.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  static const List<_QuickActionItem> _quickActions = [
    _QuickActionItem(
      label: 'Search',
      icon: Icons.search_rounded,
      query: 'Search the web for ',
    ),
    _QuickActionItem(
      label: 'Create',
      icon: Icons.add_circle_outline_rounded,
      query: 'Create a ',
    ),
    _QuickActionItem(
      label: 'Analyze',
      icon: Icons.analytics_outlined,
      query: 'Analyze ',
    ),
    _QuickActionItem(
      label: 'Automate',
      icon: Icons.bolt_rounded,
      query: 'Automate a task for ',
    ),
    _QuickActionItem(
      label: 'Research',
      icon: Icons.biotech_outlined,
      query: 'Research ',
    ),
    _QuickActionItem(
      label: 'More',
      icon: Icons.grid_view_rounded,
      query: 'What can you do?',
    ),
  ];

  static const List<_RecentTaskItem> _recentTasks = [
    _RecentTaskItem(
      title: 'Analyze market trends',
      subtitle: 'Extracted key insights and statistics • 10m ago',
      icon: Icons.insights_rounded,
      accentColor: AppColors.accentCyan,
      query: 'Review market trends analysis',
    ),
    _RecentTaskItem(
      title: 'Summarize meeting notes',
      subtitle: 'Generated action items & owner tags • 1h ago',
      icon: Icons.description_outlined,
      accentColor: AppColors.accentViolet,
      query: 'Show summary of meeting notes',
    ),
    _RecentTaskItem(
      title: 'Automate daily workflow',
      subtitle: 'Scheduled notifications and sync • Yesterday',
      icon: Icons.schedule_rounded,
      accentColor: AppColors.accentPink,
      query: 'Check status of automated daily workflow',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String text) {
    final query = text.trim();
    if (query.isEmpty) return;
    _searchController.clear();
    context.push('/chat', extra: query);
  }

  void _onQuickActionTap(_QuickActionItem action) {
    context.push('/chat', extra: action.query);
  }

  void _onRecentTaskTap(_RecentTaskItem task) {
    context.push('/chat', extra: task.query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: 'JACK AGENT' label & greeting 'Hello!' ───────────────
              _buildHeader(),
              const SizedBox(height: 24),

              // ── Large serif heading: 'What do you want\nJack to do?' ──────
              _buildLargeHeading(),
              const SizedBox(height: 24),

              // ── Search bar: 'Ask Jack anything...' with send button ────────
              _buildSearchBar(),
              const SizedBox(height: 18),

              // ── Quick action chips row ─────────────────────────────────────
              _buildQuickActionChips(),
              const SizedBox(height: 36),

              // ── Centered JACK orb (size 100) ───────────────────────────────
              _buildCenteredOrb(),
              const SizedBox(height: 36),

              // ── Recent tasks section with 2-3 GlassCard items ──────────────
              _buildRecentTasksSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accentCyan,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x8000D4FF),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'JACK AGENT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Hello!',
              style: AppTypography.sectionHeading(
                size: 26,
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Ready',
                style: AppTypography.caption(
                  size: 11,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeHeading() {
    return Text(
      'What do you want\nJack to do?',
      style: AppTypography.display(
        size: 38,
        weight: FontWeight.w400,
        height: 1.12,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSearchBar() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderColor: AppColors.surfaceBorder,
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTypography.body(
                size: 15,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.accentCyan,
              decoration: InputDecoration(
                hintText: 'Ask Jack anything...',
                hintStyle: AppTypography.body(
                  size: 15,
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: _submitSearch,
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _submitSearch(_searchController.text),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: hasText ? AppColors.primaryGradient : null,
                      color: hasText ? null : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: hasText ? Colors.black : AppColors.textTertiary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _quickActions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = _quickActions[index];
          return GlassCard(
            borderRadius: 21,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: () => _onQuickActionTap(action),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 16,
                  color: AppColors.accentCyan,
                ),
                const SizedBox(width: 8),
                Text(
                  action.label,
                  style: AppTypography.body(
                    size: 13,
                    weight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenteredOrb() {
    final realtimeState = ref.watch(agentExecutionProvider);
    final orbState = _mapJackOrbState(realtimeState.orbState);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          JackOrb(
            size: 100,
            state: orbState,
            onTap: () => context.push('/chat', extra: 'Hello Jack!'),
          ),
          const SizedBox(height: 14),
          Text(
            'Tap Jack to start speaking',
            style: AppTypography.caption(
              size: 12,
              color: AppColors.textTertiary,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Maps the 15-state [JackOrbState] from the backend to the 6-state
  /// [OrbState] understood by the [JackOrb] widget.
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
      // IDLE, WAITING_FOR_USER, SPEAKING, OFFLINE, SLEEPING, WAKE
      default:
        return OrbState.idle;
    }
  }


  Widget _buildRecentTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Recent Tasks',
              style: AppTypography.sectionHeading(
                size: 20,
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'View All',
              style: AppTypography.label(
                size: 12,
                color: AppColors.accentCyan,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentTasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final task = _recentTasks[index];
            return GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(14),
              onTap: () => _onRecentTaskTap(task),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: task.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: task.accentColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      task.icon,
                      color: task.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTypography.bodyMedium(
                            size: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          task.subtitle,
                          style: AppTypography.caption(
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final String query;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.query,
  });
}

class _RecentTaskItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String query;

  const _RecentTaskItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.query,
  });
}
