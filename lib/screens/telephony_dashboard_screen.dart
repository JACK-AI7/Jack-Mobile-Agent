// lib/screens/telephony_dashboard_screen.dart
//
// Multi-Tenant AI Telephony Dashboard & Real-Time Voice Terminal for JACK.
// Features:
// 1. Mobile Auth & Personal SIM Caller ID Auto-Linking status badge ($0.00).
// 2. Carrier Conditional Call Forwarding (CCF) 1-tap activation to Jack PBX.
// 3. Simulated & Live Real Call Lifting Test Action.
// 4. Command-based Outbound AI Dialing Execution Block.
// 5. Live cyber-terminal tracking real-time WebSocket transcriptions + live directives.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/telephony/jack_multi_tenant_telephony_service.dart';
import '../services/api/jack_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_nav_bar.dart';

class TelephonyDashboardScreen extends ConsumerStatefulWidget {
  const TelephonyDashboardScreen({super.key});

  @override
  ConsumerState<TelephonyDashboardScreen> createState() =>
      _TelephonyDashboardScreenState();
}

class _TelephonyDashboardScreenState
    extends ConsumerState<TelephonyDashboardScreen> {
  final TextEditingController _targetNumberCtrl = TextEditingController();
  final TextEditingController _taskPromptCtrl = TextEditingController(
    text: 'Call my contractor and verify if the delivery scheduled for 4 PM is on track.',
  );
  final TextEditingController _directiveCtrl = TextEditingController();
  final ScrollController _terminalScrollCtrl = ScrollController();

  final JackMultiTenantTelephonyService _service =
      JackMultiTenantTelephonyService.instance;

  bool _isSyncing = false;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _initTelephonyProfile();
    _service.liveTranscriptNotifier.addListener(_autoScrollTerminal);
  }

  @override
  void dispose() {
    _service.liveTranscriptNotifier.removeListener(_autoScrollTerminal);
    _targetNumberCtrl.dispose();
    _taskPromptCtrl.dispose();
    _directiveCtrl.dispose();
    _terminalScrollCtrl.dispose();
    super.dispose();
  }

  void _autoScrollTerminal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollCtrl.hasClients) {
        _terminalScrollCtrl.animateTo(
          _terminalScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initTelephonyProfile() async {
    setState(() => _isSyncing = true);
    try {
      final userName = await JackStorage.read(key: 'jack_user_name') ?? 'Jaswanth';
      final token = await JackStorage.read(key: 'jack_auth_token') ?? 'sim_token_default';
      final savedSim = await JackStorage.read(key: 'jack_personal_sim') ?? '+1 (415) 892-0199';

      await _service.init();
      await _service.syncProfile(
        userId: userName.toLowerCase().replaceAll(' ', '_'),
        authToken: token,
        personalSimNumber: savedSim,
        agentSystemPrompt:
            'You are Jack, a professional AI executive assistant. Answering calls for $userName. Keep answers concise, natural, and helpful.',
      );
    } catch (_) {}
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
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
              context.go('/calls');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'AI TELEPHONY HUB',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Colors.white70,
          ),
        ),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                ),
              ),
            ),
          ValueListenableBuilder<bool>(
            valueListenable: _service.wsConnectedNotifier,
            builder: (ctx, isConnected, _) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected
                       ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                       : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF22C55E) : Colors.orange,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? const Color(0xFF22C55E) : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'WS LIVE' : 'STANDBY',
                      style: GoogleFonts.inter(
                        color: isConnected ? const Color(0xFF22C55E) : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: GlassNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/calls');
          if (index == 2) context.go('/agent-builder');
          if (index == 3) context.go('/tasks');
          if (index == 4) context.go('/profile');
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          children: [
            // ── 1. User SIM Status Card ───────────────────────────────────────
            _buildProfileStatusCard(),

            const SizedBox(height: 16),

            // ── 2. Carrier Call Forwarding (CCF) Setup Card ───────────────────
            _buildCarrierCallForwardingCard(),

            const SizedBox(height: 16),

            // ── 3. Command-based Outbound AI Dialing Execution Block ──────────
            _buildOutboundExecutionCard(),

            const SizedBox(height: 16),

            // ── 4. Live Real-Time Cyber-Terminal Display ──────────────────────
            _buildLiveTranscriptTerminal(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Profile Status Card ─────────────────────────────────────────────────────
  Widget _buildProfileStatusCard() {
    return ValueListenableBuilder<TelephonyUserConfig?>(
      valueListenable: _service.profileNotifier,
      builder: (ctx, config, _) {
        final sim = config?.personalSimNumber ?? 'Active Device SIM';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF141228), Color(0xFF0F0E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sim_card_rounded, color: Color(0xFF22C55E), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'DEVICE SIM AI CALLER',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r'100% FREE • $0.00',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF22C55E),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sim,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Uses your phone\'s physical SIM and open-source PBX. Zero subscription fees, zero Twilio, and zero external costs.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Carrier Call Forwarding (CCF) Setup Card ────────────────────────────────
  Widget _buildCarrierCallForwardingCard() {
    return ValueListenableBuilder<TelephonyUserConfig?>(
      valueListenable: _service.profileNotifier,
      builder: (ctx, config, _) {
        final targetNum = config?.targetForwardingNumber ?? '+1 (800) 555-0199';
        final ccfAllCode = config?.ccfAllCode ?? '*004*$targetNum#';
        final ccfDeactCode = config?.ccfDeactivateCode ?? '##004#';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10101C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_forwarded_rounded, color: Colors.purpleAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'CARRIER CALL FORWARDING (CCF)',
                        style: GoogleFonts.inter(
                          color: Colors.purpleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'STANDARD GSM',
                      style: GoogleFonts.inter(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'When you decline or miss a call, your phone carrier automatically forwards the call for FREE to Jack\'s Open-Source PBX to answer and talk to the caller.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Forwarding Target: $targetNum',
                      style: GoogleFonts.firaCode(color: Colors.white70, fontSize: 11),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: ccfAllCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied USSD Code: $ccfAllCode')),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                        foregroundColor: Colors.purpleAccent,
                        side: const BorderSide(color: Colors.purpleAccent, width: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text('Activate ($ccfAllCode)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _service.launchUssdDialer(ccfAllCode),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24, width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onPressed: () => _service.launchUssdDialer(ccfDeactCode),
                    child: Text('Cancel (##004#)', style: GoogleFonts.inter(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Outbound Execution Block ────────────────────────────────────────────────
  Widget _buildOutboundExecutionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111024),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: AppColors.accentCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'DISPATCH OUTBOUND CALL',
                style: GoogleFonts.inter(
                  color: AppColors.accentCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetNumberCtrl,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Recipient Phone Number',
              labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              hintText: '+1 (415) 892-0199',
              hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _taskPromptCtrl,
            maxLines: 2,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'AI Outbound Mission / Task',
              labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                'Free Call via Phone SIM (\$0.00)',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final target = _targetNumberCtrl.text.trim();
                final task = _taskPromptCtrl.text.trim();
                if (target.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter recipient phone number')),
                  );
                  return;
                }
                HapticFeedback.heavyImpact();
                _service.appendTranscript('System', 'Dialing $target via native SIM. Mission: "$task"');

                final cleanNumber = target.replaceAll(RegExp(r'[^\d+]'), '');
                final uri = Uri.parse('tel:$cleanNumber');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Live Cyber-Terminal ─────────────────────────────────────────────────────
  Widget _buildLiveTranscriptTerminal() {
    return Container(
      height: 440,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF090812),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE AI CALL STREAM TERMINAL',
                    style: GoogleFonts.firaCode(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Test Real Call Lift Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSimulating
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF22C55E)))
                        : const Icon(Icons.play_arrow_rounded, color: Color(0xFF22C55E), size: 16),
                    label: Text(
                      'Test Call Lift',
                      style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSimulating ? null : () async {
                      setState(() => _isSimulating = true);
                      await _service.simulateFreeCallLift();
                      if (mounted) setState(() => _isSimulating = false);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all_rounded, color: Colors.white38, size: 18),
                    onPressed: _service.clearTerminal,
                    tooltip: 'Clear Output',
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end_rounded, color: Color(0xFFF43F5E), size: 18),
                    onPressed: () => _service.hangUpActiveCall(null),
                    tooltip: 'Hang Up Call',
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white10),

          // Live Transcript Output Area
          Expanded(
            child: ValueListenableBuilder<List<TranscriptEntry>>(
              valueListenable: _service.liveTranscriptNotifier,
              builder: (ctx, entries, _) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      '> Standby. Ready for incoming or outgoing calls.\n> Tap [Test Call Lift] to test AI answering and real-time conversation.',
                      style: GoogleFonts.firaCode(color: Colors.white24, fontSize: 11, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _terminalScrollCtrl,
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final e = entries[i];
                    final isJack = e.speaker == 'Jack';
                    final isSystem = e.speaker == 'System';
                    final isDirective = e.speaker.contains('Directive');

                    final color = isJack
                        ? AppColors.accentCyan
                        : isDirective
                            ? Colors.purpleAccent
                            : isSystem
                                ? Colors.white54
                                : const Color(0xFF22C55E);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '[${e.speaker.toUpperCase()}] ',
                              style: GoogleFonts.firaCode(
                                color: color,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: e.message,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Directive Input Field during Live Call
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over_rounded, color: Colors.purpleAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _directiveCtrl,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Whisper directive for Jack to speak (e.g. Tell them 5 PM)...',
                      hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _service.sendLiveDirective(val.trim());
                        _directiveCtrl.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.accentCyan, size: 16),
                  onPressed: () {
                    final val = _directiveCtrl.text.trim();
                    if (val.isNotEmpty) {
                      _service.sendLiveDirective(val);
                      _directiveCtrl.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
