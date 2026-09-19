import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          children: [
            _buildHeader(),
            Expanded(
              child: autosAsync.when(
                data: (autos) {
                  if (autos.isEmpty) {
                    return const Center(child: Text('No automations found.', style: TextStyle(color: Colors.white54)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: autos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final a = autos[index];
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(a.schedule, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                            Switch(
                              value: a.isActive,
                              onChanged: (val) {
                                // Real patch call to toggle
                                ref.read(apiClientProvider).toggleAutomation(a.id, val).then((_) {
                                  ref.invalidate(automationsProvider);
                                });
                              },
                              activeColor: AppColors.accentCyan,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                ref.read(apiClientProvider).deleteAutomation(a.id).then((_) {
                                  ref.invalidate(automationsProvider);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
                error: (e, st) => Center(child: Text('Error: ', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) {
              final nameCtrl = TextEditingController();
              final cronCtrl = TextEditingController(text: '* * * * *');
              return AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Create Automation', style: TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white54)),
                    ),
                    TextField(
                      controller: cronCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Cron Schedule', labelStyle: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && cronCtrl.text.isNotEmpty) {
                        ref.read(apiClientProvider).createAutomation(nameCtrl.text, cronCtrl.text).then((_) {
                          ref.invalidate(automationsProvider);
                          Navigator.pop(ctx);
                        });
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            }
          );
        },
        backgroundColor: AppColors.accentCyan,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Automations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.invalidate(automationsProvider),
          ),
        ],
      ),
    );
  }
}
