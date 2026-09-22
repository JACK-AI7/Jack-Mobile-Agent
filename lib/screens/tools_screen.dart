// lib/screens/tools_screen.dart
//
// 07. Tools — Connect your favorite tools
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Connected', 'Available'];

  late List<Map<String, dynamic>> _tools;

  @override
  void initState() {
    super.initState();
    _tools = [
      {
        'id': 'google',
        'name': 'Google',
        'icon': Icons.g_mobiledata_rounded,
        'iconColor': const Color(0xFF4285F4),
        'connected': true,
      },
      {
        'id': 'github',
        'name': 'GitHub',
        'icon': Icons.code_rounded,
        'iconColor': Colors.white,
        'connected': true,
      },
      {
        'id': 'notion',
        'name': 'Notion',
        'icon': Icons.description_rounded,
        'iconColor': const Color(0xFFFFAA00),
        'connected': false,
      },
      {
        'id': 'slack',
        'name': 'Slack',
        'icon': Icons.tag_rounded,
        'iconColor': const Color(0xFFE01E5A),
        'connected': false,
      },
      {
        'id': 'gmail',
        'name': 'Gmail',
        'icon': Icons.mail_rounded,
        'iconColor': const Color(0xFFEA4335),
        'connected': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tools.where((tool) {
      if (_selectedFilter == 1) return tool['connected'] == true;
      if (_selectedFilter == 2) return tool['connected'] == false;
      return true;
    }).toList();

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
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tools',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect and use powerful tools.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Segmented Filters: [All] [Connected] [Available]
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
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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

            // Tools list matching Screen 07
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final tool = filtered[index];
                  final isConnected = tool['connected'] as bool;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => tool['connected'] = !isConnected);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !isConnected
                                  ? '${tool['name']} connected successfully'
                                  : '${tool['name']} disconnected',
                            ),
                            backgroundColor: AppColors.surfaceElevated,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Leading icon container
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141320),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                tool['icon'] as IconData,
                                color: tool['iconColor'] as Color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Tool Name & Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tool['name'] as String,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isConnected ? 'Connected' : 'Connect',
                                    style: GoogleFonts.inter(
                                      color: isConnected
                                          ? Colors.white54
                                          : AppColors.accentCyan,
                                      fontSize: 12,
                                      fontWeight: isConnected
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Trailing Chevron
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white30,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
