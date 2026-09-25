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

  // 5 Specialized Autonomous Sub-Agents (Grok-inspired Architecture)
  final List<_LibraryItem> _agents = const [
    _LibraryItem(
      id: 'agent_executive',
      title: 'Executive Planner Agent',
      subtitle: 'Decomposes complex goals and coordinates sub-agents.',
      icon: Icons.hub_rounded,
      iconColor: Color(0xFF00E5FF),
      bgGradientStart: Color(0xFF083344),
      bgGradientEnd: Color(0xFF0C4A6E),
      model: 'Groq Llama 3.3 70B Versatile',
      systemPrompt:
          'Autonomous Executive Planner: Breaks objectives into structured sub-tasks, evaluates outputs, and routes between Specialist agents.',
      capabilities: [
        'Multi-Agent Coordination (Grok Architecture)',
        'Goal Decomposition & Dependency Tree',
        'Output Verification & Answer Synthesis',
      ],
    ),
    _LibraryItem(
      id: 'agent_device',
      title: 'Device & DOM Specialist',
      subtitle: 'Performs Android taps, keyboard input, scrolls and hardware.',
      icon: Icons.phone_android_rounded,
      iconColor: Color(0xFF38BDF8),
      bgGradientStart: Color(0xFF0B2545),
      bgGradientEnd: Color(0xFF134074),
      model: 'Android Native Accessibility Bridge',
      systemPrompt:
          'Device & DOM Specialist: Directly controls accessibility node trees, UIAutomator clicks, Shizuku, and hardware switches.',
      capabilities: [
        'Real Native Hardware Switches (Torch, Volume, Bluetooth)',
        'UIAutomator Screen Tap & Text Injection',
        'Installed Package Launcher & App Navigation',
      ],
    ),
    _LibraryItem(
      id: 'agent_research',
      title: 'Deep Research Specialist',
      subtitle: 'Conducts Google search grounding, deals and spec extraction.',
      icon: Icons.travel_explore_rounded,
      iconColor: Color(0xFF2DD4BF),
      bgGradientStart: Color(0xFF064E3B),
      bgGradientEnd: Color(0xFF047857),
      model: 'Google Grounding + Llama 3.3',
      systemPrompt:
          'Deep Research Specialist: Extracts real retail listings, technical specifications, and live web sources with clickable links.',
      capabilities: [
        'Live Google Search Grounding',
        'Side-by-Side Product Comparison (Laptops, Tech)',
        'Verified Store Links & Deal Tracking',
      ],
    ),
    _LibraryItem(
      id: 'agent_mcp',
      title: 'Tool & MCP Integration Agent',
      subtitle: 'Communicates with Gmail, GitHub, Notion, Slack & Drive.',
      icon: Icons.extension_rounded,
      iconColor: Color(0xFF7C3AED),
      bgGradientStart: Color(0xFF2E1065),
      bgGradientEnd: Color(0xFF581C87),
      model: 'Model Context Protocol (JSON-RPC 2.0)',
      systemPrompt:
          'Tool & MCP Integration Agent: Interacts with active MCP server endpoints over JSON-RPC 2.0 and native protocols.',
      capabilities: [
        'Gmail Inbox Triage & Smart Replies',
        'GitHub Pull Request & Repo Dispatcher',
        'Notion, Slack & Cloud Drive Synchronization',
      ],
    ),
    _LibraryItem(
      id: 'agent_telephony',
      title: 'Telephony & Voice Agent',
      subtitle: 'Screens phone calls and speaks in British baritone voice.',
      icon: Icons.record_voice_over_rounded,
      iconColor: Color(0xFFEC4899),
      bgGradientStart: Color(0xFF500724),
      bgGradientEnd: Color(0xFF831843),
      model: 'JARVIS British Baritone TTS',
      systemPrompt:
          'Telephony & Voice Agent: Answers incoming phone calls, screens caller intentions, and maintains natural conversational dialogue.',
      capabilities: [
        'Autonomous Call Screener & Transcription',
        'British Male Baritone Voice (JARVIS Cadence)',
        'Speech-to-Text Continuous Streaming',
      ],
    ),
  ];

  // Saved Prompts
  final List<_LibraryItem> _prompts = const [];

  // Saved Workflows
  final List<_LibraryItem> _workflows = const [];

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

            // ── Cards List 
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No ${_filters[_selectedFilter].toLowerCase()} saved yet.',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
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
        exploreLabel: 'Plugins',
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
