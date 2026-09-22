// lib/screens/automations_screen.dart
//
// 05. Automations — Real backend automations only. Zero fake data.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/jack_components.dart';
import '../providers/automations_provider.dart';
import '../services/api/jack_api_client.dart';
import '../theme/app_colors.dart';

class AutomationsScreen extends ConsumerStatefulWidget {
  const AutomationsScreen({super.key});

  @override
  ConsumerState<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends ConsumerState<AutomationsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Personal', 'Work', 'Custom'];

  // Track local toggle state overrides (optimistic UI while API call is in flight)
  final Map<String, bool> _optimisticToggles = {};

  /// Map backend automation to the icon + color best representing it
  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('brief') || n.contains('morning') || n.contains('daily')) {
      return Icons.wb_sunny_rounded;
    }
    if (n.contains('monitor') || n.contains('project') || n.contains('track')) {
      return Icons.trending_up_rounded;
    }
    if (n.contains('price') || n.contains('deal') || n.contains('shop')) {
      return Icons.sell_rounded;
    }
    if (n.contains('social') || n.contains('post') || n.contains('tweet')) {
      return Icons.groups_rounded;
    }
    if (n.contains('research') || n.contains('competitor') || n.contains('market')) {
      return Icons.search_rounded;
    }
    if (n.contains('email') || n.contains('mail') || n.contains('inbox')) {
      return Icons.mail_rounded;
    }
    if (n.contains('calendar') || n.contains('schedule') || n.contains('reminder')) {
      return Icons.calendar_today_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  Color _colorFor(String id) {
    final colors = [
      const Color(0xFFFFCC00),
      const Color(0xFF00E5FF),
      const Color(0xFFFF3377),
      const Color(0xFF8B5CF6),
      const Color(0xFF14B8A6),
      const Color(0xFF00FF88),
      const Color(0xFF3B82F6),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final asyncAutomations = ref.watch(automationsProvider);

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
        actions: [
          // Add automation button
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            onPressed: () => _showAddAutomationDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automations',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set it once. Jack handles the rest.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Segmented Filters: [All] [Personal] [Work] [Custom]
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
                        margin: const EdgeInsets.symmetric(horizontal: 3),
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
                              fontSize: 12,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
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

            // ── Real Data Only
            Expanded(
              child: asyncAutomations.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading automations...',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                error: (err, _) => _buildErrorState(
                  err.toString().replaceAll('Exception: ', ''),
                ),
                data: (automations) {
                  if (automations.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final filtered = automations.where((_) {
                    // Filter tabs are UI-only grouping; backend has no category field.
                    // All/Personal/Work/Custom tabs cycle through the list.
                    return true;
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final auto = filtered[index];
                      final enabled = _optimisticToggles[auto.id] ?? auto.isActive;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: JackAutomationCard(
                          icon: _iconFor(auto.name),
                          iconColor: _colorFor(auto.id),
                          title: auto.name,
                          subtitle: auto.schedule,
                          enabled: enabled,
                          onToggle: (val) async {
                            HapticFeedback.lightImpact();
                            // Optimistic update
                            setState(() => _optimisticToggles[auto.id] = val);
                            try {
                              await ref
                                  .read(apiClientProvider)
                                  .toggleAutomation(auto.id, val);
                              // Invalidate to refetch
                              ref.invalidate(automationsProvider);
                            } catch (_) {
                              // Revert on failure
                              if (mounted) {
                                setState(() =>
                                    _optimisticToggles[auto.id] = !val);
                              }
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    val
                                        ? '${auto.name} activated'
                                        : '${auto.name} paused',
                                  ),
                                  backgroundColor: AppColors.surfaceElevated,
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load automations',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.contains('Authentication')
                  ? 'Please log in again to access your automations.'
                  : 'Backend is unreachable. Check your connection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => ref.invalidate(automationsProvider),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.accentCyan.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(color: AppColors.accentCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_outlined,
                color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'No automations yet',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first automation and let Jack handle\nrepetitive tasks automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddAutomationDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Create Automation',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAutomationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final scheduleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Automation',
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style:
                  GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Automation name (e.g. Daily AI Brief)',
                hintStyle:
                    GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E1C35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scheduleController,
              style:
                  GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Schedule (e.g. Every morning • 8:00 AM)',
                hintStyle:
                    GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E1C35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final schedule = scheduleController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(apiClientProvider)
                        .createAutomation(name, schedule);
                    ref.invalidate(automationsProvider);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to create automation'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Create',
                  style:
                      GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
