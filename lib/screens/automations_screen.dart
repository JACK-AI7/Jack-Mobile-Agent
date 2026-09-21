import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/automations_provider.dart';
import '../services/api/jack_api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class AutomationsScreen extends ConsumerWidget {
  const AutomationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autosAsync = ref.watch(automationsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(ref),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accentCyan,
                backgroundColor: AppColors.surfaceElevated,
                onRefresh: () async => ref.invalidate(automationsProvider),
                child: autosAsync.when(
                  data: (autos) {
                    if (autos.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Text('No automations yet. Create one to schedule tasks.', 
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: autos.length,
                      separatorBuilder: (context, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final a = autos[index];
                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.accentViolet.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accentViolet.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.auto_awesome, color: AppColors.accentViolet),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(a.schedule, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: a.isActive,
                                onChanged: (val) async {
                                  try {
                                    await ref.read(apiClientProvider).toggleAutomation(a.id, val);
                                    ref.invalidate(automationsProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to toggle automation')));
                                    }
                                  }
                                },
                                activeTrackColor: AppColors.accentCyan.withValues(alpha: 0.5),
                                activeThumbColor: AppColors.accentCyan,
                                inactiveTrackColor: Colors.white10,
                                inactiveThumbColor: Colors.white38,
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.7)),
                                onPressed: () async {
                                  try {
                                    await ref.read(apiClientProvider).deleteAutomation(a.id);
                                    ref.invalidate(automationsProvider);
                                  } catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
                                  }
                                },
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
                  error: (e, st) => Center(child: Text('Error loading automations', style: GoogleFonts.inter(color: AppColors.error))),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppColors.accentViolet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
            'Schedule and automate tasks',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final cronCtrl = TextEditingController(text: '* * * * *');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Automation', style: GoogleFonts.cormorantGaramond(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Automation Name',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cronCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cron Schedule (e.g., 0 9 * * *)',
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty && cronCtrl.text.isNotEmpty) {
                      try {
                        await ref.read(apiClientProvider).createAutomation(nameCtrl.text, cronCtrl.text);
                        ref.invalidate(automationsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to create')));
                      }
                    }
                  },
                  child: Text('Create Automation', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
