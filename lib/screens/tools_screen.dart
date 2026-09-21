import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../services/api/jack_api_client.dart';
import '../models/tool/tool_definition.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

final toolsProvider = FutureProvider.autoDispose<List<ToolDefinition>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return await client.listTools();
});

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final toolsAsyncValue = ref.watch(toolsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.4, -0.6),
            radius: 1.2,
            colors: [Color(0xFF12082A), Color(0xFF05050F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tools',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect and use powerful tools.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white54,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterRow(),
              const SizedBox(height: 16),
              Expanded(
                child: toolsAsyncValue.when(
                  data: (tools) {
                    final filteredTools = tools.where((t) {
                      if (_filter == 'All') return true;
                      if (_filter == 'Connected') return t.availability == 'AVAILABLE';
                      if (_filter == 'Available') return t.availability != 'AVAILABLE';
                      return true;
                    }).toList();

                    if (filteredTools.isEmpty) {
                      return Center(
                        child: Text(
                          'No tools found.',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: filteredTools.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildToolCard(filteredTools[index]);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accentCyan),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error loading tools',
                      style: GoogleFonts.inter(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Connected', 'Available'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filter = filter;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white10,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.accentCyan : Colors.white54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolCard(ToolDefinition tool) {
    final isConnected = tool.availability == 'AVAILABLE';
    
    IconData iconData = Icons.extension_rounded;
    Color iconColor = AppColors.accentCyan;
    
    final lowerName = tool.name.toLowerCase();
    if (lowerName.contains('google') || lowerName.contains('gmail')) {
      iconData = Icons.email_rounded;
      iconColor = const Color(0xFF4285F4);
    } else if (lowerName.contains('github')) {
      iconData = Icons.code_rounded;
      iconColor = const Color(0xFFEBEBEB);
    } else if (lowerName.contains('notion')) {
      iconData = Icons.description_rounded;
      iconColor = const Color(0xFFEBEBEB);
    } else if (lowerName.contains('slack')) {
      iconData = Icons.chat_rounded;
      iconColor = const Color(0xFFE01E5A);
    } else if (lowerName.contains('jira')) {
      iconData = Icons.assignment_rounded;
      iconColor = const Color(0xFF2684FF);
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 24,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (tool.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tool.description,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connection setup is currently in development.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isConnected ? Colors.transparent : AppColors.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: isConnected ? Border.all(color: Colors.white10) : Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
              ),
              child: Text(
                isConnected ? 'Connected' : 'Connect',
                style: GoogleFonts.inter(
                  color: isConnected ? Colors.white54 : AppColors.accentCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
