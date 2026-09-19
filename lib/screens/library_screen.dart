// lib/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _filterIndex = 0;
  static const _filters = ['Agents', 'Prompts', 'Workflows'];

  final _agents = [
    _Agent('Research Agent', 'Deep research & analysis', Icons.search_rounded, AppColors.accentCyan),
    _Agent('Content Agent', 'Create & edit content', Icons.edit_rounded, AppColors.accentViolet),
    _Agent('Data Analyst', 'Analyze data & generate insights', Icons.bar_chart_rounded, AppColors.accentBlue),
    _Agent('Social Media', 'Plan & schedule posts', Icons.share_rounded, AppColors.accentPink),
    _Agent('Custom Agent', 'Build your own agent', Icons.add_circle_rounded, AppColors.accentTeal),
    _Agent('Email Agent', 'Draft and send emails', Icons.email_rounded, AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agent-builder'),
        backgroundColor: AppColors.accentCyan,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: Text('New Agent', style: AppTypography.button(size: 14, color: Colors.black)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Library', style: AppTypography.heading(size: 34)),
                  const SizedBox(height: 4),
                  Text('Your saved agents, prompts and workflows.',
                      style: AppTypography.body(size: 14)),
                  const SizedBox(height: 16),
                  // Filter tabs
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: _filters.asMap().entries.map((e) {
                        final isSelected = _filterIndex == e.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _filterIndex = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentCyan.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Text(e.value,
                                    style: AppTypography.caption(
                                        size: 13,
                                        color: isSelected
                                            ? AppColors.accentCyan
                                            : AppColors.textSecondary)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _agents.length,
                itemBuilder: (context, i) => _AgentCard(agent: _agents[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Agent {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  const _Agent(this.name, this.description, this.icon, this.color);
}

class _AgentCard extends StatelessWidget {
  final _Agent agent;
  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: agent.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: agent.color.withOpacity(0.2)),
            ),
            child: Icon(agent.icon, color: agent.color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(agent.name,
              style: AppTypography.bodySemiBold(size: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Expanded(
            child: Text(agent.description,
                style: AppTypography.caption(size: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [agent.color, AppColors.accentViolet],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('Run', style: AppTypography.caption(size: 12, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
