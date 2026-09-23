// lib/screens/library_screen.dart
//
// 08. Library — Saved agents, prompts & workflows
// Pixel-to-pixel reproduction of reference image:
// Header, title & two-line subtitle, segmented filter pills [Agents] [Prompts] [Workflows],
// 5 canonical agent cards (Research Agent, Content Agent, Data Analyst, Social Media Agent, Custom Agent),
// interactive details & execution sheets, and bottom navigation bar with active Library tab.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class _LibraryItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgGradientStart;
  final Color bgGradientEnd;
  final String model;
  final String systemPrompt;
  final List<String> capabilities;

  const _LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgGradientStart,
    required this.bgGradientEnd,
    required this.model,
    required this.systemPrompt,
    required this.capabilities,
  });
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedFilter = 0; // 0: Agents, 1: Prompts, 2: Workflows
  final List<String> _filters = ['Agents', 'Prompts', 'Workflows'];

  // Canonical 5 Agents matching reference image exactly:
  // 1. Research Agent (Deep research & analysis, purple flower/gear)
  // 2. Content Agent (Create & edit content, cyan document)
  // 3. Data Analyst (Analyze data & generate insights, blue chart)
  // 4. Social Media Agent (Plan & schedule posts, navy/slate capsule)
  // 5. Custom Agent (Your own agent, luminous purple crosshair)
  final List<_LibraryItem> _agents = const [
    _LibraryItem(
      id: 'research_agent',
      title: 'Research Agent',
      subtitle: 'Deep research & analysis',
      icon: Icons.auto_awesome_rounded,
      iconColor: Color(0xFFC084FC),
      bgGradientStart: Color(0xFF3B0764),
      bgGradientEnd: Color(0xFF1E1035),
      model: 'Llama 3.3 70B Versatile',
      systemPrompt:
          'You are an expert research analyst. Gather facts, synthesize complex sources, cite data points, and deliver structured briefings.',
      capabilities: [
        'Web Search & Grounding',
        'Academic Paper Synthesis',
        'Competitor Landscape Mapping',
        'Executive Briefing Generation',
      ],
    ),
    _LibraryItem(
      id: 'content_agent',
      title: 'Content Agent',
      subtitle: 'Create & edit content',
      icon: Icons.article_rounded,
      iconColor: Color(0xFF22D3EE),
      bgGradientStart: Color(0xFF0E4A5C),
      bgGradientEnd: Color(0xFF08222C),
      model: 'Llama 3.3 70B Versatile',
      systemPrompt:
          'You are a premier content strategist and copywriter. Draft compelling narratives, blog posts, changelogs, and marketing copy.',
      capabilities: [
        'Long-form Article Drafting',
        'Grammar & Tone Modulation',
        'Social Hook Generation',
        'SEO Keyword Integration',
      ],
    ),
    _LibraryItem(
      id: 'data_analyst',
      title: 'Data Analyst',
      subtitle: 'Analyze data & generate insights',
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF38BDF8),
      bgGradientStart: Color(0xFF1E3A8A),
      bgGradientEnd: Color(0xFF0F172A),
      model: 'DeepSeek R1 / Llama 70B',
      systemPrompt:
          'You are a senior quantitative data scientist. Parse numerical datasets, calculate trends, detect anomalies, and derive strategic conclusions.',
      capabilities: [
        'CSV & JSON Schema Analysis',
        'Statistical Regression',
        'Trend & Outlier Detection',
        'Visualization Prompting',
      ],
    ),
    _LibraryItem(
      id: 'social_media_agent',
      title: 'Social Media Agent',
      subtitle: 'Plan & schedule posts',
      icon: Icons.rocket_launch_rounded,
      iconColor: Color(0xFFA5B4FC),
      bgGradientStart: Color(0xFF1E293B),
      bgGradientEnd: Color(0xFF0F172A),
      model: 'Llama 3.3 70B Versatile',
      systemPrompt:
          'You are a high-growth social media manager. Architect viral threads, schedule multi-channel updates, and optimize engagement hooks.',
      capabilities: [
        'Viral Hook Generation',
        'Cross-platform Scheduling',
        'Audience Persona Triage',
        'Hashtag & Metric Strategy',
      ],
    ),
    _LibraryItem(
      id: 'custom_agent',
      title: 'Custom Agent',
      subtitle: 'Your own agent',
      icon: Icons.track_changes_rounded,
      iconColor: Color(0xFFE879F9),
      bgGradientStart: Color(0xFF7C3AED),
      bgGradientEnd: Color(0xFF4C1D95),
      model: 'Fully Configurable',
      systemPrompt:
          'You are a custom AI agent tailored by the user with personalized memory, tools, and reasoning rules.',
      capabilities: [
        'Custom Tool Bindings',
        'Episodic Memory Access',
        'Automated Action Triggers',
        'Multi-Agent Delegation',
      ],
    ),
  ];

  // Saved Prompts
  final List<_LibraryItem> _prompts = const [
    _LibraryItem(
      id: 'prompt_1',
      title: 'Market Analysis Template',
      subtitle: 'TAM, SAM & SOM competitor breakdown',
      icon: Icons.pie_chart_rounded,
      iconColor: Color(0xFFFBBF24),
      bgGradientStart: Color(0xFF78350F),
      bgGradientEnd: Color(0xFF1E1305),
      model: 'Groq Llama 3.3',
      systemPrompt: 'Provide a structured total addressable market analysis.',
      capabilities: ['Market Sizing', 'Competitor Comparison'],
    ),
    _LibraryItem(
      id: 'prompt_2',
      title: 'Code Architecture Review',
      subtitle: 'Detect bottlenecks & structural debt',
      icon: Icons.code_rounded,
      iconColor: Color(0xFF34D399),
      bgGradientStart: Color(0xFF064E3B),
      bgGradientEnd: Color(0xFF022C22),
      model: 'Groq Llama 3.3',
      systemPrompt: 'Analyze code repository for anti-patterns and performance.',
      capabilities: ['Refactoring', 'Lint Analysis'],
    ),
    _LibraryItem(
      id: 'prompt_3',
      title: 'Daily Standup Summary',
      subtitle: 'Consolidate git commits & blocker tickets',
      icon: Icons.fact_check_rounded,
      iconColor: Color(0xFF60A5FA),
      bgGradientStart: Color(0xFF1E3A8A),
      bgGradientEnd: Color(0xFF0F172A),
      model: 'Groq Llama 3.3',
      systemPrompt: 'Generate a clean bulleted 3-part daily standup summary.',
      capabilities: ['Sprint Tracking', 'Git Log Parsing'],
    ),
  ];

  // Saved Workflows
  final List<_LibraryItem> _workflows = const [
    _LibraryItem(
      id: 'workflow_1',
      title: 'Autonomous Market Intel',
      subtitle: 'Search competitors → Scrape → Briefing',
      icon: Icons.account_tree_rounded,
      iconColor: Color(0xFFFB923C),
      bgGradientStart: Color(0xFF7C2D12),
      bgGradientEnd: Color(0xFF1E0A05),
      model: 'Multi-Agent Pipeline',
      systemPrompt: 'Execute multi-step pipeline for market data intelligence.',
      capabilities: ['Web Crawler', 'Summarizer', 'Export to PDF'],
    ),
    _LibraryItem(
      id: 'workflow_2',
      title: 'CI/CD Auto-Remediation',
      subtitle: 'Catch test failures → Patch → Open PR',
      icon: Icons.healing_rounded,
      iconColor: Color(0xFF38BDF8),
      bgGradientStart: Color(0xFF0369A1),
      bgGradientEnd: Color(0xFF082F49),
      model: 'Multi-Agent Pipeline',
      systemPrompt: 'Analyze build logs and automatically propose fixes.',
      capabilities: ['Log Parser', 'Diff Generator', 'GitHub Dispatcher'],
    ),
    _LibraryItem(
      id: 'workflow_3',
      title: 'Lead Sourcing Pipeline',
      subtitle: 'Ingest signups → Enrich metadata → Slack alert',
      icon: Icons.hub_rounded,
      iconColor: Color(0xFFA855F7),
      bgGradientStart: Color(0xFF581C87),
      bgGradientEnd: Color(0xFF1E0638),
      model: 'Multi-Agent Pipeline',
      systemPrompt: 'Enrich lead contact profiles and send real-time alerts.',
      capabilities: ['Data Enrichment', 'Slack Webhook', 'CRM Sync'],
    ),
  ];

  void _showItemInspector(_LibraryItem item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          18,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header: Icon Badge + Name + Subtitle
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [item.bgGradientStart, item.bgGradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.iconColor.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.iconColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(item.icon, color: item.iconColor, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              // Model & Routing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inference Engine',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1D33),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      item.model,
                      style: GoogleFonts.inter(
                        color: AppColors.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Capabilities
              Text(
                'Capabilities',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.capabilities.map((c) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181728),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: item.iconColor),
                        const SizedBox(width: 6),
                        Text(
                          c,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/agent-builder');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Edit Config',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(
                          '/chat',
                          extra: 'Initialize and run ${item.title}: ${item.subtitle}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Run ${item.title.split(" ").first}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Select items based on active pill
    final items = _selectedFilter == 0
        ? _agents
        : (_selectedFilter == 1 ? _prompts : _workflows);

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Colors.white70,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // ── Header: Title & Two-line Subtitle matching Screen 08 ────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your saved agents, prompts\nand workflows.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Segmented Filter Pills: [Agents] [Prompts] [Workflows] ─────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final active = _selectedFilter == i;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = i);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF38BDF8) // Reference Blue
                              : const Color(0xFF141320),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _filters[i],
                            style: GoogleFonts.inter(
                              color: active ? Colors.black : Colors.white70,
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Cards List (Research Agent, Content Agent, Data Analyst, etc.) 
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return GestureDetector(
                    onTap: () => _showItemInspector(item),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141320),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Leading Vibrant Icon Badge
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  item.bgGradientStart,
                                  item.bgGradientEnd
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.iconColor.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                item.icon,
                                color: item.iconColor,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title and Subtitle Stack
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.subtitle,
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Trailing Chevron
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white30,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar with active Library tab matching reference Screen 08
      bottomNavigationBar: GlassNavBar(
        currentIndex: 2, // Library tab
        isLibraryActive: true,
        exploreLabel: 'Tools',
        onTap: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/tools');
              break;
            case 2:
              // Already on Library
              break;
            case 3:
              context.go('/tasks');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
