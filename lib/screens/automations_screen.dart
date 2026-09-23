// lib/screens/automations_screen.dart
//
// 05. Automations — Pixel-to-pixel reproduction of reference image:
// Header, filter pills (All, Personal, Work, Custom), 5 canonical interactive
// automation cards with clickable details modal, schedule customizer, and
// immediate execution capability backed by live JackAutomationEngine.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/automations/jack_automation_engine.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class AutomationsScreen extends ConsumerStatefulWidget {
  const AutomationsScreen({super.key});

  @override
  ConsumerState<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends ConsumerState<AutomationsScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Personal', 'Work', 'Custom'];

  void _showAutomationDetails(AutomationRoutine routine) {
    HapticFeedback.mediumImpact();
    final id = routine.id;
    final title = routine.title;
    final color = routine.color;
    final icon = routine.icon;
    final isEnabled = routine.isEnabled;
    final actions = routine.actions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          routine.description,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: CupertinoSwitch(
                      value: isEnabled,
                      activeTrackColor: const Color(0xFF2563EB),
                      inactiveTrackColor: const Color(0xFF2B2A3A),
                      thumbColor: Colors.white,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        ref
                            .read(jackAutomationProvider.notifier)
                            .toggleAutomation(id, val);
                        setSheetState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Schedule',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 13)),
                        Text(routine.schedule.isEmpty
                            ? 'Trigger on demand'
                            : routine.schedule,
                            style: GoogleFonts.inter(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Last Executed',
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 13)),
                        Text(routine.lastRunLabel,
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                    if (routine.lastResult != null) ...[
                      const Divider(color: Colors.white10, height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          routine.lastResult!,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Execution Steps',
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...actions.map((act) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(act,
                              style: GoogleFonts.inter(
                                  color: Colors.white60, fontSize: 12.5)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        ref
                            .read(jackAutomationProvider.notifier)
                            .executeRoutine(id, context);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      label: Text(
                        'Run Now',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: color.withValues(alpha: 0.8)),
                        ),
                        elevation: 0,
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

  void _showNewAutomationDialog() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom routine creator open. Ask Jack to automate anything!'),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(jackAutomationProvider);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            onPressed: _showNewAutomationDialog,
          ),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: 2,
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
              // Current tab
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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // ── Section Title & Subtitle ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Text(
                'Automations',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Text(
                'Set it once. Jack handles the rest.',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Segmented Filter Pills ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final active = _selectedFilter == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedFilter = i);
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF38BDF8) // Electric cyan/blue
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _filters[i],
                              style: GoogleFonts.inter(
                                color: active ? Colors.black : Colors.white70,
                                fontSize: 12.5,
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
            ),

            const SizedBox(height: 16),

            // ── Automation Cards List ─────────────────────────────────────
            Expanded(
              child: _buildCardsList(routines),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(List<AutomationRoutine> routines) {
    final activeFilterName = _filters[_selectedFilter];

    // Filter items based on selected pill
    final items = routines.where((item) {
      if (activeFilterName == 'All') return true;
      return item.category == activeFilterName;
    }).toList();

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No ${activeFilterName.toLowerCase()} automations configured',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final routine = items[index];
        final id = routine.id;
        final title = routine.title;
        final description = routine.description;
        final schedule = routine.schedule;
        final icon = routine.icon;
        final color = routine.color;
        final isEnabled = routine.isEnabled;

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => _showAutomationDetails(routine),
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141320).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Tinted Rounded Icon Box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),

                      // Title & Multi-Line Subtitles
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (schedule.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                schedule,
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Custom Switch Matching Reference Image
                      Transform.scale(
                        scale: 0.85,
                        child: CupertinoSwitch(
                          value: isEnabled,
                          activeTrackColor: const Color(0xFF2563EB), // Reference Blue
                          inactiveTrackColor: const Color(0xFF2B2A3A),
                          thumbColor: Colors.white,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            ref
                                .read(jackAutomationProvider.notifier)
                                .toggleAutomation(id, val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$title ${val ? "enabled" : "disabled"}'),
                                backgroundColor: AppColors.surfaceElevated,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
