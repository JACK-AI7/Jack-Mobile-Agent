// lib/screens/agent_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class AgentBuilderScreen extends StatefulWidget {
  const AgentBuilderScreen({super.key});

  @override
  State<AgentBuilderScreen> createState() => _AgentBuilderScreenState();
}

class _AgentBuilderScreenState extends State<AgentBuilderScreen> {
  final _nodes = [
    _Node('Trigger', 'User Request', 'What starts the agent', Icons.play_arrow_rounded, AppColors.accentBlue),
    _Node('AI Reasoning', 'LLM', 'Llama 3.3 70B via Groq', Icons.psychology_rounded, AppColors.accentViolet),
    _Node('Tools', 'Apps & APIs', 'Connected integrations', Icons.build_rounded, AppColors.accentCyan),
    _Node('Actions', 'Do Tasks', 'Execute & take action', Icons.bolt_rounded, AppColors.accentPink),
    _Node('Output', 'Result to You', 'Deliver final answer', Icons.check_circle_rounded, AppColors.success),
  ];

  final _sideNodes = ['Skills', 'Data', 'Integrations', 'Knowledge', 'Memory', 'Personality', 'Automations'];
  final Set<String> _added = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agent Builder', style: AppTypography.sectionHeading(size: 22)),
            Text('Visual workflow editor', style: AppTypography.caption()),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header text ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build how your\nagent works',
                  style: AppTypography.heading(size: 30),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drag, connect, and create powerful workflows in minutes.',
                  style: AppTypography.body(size: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Node palette ─────────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sideNodes.length,
              itemBuilder: (context, i) {
                final n = _sideNodes[i];
                final isAdded = _added.contains(n);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (isAdded) {
                        _added.remove(n);
                      } else {
                        _added.add(n);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAdded
                            ? AppColors.accentViolet.withOpacity(0.2)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isAdded ? AppColors.accentViolet : AppColors.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAdded)
                            const Icon(Icons.check_rounded, size: 12, color: AppColors.accentViolet),
                          if (isAdded) const SizedBox(width: 4),
                          Text(n,
                              style: AppTypography.caption(
                                  size: 12,
                                  color: isAdded ? AppColors.accentViolet : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Workflow nodes ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _nodes.length,
              itemBuilder: (context, i) {
                final node = _nodes[i];
                final isLast = i == _nodes.length - 1;
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showNodeConfig(context, node),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: node.color.withOpacity(0.3)),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              node.color.withOpacity(0.1),
                              AppColors.surfaceCard,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 70,
                              decoration: BoxDecoration(
                                color: node.color,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: node.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(node.icon, color: node.color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(node.category,
                                      style: AppTypography.caption(size: 10, color: node.color)),
                                  Text(node.title, style: AppTypography.bodyMedium(size: 15)),
                                  Text(node.subtitle, style: AppTypography.caption(size: 11)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Icon(Icons.settings_rounded,
                                  size: 16, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 20,
                        margin: const EdgeInsets.only(left: 32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [node.color, _nodes[i + 1].color],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Create button ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Agent saved to Library!',
                        style: AppTypography.body(size: 14, color: Colors.white)),
                    backgroundColor: AppColors.accentViolet,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.accentCyan, AppColors.accentViolet],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Create New Agent', style: AppTypography.button(size: 15, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNodeConfig(BuildContext context, _Node node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: node.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(node.icon, color: node.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.title, style: AppTypography.bodySemiBold(size: 16)),
                      Text(node.subtitle, style: AppTypography.caption(size: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Configuration', style: AppTypography.bodySemiBold(size: 14)),
              const SizedBox(height: 12),
              Text('Node settings will be available in Pro version.',
                  style: AppTypography.body(size: 14)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: node.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: node.color.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('Save & Apply',
                        style: AppTypography.button(size: 14, color: node.color)),
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

class _Node {
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Node(this.category, this.title, this.subtitle, this.icon, this.color);
}
