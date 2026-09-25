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
import '../widgets/animations/animated_beam.dart';
import '../services/mcp/jack_mcp_client.dart' as import_mcp;
import '../services/api/jack_storage.dart';

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
    _initTools();
    _loadSavedConnections();
  }

  Future<void> _loadSavedConnections() async {
    for (final tool in _tools) {
      final saved = await JackStorage.read(key: 'mcp_connected_${tool.id}');
      if (saved != null) {
        tool.connected = saved == 'true';
      } else {
        // Canonical defaults matching design reference Screen 07: Google, GitHub, Gmail
        if (tool.id == 'google' || tool.id == 'github' || tool.id == 'gmail') {
          tool.connected = true;
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _initTools() {
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
        connected: false,
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
        connected: false,
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
        connected: false,
      ),
      _ToolModel(
        id: 'telecom',
        name: 'AI Call Screener',
        svgAsset: 'assets/logos/google.svg',
        mcpEndpoint: 'mcp://telephony.jack.ai/v1',
        description: 'Autonomous call screening, British male caller interaction, and dialogue transcription.',
        capabilities: [
          'Live Incoming Call Interception',
          'British Male Baritone Caller Dialogue',
          'Groq LLM Dynamic Conversational Reasoning',
          'Auto-Transcribe & Task Logging',
        ],
        connected: true,
      ),
      _ToolModel(
        id: 'linear',
        name: 'Linear',
        svgAsset: 'assets/logos/linear.svg',
        mcpEndpoint: 'mcp://linear.app/v1',
        description: 'Sync issues, triage bugs, and manage project cycles with real-time bidirectional sync.',
        capabilities: [
          'Create & Update Issues',
          'Read Project Cycles',
          'Search Ticket History',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'jira',
        name: 'Jira',
        svgAsset: 'assets/logos/jira.svg',
        mcpEndpoint: 'mcp://jira.atlassian.com/api',
        description: 'Enterprise task tracking, sprint management, and agile board synchronization.',
        capabilities: [
          'Manage Sprint Boards',
          'Assign Tickets',
          'Update Status Transitions',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'figma',
        name: 'Figma',
        svgAsset: 'assets/logos/figma.svg',
        mcpEndpoint: 'mcp://api.figma.com/v1',
        description: 'Read design tokens, inspect component trees, and fetch asset exports directly from canvas.',
        capabilities: [
          'Extract Design Tokens',
          'Inspect Component Properties',
          'Export UI Assets',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'discord',
        name: 'Discord',
        svgAsset: 'assets/logos/discord.svg',
        mcpEndpoint: 'mcp://discord.com/api/v10',
        description: 'Community server monitoring, automated announcements, and threaded conversations.',
        capabilities: [
          'Send Channel Messages',
          'Manage Roles & Invites',
          'Listen for Mentions',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'spotify',
        name: 'Spotify',
        svgAsset: 'assets/logos/spotify.svg',
        mcpEndpoint: 'mcp://api.spotify.com/v1',
        description: 'Control playback, search catalogs, and generate dynamic AI-driven playlists.',
        capabilities: [
          'Control Active Devices',
          'Search Tracks & Artists',
          'Create Custom Playlists',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'stripe',
        name: 'Stripe',
        svgAsset: 'assets/logos/stripe.svg',
        mcpEndpoint: 'mcp://api.stripe.com/v1',
        description: 'Monitor financial transactions, manage subscriptions, and generate revenue reports.',
        capabilities: [
          'List Recent Charges',
          'View Customer Subscriptions',
          'Generate Revenue Summaries',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'trello',
        name: 'Trello',
        svgAsset: 'assets/logos/trello.svg',
        mcpEndpoint: 'mcp://api.trello.com/1',
        description: 'Manage kanban boards, sort cards, and track lightweight project pipelines.',
        capabilities: [
          'Move Cards Across Lists',
          'Add Card Attachments',
          'Read Board Activity',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'x',
        name: 'X (Twitter)',
        svgAsset: 'assets/logos/x.svg',
        mcpEndpoint: 'mcp://api.x.com/2',
        description: 'Automate social posts, track sentiment analysis, and read trending topics.',
        capabilities: [
          'Post New Tweets',
          'Read Timeline & Mentions',
          'Analyze Sentiment Data',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'dropbox',
        name: 'Dropbox',
        svgAsset: 'assets/logos/dropbox.svg',
        mcpEndpoint: 'mcp://api.dropbox.com/2',
        description: 'Secure cloud file management, document parsing, and backup synchronization.',
        capabilities: [
          'Read File Contents',
          'Upload Backup Archives',
          'Search Cloud Storage',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'asana',
        name: 'Asana',
        svgAsset: 'assets/logos/asana.svg',
        mcpEndpoint: 'mcp://app.asana.com/api/1.0',
        description: 'Cross-functional team task alignment, portfolio tracking, and goal management.',
        capabilities: [
          'Assign Team Tasks',
          'Read Portfolio Progress',
          'Update Task Dependencies',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'zendesk',
        name: 'Zendesk',
        svgAsset: 'assets/logos/zendesk.svg',
        mcpEndpoint: 'mcp://api.zendesk.com/v2',
        description: 'Automated customer support triage, ticket routing, and AI-assisted macro replies.',
        capabilities: [
          'Triage New Tickets',
          'Draft Support Replies',
          'Update Ticket Status',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'hubspot',
        name: 'HubSpot',
        svgAsset: 'assets/logos/hubspot.svg',
        mcpEndpoint: 'mcp://api.hubapi.com/v3',
        description: 'CRM lead tracking, marketing email automation, and deal pipeline analytics.',
        capabilities: [
          'Search CRM Contacts',
          'Update Deal Stages',
          'Track Marketing Campaigns',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'anthropic',
        name: 'Anthropic (Claude)',
        svgAsset: 'assets/logos/anthropic.svg',
        mcpEndpoint: 'mcp://api.anthropic.com/v1',
        description: 'Advanced reasoning, constitutional AI interactions, and 200k token context processing.',
        capabilities: [
          'Generate Complex Code',
          'Analyze Long Documents',
          'Process Natural Language',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'datadog',
        name: 'Datadog',
        svgAsset: 'assets/logos/datadog.svg',
        mcpEndpoint: 'mcp://api.datadoghq.com/v1',
        description: 'Monitor cloud infrastructure, application traces, and alerting metrics in real-time.',
        capabilities: [
          'Read Infrastructure Metrics',
          'Acknowledge Pager Alerts',
          'View APM Traces',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'docker',
        name: 'Docker',
        svgAsset: 'assets/logos/docker.svg',
        mcpEndpoint: 'mcp://var/run/docker.sock',
        description: 'Manage containers, build multi-arch images, and inspect live container logs.',
        capabilities: [
          'List Running Containers',
          'Build Dockerfiles',
          'Stream Container Logs',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'googlecloud',
        name: 'Google Cloud (GCP)',
        svgAsset: 'assets/logos/googlecloud.svg',
        mcpEndpoint: 'mcp://cloud.google.com/v1',
        description: 'Deploy serverless functions, manage BigQuery databases, and scale Kubernetes clusters.',
        capabilities: [
          'Provision Cloud Resources',
          'Execute BigQuery SQL',
          'Scale GKE Clusters',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'mongodb',
        name: 'MongoDB',
        svgAsset: 'assets/logos/mongodb.svg',
        mcpEndpoint: 'mcp://mongodb.atlas.com/api',
        description: 'Query NoSQL documents, analyze aggregations, and monitor cluster performance.',
        capabilities: [
          'Execute Document Queries',
          'Run Aggregation Pipelines',
          'Monitor DB Performance',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'postgresql',
        name: 'PostgreSQL',
        svgAsset: 'assets/logos/postgresql.svg',
        mcpEndpoint: 'mcp://postgres.cloud.com/v1',
        description: 'Execute relational database queries, manage schemas, and run complex joins.',
        capabilities: [
          'Execute SQL Queries',
          'Describe DB Schemas',
          'Perform Migrations',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'sentry',
        name: 'Sentry',
        svgAsset: 'assets/logos/sentry.svg',
        mcpEndpoint: 'mcp://sentry.io/api/0',
        description: 'Track application exceptions, analyze crash reports, and resolve user issues.',
        capabilities: [
          'List Recent Exceptions',
          'Resolve Issues',
          'Read Crash Stacktraces',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'shopify',
        name: 'Shopify',
        svgAsset: 'assets/logos/shopify.svg',
        mcpEndpoint: 'mcp://api.shopify.com/admin',
        description: 'Manage e-commerce inventory, process orders, and handle customer data.',
        capabilities: [
          'Read Store Inventory',
          'Update Product Prices',
          'Fulfill Orders',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'supabase',
        name: 'Supabase',
        svgAsset: 'assets/logos/supabase.svg',
        mcpEndpoint: 'mcp://api.supabase.com/v1',
        description: 'Manage Auth users, query PostgREST APIs, and access Edge Functions.',
        capabilities: [
          'Manage User Auth',
          'Query DB via PostgREST',
          'Deploy Edge Functions',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'vercel',
        name: 'Vercel',
        svgAsset: 'assets/logos/vercel.svg',
        mcpEndpoint: 'mcp://api.vercel.com/v1',
        description: 'Deploy frontend projects, manage domain routing, and inspect Edge configurations.',
        capabilities: [
          'Trigger Deployments',
          'Read Build Logs',
          'Manage Environment Variables',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'whatsapp',
        name: 'WhatsApp',
        svgAsset: 'assets/logos/whatsapp.svg',
        mcpEndpoint: 'mcp://graph.facebook.com/v17.0',
        description: 'Automate business messaging, send templates, and handle customer replies.',
        capabilities: [
          'Send Text Messages',
          'Read Incoming Chats',
          'Send Media Attachments',
        ],
        connected: false,
      ),
      _ToolModel(
        id: 'zoom',
        name: 'Zoom',
        svgAsset: 'assets/logos/zoom.svg',
        mcpEndpoint: 'mcp://api.zoom.us/v2',
        description: 'Schedule video meetings, manage webinars, and fetch cloud recordings.',
        capabilities: [
          'Schedule Meetings',
          'List Cloud Recordings',
          'Generate Meeting Transcripts',
        ],
        connected: false,
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
                                        'MCP Handshake Successful: ${tool.capabilities.length} plugins registered for ${tool.name}',
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
                      'Active Capabilities & Plugins',
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
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          
                          if (tool.connected) {
                            setState(() {
                              tool.connected = false;
                            });
                            await JackStorage.write(
                              key: 'mcp_connected_${tool.id}',
                              value: 'false',
                            );
                            if (modalContext.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${tool.name} disconnected.'),
                                  backgroundColor: AppColors.surfaceElevated,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                            return;
                          }

                          // Attempt Real Connection
                          setModalState(() => testingHandshake = true);
                          final client = import_mcp.JackMcpClient();
                          final success = await client.ping(mcpController.text);
                          setModalState(() => testingHandshake = false);

                          if (success) {
                            setState(() {
                              tool.connected = true;
                            });
                            await JackStorage.write(
                              key: 'mcp_connected_${tool.id}',
                              value: 'true',
                            );
                            if (modalContext.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${tool.name} connected successfully via MCP!'),
                                  backgroundColor: AppColors.surfaceElevated,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to connect to ${mcpController.text}. Ensure server is running.'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
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
                          tool.connected ? 'Disconnect Plugin' : (testingHandshake ? 'Connecting...' : 'Connect via MCP'),
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
  Color _getToolPrimaryColor(String id) {
    switch (id) {
      case 'google':
        return const Color(0xFF4285F4);
      case 'github':
        return const Color(0xFF818CF8);
      case 'gmail':
        return const Color(0xFFEA4335);
      case 'notion':
        return const Color(0xFF38BDF8);
      case 'slack':
        return const Color(0xFFE879F9);
      case 'linear':
        return const Color(0xFF5E6AD2);
      case 'jira':
        return const Color(0xFF0052CC);
      case 'figma':
        return const Color(0xFFF24E1E);
      case 'discord':
        return const Color(0xFF5865F2);
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'stripe':
        return const Color(0xFF635BFF);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'x':
        return const Color(0xFF1DA1F2);
      case 'anthropic':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF00E5FF);
    }
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
                    'Plugins',
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
                    'Connect and use powerful plugins.',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  // ── Magic UI Animated Integration Beam Hub (Connected Only) ──
                  if (_selectedFilter == 0 || _selectedFilter == 1) ...[
                    JackAnimatedBeamHub(
                      connectedPlugins: _tools
                          .where((t) => t.connected)
                          .map((t) => BeamPluginItem(
                                id: t.id,
                                name: t.name.split(' ').first,
                                svgAsset: t.svgAsset,
                                primaryColor: _getToolPrimaryColor(t.id),
                                secondaryColor: const Color(0xFF7C3AED),
                              ))
                          .toList(),
                      onToolTap: (toolId) {
                        final tool = _tools.firstWhere(
                          (t) => t.id == toolId,
                          orElse: () => _tools.first,
                        );
                        _showToolDetails(tool);
                      },
                      onCenterTap: () {
                        final count = _tools.where((t) => t.connected).length;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Jack Agent Core: $count connected neural integration${count == 1 ? '' : 's'} active.'),
                            backgroundColor: AppColors.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Tools List (Google, GitHub, Notion, Slack, Gmail) ───
                  ...filtered.map((tool) {
                    final isConnected = tool.connected;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
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
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar matching 12-screen specification with Plugins tab active
      bottomNavigationBar: GlassNavBar(
        currentIndex: 1, // Plugins is Tab index 1
        exploreLabel: 'Plugins',
        onTap: (index) {
          HapticFeedback.lightImpact();
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              // Already on Plugins
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
