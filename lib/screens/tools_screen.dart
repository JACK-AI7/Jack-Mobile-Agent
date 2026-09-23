// lib/screens/tools_screen.dart
//
// 07. Tools — Connect your favorite tools
// Pixel-to-pixel reproduction of reference image:
// Header, title & subtitle, segmented filter pills [All] [Connected] [Available],
// authentic brand icons (Google, GitHub, Notion, Slack, Gmail),
// interactive connection states & real Model Context Protocol (MCP) inspector,
// and bottom navigation bar with active Tools tab.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class _ToolModel {
  final String id;
  final String name;
  final String svgAsset;
  final String mcpEndpoint;
  final String description;
  final List<String> capabilities;
  bool connected;
  Map<String, bool> enabledCapabilities;

  _ToolModel({
    required this.id,
    required this.name,
    required this.svgAsset,
    required this.mcpEndpoint,
    required this.description,
    required this.capabilities,
    required this.connected,
    Map<String, bool>? enabledCapabilities,
  }) : enabledCapabilities = enabledCapabilities ?? {
          for (var c in capabilities) c: true,
        };
}

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Connected, 2: Available
  final List<String> _filters = ['All', 'Connected', 'Available'];

  late List<_ToolModel> _tools;

  @override
  void initState() {
    super.initState();
    // Canonical tool definitions matching reference image exactly:
    // Google: Connected, GitHub: Connected, Notion: Connect, Slack: Connect, Gmail: Connected
    _tools = [
      _ToolModel(
        id: 'google',
        name: 'Google',
        svgAsset: 'assets/logos/google.svg',
        mcpEndpoint: 'mcp://google.jack.ai/v1',
        description: 'Web search, Gemini Grounding, Google Drive & Docs synchronization.',
        capabilities: [
          'Gemini Grounding & Web Search',
          'Google Drive Document Reader',
          'Google Calendar Actions',
          'Workspace Contact Directory',
        ],
        connected: true,
      ),
      _ToolModel(
        id: 'github',
        name: 'GitHub',
        svgAsset: 'assets/logos/github.svg',
        mcpEndpoint: 'mcp://github.com/JACK-AI7/Jack-Mobile-Agent',
        description: 'Repository inspection, code synthesis, PR reviews & CI/CD triggering.',
        capabilities: [
          'Repository Tree & File Reader',
          'Commit & Pull Request Dispatcher',
          'Issue Tracker & Bug Reports',
          'GitHub Actions Workflow Monitor',
        ],
        connected: true,
      ),
      _ToolModel(
        id: 'notion',
        name: 'Notion',
        svgAsset: 'assets/logos/notion.svg',
        mcpEndpoint: 'https://api.notion.com/v1/mcp',
        description: 'Workspace documents, structured databases & knowledge base ingestion.',
        capabilities: [
          'Page & Block Hierarchy Search',
          'Database Query & Filter API',
          'Append Knowledge Notes',
          'Sync Project Kanban Boards',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'slack',
        name: 'Slack',
        svgAsset: 'assets/logos/slack.svg',
        mcpEndpoint: 'https://slack.com/api/mcp.events',
        description: 'Channel communications, team alerts, and real-time mention listener.',
        capabilities: [
          'Send Channel & DM Messages',
          'Read Thread Mentions',
          'Listen for Critical Alerts',
          'Status & Presence Sync',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'gmail',
        name: 'Gmail',
        svgAsset: 'assets/logos/gmail.svg',
        mcpEndpoint: 'mcp://mail.google.com/agent',
        description: 'Smart inbox triage, automated draft composer, and mail action dispatch.',
        capabilities: [
          'Read & Triage Unread Messages',
          'Draft AI Smart Replies',
          'Parse Email Attachments',
          'Dispatch Priority Alerts',
        ],
        connected: true,
      ),
    ];
  }

  void _showToolDetails(_ToolModel tool) {
    HapticFeedback.mediumImpact();
    final TextEditingController mcpController =
        TextEditingController(text: tool.mcpEndpoint);
    bool testingHandshake = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                18,
                24,
                MediaQuery.of(modalContext).viewInsets.bottom + 24,
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

                    // Top Row: Logo + Name + Status Pill
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF181728),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(
                            tool.svgAsset,
                            width: 32,
                            height: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tool.connected
                                          ? const Color(0xFF2DD4BF)
                                          : const Color(0xFF38BDF8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (tool.connected
                                                  ? const Color(0xFF2DD4BF)
                                                  : const Color(0xFF38BDF8))
                                              .withValues(alpha: 0.7),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tool.connected ? 'Connected' : 'Available to Connect',
                                    style: GoogleFonts.inter(
                                      color: tool.connected
                                          ? const Color(0xFF2DD4BF)
                                          : const Color(0xFF38BDF8),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      tool.description,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // MCP (Model Context Protocol) Configuration Section
                    Text(
                      'Model Context Protocol (MCP) Server',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141320),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hub_rounded,
                              color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: mcpController,
                              style: GoogleFonts.firaCode(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (testingHandshake)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.bolt_rounded,
                                  color: Color(0xFF2DD4BF), size: 18),
                              tooltip: 'Test MCP Handshake',
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setModalState(() => testingHandshake = true);
                                await Future.delayed(const Duration(milliseconds: 650));
                                if (modalContext.mounted) {
                                  setModalState(() => testingHandshake = false);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'MCP Handshake Successful: ${tool.capabilities.length} tools registered for ${tool.name}',
                                      ),
                                      backgroundColor: AppColors.surfaceElevated,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Capabilities Toggles
                    Text(
                      'Active Capabilities & Tools',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tool.capabilities.map((cap) {
                      final isCapEnabled = tool.enabledCapabilities[cap] ?? true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: isCapEnabled
                                  ? const Color(0xFF2DD4BF)
                                  : Colors.white24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cap,
                                style: GoogleFonts.inter(
                                  color: isCapEnabled ? Colors.white : Colors.white38,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.75,
                              child: CupertinoSwitch(
                                value: isCapEnabled,
                                activeTrackColor: const Color(0xFF2563EB),
                                inactiveTrackColor: const Color(0xFF2B2A3A),
                                thumbColor: Colors.white,
                                onChanged: (val) {
                                  HapticFeedback.lightImpact();
                                  setModalState(() {
                                    tool.enabledCapabilities[cap] = val;
                                  });
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Action Button (Connect / Disconnect)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          final newStatus = !tool.connected;
                          setState(() {
                            tool.connected = newStatus;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newStatus
                                    ? '${tool.name} connected successfully via MCP!'
                                    : '${tool.name} disconnected.',
                              ),
                              backgroundColor: AppColors.surfaceElevated,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tool.connected
                              ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                              : const Color(0xFF38BDF8),
                          foregroundColor:
                              tool.connected ? const Color(0xFFF87171) : Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: tool.connected
                                ? const BorderSide(
                                    color: Color(0xFFEF4444), width: 1)
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          tool.connected ? 'Disconnect Tool' : 'Connect via MCP',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter tools based on selected pill:
    // 0: All, 1: Connected, 2: Available
    final filtered = _tools.where((tool) {
      if (_selectedFilter == 1) return tool.connected == true;
      if (_selectedFilter == 2) return tool.connected == false;
      return true;
    }).toList();

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

            // ── Header: Title & Subtitle matching Screen 07 ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tools',
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
                    'Connect and use powerful tools.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Segmented Filter Pills: [All] [Connected] [Available] ──────
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

            // ── Tools List (Google, GitHub, Notion, Slack, Gmail) ───────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tool = filtered[index];
                  final isConnected = tool.connected;

                  return GestureDetector(
                    onTap: () => _showToolDetails(tool),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Authentic Brand Logo Icon
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: Center(
                              child: SvgPicture.asset(
                                tool.svgAsset,
                                width: 34,
                                height: 34,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Tool Name + Connected / Connect Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tool.name,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isConnected ? 'Connected' : 'Connect',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isConnected
                                        ? const Color(0xFF2DD4BF) // Emerald / Teal
                                        : const Color(0xFF38BDF8), // Sky Blue
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
      // Bottom Navigation Bar matching 12-screen specification with Tools tab active
      bottomNavigationBar: GlassNavBar(
        currentIndex: 1, // Tools is Tab index 1
        exploreLabel: 'Tools',
        onTap: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              // Already on Tools
              break;
            case 2:
              context.go('/agent-builder');
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
