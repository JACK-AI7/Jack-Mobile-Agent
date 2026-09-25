// lib/screens/call_log_screen.dart
//
// High-End Autonomous AI Call Center & Call Screening Screen for JACK.
// Features:
// 1. Live status HUD with active Telephony Engine badge.
// 2. Direct interactive test triggers: Simulate incoming calls from recruiters, clients, or deliveries.
// 3. Direct outbound dialer driven by Jack's native voice & phone automation.
// 4. Live Call Log list backed by CallLogNotifier & SharedPreferences.
// 5. Turn-by-turn AI transcript inspector with British Male voice summaries & action items.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/call_log_model.dart';
import '../providers/call_log_provider.dart';
import '../services/jack_master_dispatcher.dart';
import '../services/telephony/jack_call_screener_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class CallLogScreen extends ConsumerStatefulWidget {
  const CallLogScreen({super.key});

  @override
  ConsumerState<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends ConsumerState<CallLogScreen> {
  int _selectedFilter = 0; // 0: All, 1: Screened, 2: Incoming, 3: Outgoing
  final List<String> _filters = ['All', 'Screened', 'Incoming', 'Outgoing'];

  @override
  void initState() {
    super.initState();
    _seedDefaultCallsIfEmpty();
  }

  Future<void> _seedDefaultCallsIfEmpty() async {
    final logs = ref.read(callLogProvider);
    if (logs.isEmpty) {
      final notifier = ref.read(callLogProvider.notifier);
      await notifier.addEntry(
        CallLogEntry(
          id: 'seed_1',
          contactName: 'Sarah Jenkins',
          phoneNumber: '+1 (415) 892-0199',
          type: CallLogType.incoming,
          startTime: DateTime.now().subtract(const Duration(minutes: 42)),
          duration: const Duration(seconds: 48),
          aiSummary:
              'Caller: "Hi Jaswanth, checking if you reviewed the updated architecture proposal."\nJack: "Hello Sarah. Jaswanth is currently occupied in deep work. I have logged your message and he will review the document shortly."',
          jackActions: [
            'Screened call autonomously via British Male AI voice',
            'Captured message regarding architecture proposal',
            'Logged priority task to Tasks screen',
          ],
        ),
      );
      await notifier.addEntry(
        CallLogEntry(
          id: 'seed_2',
          contactName: 'Amazon Delivery',
          phoneNumber: '+1 (800) 280-4331',
          type: CallLogType.incoming,
          startTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
          duration: const Duration(seconds: 32),
          aiSummary:
              'Caller: "Package delivery at front gate. Need access code."\nJack: "Thank you. Please place the package inside the secure parcel box next to the gate. Have a pleasant day."',
          jackActions: [
            'Provided automated gate delivery instructions',
            'Notified user of package arrival',
          ],
        ),
      );
      await notifier.addEntry(
        CallLogEntry(
          id: 'seed_3',
          contactName: 'Google Recruiting',
          phoneNumber: '+1 (650) 253-0000',
          type: CallLogType.outgoing,
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          duration: const Duration(minutes: 2, seconds: 14),
          aiSummary:
              'Dialed via Jack Telephony for interview loop sync. Scheduled technical follow-up session.',
          jackActions: [
            'Outbound dial executed via native phone system',
            'Calendar slot reserved',
          ],
        ),
      );
    }
  }

  void _showTestCallDialog() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF100E22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final nameCtrl = TextEditingController(text: 'Sarah Jenkins');
        final numCtrl = TextEditingController(text: '+1 (415) 892-0199');

        final presets = [
          {'name': 'Sarah Jenkins', 'role': 'Project Lead', 'num': '+1 (415) 892-0199'},
          {'name': 'Google Recruiter', 'role': 'Hiring Team', 'num': '+1 (650) 253-0000'},
          {'name': 'Amazon Courier', 'role': 'Package Delivery', 'num': '+1 (800) 280-4331'},
          {'name': 'Alex Carter', 'role': 'Design Partner', 'num': '+1 (212) 555-0182'},
        ];

        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            16,
            22,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_callback_rounded,
                        color: AppColors.accentCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulate Screened Call',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Jack will answer and talk directly with the caller',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'QUICK SCENARIO PRESETS:',
                style: GoogleFonts.inter(
                  color: AppColors.accentCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((p) {
                  return ActionChip(
                    backgroundColor: const Color(0xFF17152B),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    label: Text(
                      '${p['name']} (${p['role']})',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () {
                      nameCtrl.text = p['name']!;
                      numCtrl.text = p['num']!;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Caller Name',
                  labelStyle: GoogleFonts.inter(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: GoogleFonts.inter(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.ring_volume_rounded, size: 20),
                  label: Text(
                    'Trigger Incoming Call',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    JackCallScreenerService.triggerGlobally(
                      callerName: nameCtrl.text.trim().isEmpty ? 'Sarah Jenkins' : nameCtrl.text.trim(),
                      phoneNumber: numCtrl.text.trim().isEmpty ? '+1 (415) 892-0199' : numCtrl.text.trim(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOutboundDialerDialog() {
    HapticFeedback.mediumImpact();
    final targetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121026),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_forwarded_rounded, color: Color(0xFF22C55E), size: 22),
            const SizedBox(width: 10),
            Text(
              'Dial with Jack',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter contact name or phone number:',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              autofocus: true,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Mom, Sarah, +1 415 892 0199',
                hintStyle: GoogleFonts.inter(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final target = targetCtrl.text.trim();
              Navigator.of(ctx).pop();
              if (target.isNotEmpty) {
                final res = await JackMasterDispatcher.executeCommand({
                  'intent': 'make_call',
                  'params': {'target': target},
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message']?.toString() ?? 'Call dispatched'),
                      backgroundColor: AppColors.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('Call Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCallDetails(CallLogEntry entry) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0E20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.record_voice_over_rounded,
                      color: AppColors.accentCyan, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entry.phoneNumber} • ${entry.durationDisplay.isNotEmpty ? entry.durationDisplay : "Active"}',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Screened',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF22C55E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'CALL TRANSCRIPT & DIALOGUE:',
              style: GoogleFonts.inter(
                color: AppColors.accentCyan,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF16142A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                entry.aiSummary ?? 'No conversation notes recorded.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
            if (entry.jackActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'ACTIONS TAKEN BY JACK:',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA855F7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              ...entry.jackActions.map(
                (act) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF22C55E), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          act,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.phone_forwarded_rounded, size: 16),
                    label: Text('Call Back', style: GoogleFonts.inter(fontSize: 13)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      JackMasterDispatcher.executeCommand({
                        'intent': 'make_call',
                        'params': {'target': entry.phoneNumber},
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Close', style: GoogleFonts.inter(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = ref.watch(callLogProvider);

    final filteredLogs = allLogs.where((log) {
      if (_selectedFilter == 1) return log.type == CallLogType.incoming && (log.aiSummary?.contains('Jack') ?? false);
      if (_selectedFilter == 2) return log.type == CallLogType.incoming;
      if (_selectedFilter == 3) return log.type == CallLogType.outgoing;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
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
          'AI CALL CENTER',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Colors.white70,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Simulate Screened Call',
            icon: const Icon(Icons.ring_volume_rounded, color: AppColors.accentCyan, size: 22),
            onPressed: _showTestCallDialog,
          ),
          IconButton(
            tooltip: 'Clear Log',
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white38, size: 22),
            onPressed: () => ref.read(callLogProvider.notifier).clearAll(),
          ),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/tools');
          if (index == 2) context.go('/agent-builder');
          if (index == 3) context.go('/tasks');
          if (index == 4) context.go('/profile');
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          children: [
            // Status HUD Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF16132D),
                    const Color(0xFF100E22).withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.1),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF22C55E),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'JACK TELEPHONY ACTIVE',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF22C55E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Male Baritone Voice',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Autonomous Call Agent',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jack intercepts unknown and incoming calls, speaks in real-time, extracts caller intent, and logs action items.',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.ring_volume_rounded, size: 17),
                          label: Text(
                            'Simulate Call',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _showTestCallDialog,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.phone_forwarded_rounded, size: 17),
                          label: Text(
                            'Dial Number',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _showOutboundDialerDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Metrics row
            Row(
              children: [
                _buildMetricCard(
                  title: 'Screened Calls',
                  value: '${allLogs.where((l) => l.type == CallLogType.incoming).length}',
                  icon: Icons.shield_rounded,
                  color: AppColors.accentCyan,
                ),
                const SizedBox(width: 10),
                _buildMetricCard(
                  title: 'Transcribed',
                  value: '${allLogs.where((l) => l.aiSummary != null).length}',
                  icon: Icons.notes_rounded,
                  color: const Color(0xFFA855F7),
                ),
                const SizedBox(width: 10),
                _buildMetricCard(
                  title: 'Minutes Saved',
                  value: '14.2m',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Segmented Filters
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, i) {
                  final active = _selectedFilter == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: active,
                      label: Text(_filters[i]),
                      labelStyle: GoogleFonts.inter(
                        color: active ? Colors.black : Colors.white70,
                        fontSize: 12.5,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                      selectedColor: AppColors.accentCyan,
                      backgroundColor: const Color(0xFF141224),
                      side: BorderSide(
                        color: active ? AppColors.accentCyan : Colors.white.withValues(alpha: 0.1),
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = i),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Call List
            if (filteredLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No calls in this category.',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 13.5),
                  ),
                ),
              )
            else
              ...filteredLogs.map((entry) {
                final isScreened = entry.aiSummary?.contains('Jack') ?? false;
                final isIncoming = entry.type == CallLogType.incoming;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF110F20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isScreened
                          ? AppColors.accentCyan.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onTap: () => _showCallDetails(entry),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isScreened
                            ? AppColors.accentCyan.withValues(alpha: 0.15)
                            : (isIncoming
                                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                : const Color(0xFFA855F7).withValues(alpha: 0.15)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isScreened
                            ? Icons.smart_toy_rounded
                            : (isIncoming
                                ? Icons.phone_callback_rounded
                                : Icons.phone_forwarded_rounded),
                        color: isScreened
                            ? AppColors.accentCyan
                            : (isIncoming ? const Color(0xFF22C55E) : const Color(0xFFA855F7)),
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.displayName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isScreened)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Screened',
                              style: GoogleFonts.inter(
                                color: AppColors.accentCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${entry.phoneNumber} • ${entry.durationDisplay.isNotEmpty ? entry.durationDisplay : "Active"}',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                        ),
                        if (entry.aiSummary != null && entry.aiSummary!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            entry.aiSummary!.replaceAll('\n', ' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
                  ),
                );
              }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF100E20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
