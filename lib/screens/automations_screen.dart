// lib/screens/automations_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  int _filterIndex = 0;
  static const _filters = ['All', 'Personal', 'Work', 'Custom'];

  final List<_Automation> _automations = [
    _Automation(
      title: 'Daily AI Brief',
      description: 'News, emails, calendar summary',
      schedule: 'Every morning · 8:00 AM',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.warning,
      enabled: true,
      category: 'Personal',
    ),
    _Automation(
      title: 'Monitor project',
      description: 'Track GitHub & send updates',
      schedule: 'Every 6 hours',
      icon: Icons.code_rounded,
      color: AppColors.accentViolet,
      enabled: true,
      category: 'Work',
    ),
    _Automation(
      title: 'Check price drops',
      description: 'Monitor products & alert me',
      schedule: 'Daily · 10:00 AM',
      icon: Icons.shopping_cart_rounded,
      color: AppColors.accentPink,
      enabled: false,
      category: 'Personal',
    ),
    _Automation(
      title: 'Social media helper',
      description: 'Draft & schedule posts',
      schedule: 'Weekdays · 6:00 PM',
      icon: Icons.share_rounded,
      color: AppColors.accentBlue,
      enabled: true,
      category: 'Work',
    ),
    _Automation(
      title: 'Research competitor',
      description: 'Weekly market research',
      schedule: 'Weekly · Mon 9:00 AM',
      icon: Icons.analytics_rounded,
      color: AppColors.accentTeal,
      enabled: false,
      category: 'Custom',
    ),
  ];

  List<_Automation> get _filtered {
    if (_filterIndex == 0) return _automations;
    final cat = _filters[_filterIndex];
    return _automations.where((a) => a.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.accentCyan,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: Text('Create automation', style: AppTypography.button(size: 14, color: Colors.black)),
      ),
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
            Text('Automations', style: AppTypography.sectionHeading(size: 22)),
            Text('Set it once. Jack handles the rest.', style: AppTypography.caption()),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: _filters.asMap().entries.map((e) {
                  final isSelected = _filterIndex == e.key;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _filterIndex = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Text(e.value,
                              style: AppTypography.caption(
                                  size: 12,
                                  color: isSelected ? AppColors.accentCyan : AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final auto = _filtered[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: auto.color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(auto.icon, color: auto.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(auto.title, style: AppTypography.bodyMedium(size: 14)),
                              const SizedBox(height: 2),
                              Text(auto.description,
                                  style: AppTypography.caption(size: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 10, color: AppColors.textTertiary),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(auto.schedule,
                                        style: AppTypography.caption(size: 10, color: AppColors.textTertiary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: auto.enabled,
                          onChanged: (v) => setState(() => auto.enabled = v),
                          activeColor: AppColors.accentCyan,
                          inactiveTrackColor: AppColors.surfaceBorder,
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
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.surfaceBorder),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Automation', style: AppTypography.sectionHeading(size: 22)),
                const SizedBox(height: 16),
                Text('Describe what you want Jack to automate:',
                    style: AppTypography.body(size: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                TextField(
                  style: AppTypography.body(size: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., Send me a morning brief every day at 8 AM',
                    hintStyle: AppTypography.body(size: 14, color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [AppColors.accentCyan, AppColors.accentViolet],
                      ),
                    ),
                    child: Center(
                      child: Text('Create with Jack',
                          style: AppTypography.button(size: 15, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Automation {
  final String title;
  final String description;
  final String schedule;
  final IconData icon;
  final Color color;
  bool enabled;
  final String category;

  _Automation({
    required this.title,
    required this.description,
    required this.schedule,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.category,
  });
}
