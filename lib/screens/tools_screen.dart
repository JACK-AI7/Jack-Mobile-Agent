// lib/screens/tools_screen.dart
//
// Jack — Tools & Integrations Screen
// Manage and connect external apps, APIs, and custom integrations.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _IntegrationItem {
  final String id;
  final String name;
  final String description;
  final String iconLetter;
  final Color iconColor;
  final Color iconTextColor;
  final Set<String> categories;
  final bool isBuiltIn;
  bool isConnected;

  _IntegrationItem({
    required this.id,
    required this.name,
    required this.description,
    required this.iconLetter,
    required this.iconColor,
    this.iconTextColor = Colors.white,
    required this.categories,
    this.isBuiltIn = false,
    required this.isConnected,
  });
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _selectedFilter = 'All';

  final List<_IntegrationItem> _integrations = [
    _IntegrationItem(
      id: 'google',
      name: 'Google',
      description: 'Search, Drive, Calendar',
      iconLetter: 'G',
      iconColor: const Color(0xFF4285F4),
      categories: {'Apps', 'APIs'},
      isConnected: true,
    ),
    _IntegrationItem(
      id: 'github',
      name: 'GitHub',
      description: 'Code, repos, PRs',
      iconLetter: 'G',
      iconColor: const Color(0xFF6E5494),
      categories: {'APIs', 'Apps'},
      isConnected: false,
    ),
    _IntegrationItem(
      id: 'notion',
      name: 'Notion',
      description: 'Notes & databases',
      iconLetter: 'N',
      iconColor: const Color(0xFFE16259),
      categories: {'Apps'},
      isConnected: false,
    ),
    _IntegrationItem(
      id: 'slack',
      name: 'Slack',
      description: 'Team messaging',
      iconLetter: 'S',
      iconColor: const Color(0xFFE01E5A),
      categories: {'Apps'},
      isConnected: false,
    ),
    _IntegrationItem(
      id: 'gmail',
      name: 'Gmail',
      description: 'Email management',
      iconLetter: 'M',
      iconColor: const Color(0xFFEA4335),
      categories: {'Apps'},
      isConnected: true,
    ),
    _IntegrationItem(
      id: 'drive',
      name: 'Drive',
      description: 'File storage',
      iconLetter: 'D',
      iconColor: const Color(0xFF0F9D58),
      categories: {'Apps'},
      isConnected: true,
    ),
    _IntegrationItem(
      id: 'web_search',
      name: 'Web Search',
      description: 'Internet browsing',
      iconLetter: 'W',
      iconColor: AppColors.accentCyan,
      iconTextColor: const Color(0xFF05050F),
      categories: {'APIs', 'Custom'},
      isBuiltIn: true,
      isConnected: true,
    ),
    _IntegrationItem(
      id: 'calculator',
      name: 'Calculator',
      description: 'Math & calculations',
      iconLetter: 'C',
      iconColor: AppColors.accentViolet,
      iconTextColor: Colors.white,
      categories: {'Custom'},
      isBuiltIn: true,
      isConnected: true,
    ),
  ];

  List<_IntegrationItem> get _filteredIntegrations {
    if (_selectedFilter == 'All') {
      return _integrations;
    }
    return _integrations
        .where((item) => item.categories.contains(_selectedFilter))
        .toList();
  }

  void _toggleConnect(_IntegrationItem item) {
    setState(() {
      item.isConnected = !item.isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIntegrations;
    final connectedCount = _integrations.where((i) => i.isConnected).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, connectedCount),
              const SizedBox(height: 20),
              // ── Header (Cormorant Garamond) ─────────────────────────────────
              Text(
                'Tools',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              // ── Subtitle ────────────────────────────────────────────────────
              Text(
                'Connect and use powerful tools.',
                style: AppTypography.body(
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              // ── Filter row: All | Apps | APIs | Custom ──────────────────────
              _buildFilterRow(),
              const SizedBox(height: 20),
              // ── Integration cards ───────────────────────────────────────────
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No tools found in this category.',
                      style: AppTypography.body(
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                ...filtered.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildIntegrationCard(item),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, int connectedCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (Navigator.of(context).canPop())
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          )
        else
          const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$connectedCount CONNECTED',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Apps', 'APIs', 'Custom'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentCyan.withValues(alpha: 0.12)
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentCyan
                        : AppColors.surfaceBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.accentCyan
                        : AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIntegrationCard(_IntegrationItem item) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          // ── Icon (colored circle with letter) ──────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: item.iconColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              item.iconLetter,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: item.iconTextColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ── Name & Description ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isBuiltIn) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.accentCyan.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'built-in',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentCyan,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Status button: 'Connected' (green outline) or 'Connect' (cyan fill)
          GestureDetector(
            onTap: () => _toggleConnect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: item.isConnected
                    ? Colors.transparent
                    : AppColors.accentCyan,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.isConnected
                      ? AppColors.success
                      : AppColors.accentCyan,
                  width: 1.2,
                ),
                boxShadow: item.isConnected
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.accentCyan.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.isConnected) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    item.isConnected ? 'Connected' : 'Connect',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.isConnected
                          ? AppColors.success
                          : const Color(0xFF05050F),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
