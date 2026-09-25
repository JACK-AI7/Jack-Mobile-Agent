// lib/screens/telephony_dashboard_screen.dart
//
// Multi-Tenant AI Telephony Dashboard & Real-Time Voice Terminal for JACK.
// Features:
// 1. Mobile Auth & Personal SIM Caller ID Auto-Linking status badge.
// 2. Conditional Call Forwarding (CCF) activation card with 1-tap USSD launcher.
// 3. Command-based Outbound AI Dialing Execution Block.
// 4. Live cyber-terminal tracking real-time WebSocket transcriptions.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

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
  final ScrollController _terminalScrollCtrl = ScrollController();

  final JackMultiTenantTelephonyService _service =
      JackMultiTenantTelephonyService.instance;

  bool _isSyncing = false;

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
                      isConnected ? 'WS LIVE' : 'RECONNECTING',
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
            // ── 1. User Authentication & Personal SIM Caller ID Card ───────────
            _buildProfileStatusCard(),

            const SizedBox(height: 16),

            // ── 2. Conditional Call Forwarding (CCF) Activation Terminal ────────
            _buildCcfForwardingTerminal(),

            const SizedBox(height: 16),

            // ── 3. Command-based Outbound AI Dialing Execution Block ─────────────
            _buildOutboundExecutionCard(),

            const SizedBox(height: 16),

            // ── 4. Live Real-Time Cyber-Terminal Display ─────────────────────────
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
        final sim = config?.personalSimNumber ?? 'Detecting SIM...';
        final isVerified = config?.isCallerIdVerified ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF141228), Color(0xFF0F0E1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                      const Icon(Icons.sim_card_rounded, color: AppColors.accentCyan, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'BOUND SIM NUMBER',
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
                      color: isVerified
                          ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isVerified ? '✓ CALLER ID VERIFIED' : 'PENDING VALIDATION',
                      style: GoogleFonts.inter(
                        color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
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
                isVerified
                    ? 'All outbound AI calls will display this personal phone number on recipient screens.'
                    : 'Twilio validation initiated. Enter code ${config?.validationCode ?? "..."} when prompted by phone.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── CCF Forwarding Terminal ─────────────────────────────────────────────────
  Widget _buildCcfForwardingTerminal() {
    return ValueListenableBuilder<TelephonyUserConfig?>(
      valueListenable: _service.profileNotifier,
      builder: (ctx, config, _) {
        final fwdNumber = config?.targetForwardingNumber ?? '+1 (800) 555-0199';
        final ussdAll = config?.ccfAllCode ?? '**004*$fwdNumber#';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111024),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_forwarded_rounded, color: Color(0xFF8B5CF6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'INCOMING FORWARDING (CCF)',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8B5CF6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Route calls automatically to Jack when your line is busy or unanswered.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ussdAll,
                      style: GoogleFonts.firaCode(
                        color: AppColors.accentCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: ussdAll));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CCF Code copied to clipboard')),
                        );
                      },
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
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.dialer_sip_rounded, size: 18),
                      label: Text('Activate Forwarding', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _service.launchUssdDialer(ussdAll),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    ),
                    child: Text('Disable', style: GoogleFonts.inter(fontSize: 12)),
                    onPressed: () => _service.launchUssdDialer(config?.ccfDeactivateCode ?? '##004#'),
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
              icon: const Icon(Icons.phone_forwarded_rounded, size: 18),
              label: Text(
                'Dial Showing My Caller ID',
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
                await _service.dispatchOutboundCall(
                  recipientNumber: target,
                  taskPrompt: task,
                );
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
      height: 320,
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
                    'LIVE PIPE-CAT STREAM TERMINAL',
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
          Expanded(
            child: ValueListenableBuilder<List<TranscriptEntry>>(
              valueListenable: _service.liveTranscriptNotifier,
              builder: (ctx, entries, _) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      '> Standby. Ready for incoming or outgoing calls.\n> Pipecat Deepgram STT + Groq LLM + Cartesia TTS active.',
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

                    final color = isJack
                        ? AppColors.accentCyan
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
        ],
      ),
    );
  }
}
