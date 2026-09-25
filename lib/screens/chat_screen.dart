// lib/screens/chat_screen.dart
//
// 06. Chat — Natural conversation & real results
// Pixel-to-pixel reproduction of reference image:
// Header, user & Jack chat bubbles with mini JackOrb avatar,
// clickable Lenovo LOQ 15 & ASUS TUF A15 product cards with laptop graphics,
// and bottom follow-up input bar with voice button.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/product_card_model.dart';
import '../services/agents/jack_multi_agent_orchestrator.dart';
import '../services/app_launcher_helper.dart';
import '../theme/app_colors.dart';
import '../widgets/jack_orb.dart';
import '../widgets/animations/loading_dev_indicators.dart';
import '../services/voice/jack_male_voice_helper.dart';
import '../services/jack_master_dispatcher.dart';

class _ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final List<ProductCardItem>? products;
  final List<AgentExecutionStep>? steps;
  final List<String>? involvedAgents;
  final DateTime timestamp;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.products,
    this.steps,
    this.involvedAgents,
    required this.timestamp,
  });
}

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const ChatScreen({super.key, this.initialQuery});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechInitialized = false;
  bool _isListening = false;
  bool _isThinking = false;
  String _workingAgentName = 'Executive Planner';
  String _workingAgentStatus = 'Reasoning...';
  final List<ThoughtLineStep> _activeThinkingSteps = [];

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!.trim());
      });
    } else {
      _initCanonicalConversation();
    }
  }

  void _initCanonicalConversation() {
    _messages.addAll([
      _ChatMessage(
        id: 'msg_canonical_user',
        text: 'Find me the best laptop deals under \$1,000 right now.',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      _ChatMessage(
        id: 'msg_canonical_jack',
        text:
            'I found two standout gaming and productivity machines currently discounted on Amazon and Best Buy with top price-to-performance ratings:',
        isUser: false,
        steps: [
          AgentExecutionStep(
            agentId: 'executive',
            agentName: 'Executive Planner',
            badgeColor: const Color(0xFF00E5FF),
            title: 'Goal Analysis & Planning',
            detail: 'Decomposed intent: Find verified laptop deals under \$1,000.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          AgentExecutionStep(
            agentId: 'deep_research',
            agentName: 'Deep Research Specialist',
            badgeColor: const Color(0xFF2DD4BF),
            title: 'Google Grounding & Spec Normalization',
            detail:
                'Grounded live deals across major retailers; identified Lenovo LOQ 15 and ASUS TUF A15 with RTX 4050 GPUs.',
            timestamp:
                DateTime.now().subtract(const Duration(minutes: 4, seconds: 40)),
          ),
          AgentExecutionStep(
            agentId: 'executive',
            agentName: 'Executive Planner',
            badgeColor: const Color(0xFF00E5FF),
            title: 'Final Synthesis',
            detail: 'Synthesized side-by-side product cards with verified ratings.',
            timestamp:
                DateTime.now().subtract(const Duration(minutes: 4, seconds: 20)),
          ),
        ],
        involvedAgents: const [
          'Executive Planner',
          'Deep Research Specialist',
        ],
        products: const [
          ProductCardItem(
            title: 'Lenovo LOQ 15',
            price: '\$899.99',
            ratingValue: '4.8',
            reviewsCount: '2.4k',
            screenText: 'LOQ 15',
            screenGlowColor: Color(0xFF00E5FF),
            wallpaperColors: [Color(0xFF00E5FF), Color(0xFF1E1B4B)],
            specs: {
              'Processor': 'Intel Core i5-13420H (13th Gen)',
              'Graphics': 'NVIDIA GeForce RTX 4050 6GB GDDR6',
              'Display': '15.6" FHD (1920x1080) 144Hz IPS',
              'RAM': '16GB DDR5 5200MHz',
              'Storage': '512GB PCIe NVMe Gen4 SSD',
            },
            purchaseUrl:
                'https://www.google.com/search?q=Lenovo+LOQ+15+buy+deals',
          ),
          ProductCardItem(
            title: 'ASUS TUF A15',
            price: '\$849.00',
            ratingValue: '4.7',
            reviewsCount: '3.1k',
            screenText: 'TUF A15',
            screenGlowColor: Color(0xFF7C3AED),
            wallpaperColors: [Color(0xFF7C3AED), Color(0xFF3B0764)],
            specs: {
              'Processor': 'AMD Ryzen 7 7735HS (8 cores)',
              'Graphics': 'NVIDIA GeForce RTX 4050 6GB',
              'Display': '15.6" FHD 144Hz 100% sRGB',
              'RAM': '16GB DDR5 Dual Channel',
              'Storage': '512GB PCIe 4.0 SSD + Extra M.2 slot',
            },
            purchaseUrl:
                'https://www.google.com/search?q=ASUS+TUF+A15+buy+deals',
          ),
        ],
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ]);
  }

  Future<void> _initTts() async {
    try {
      await JackMaleVoiceHelper.configureMaleBaritoneVoice(_tts);
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (s) {
          if (s == 'notListening' || s == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechInitialized = false;
    }
  }

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) return;

    if (!_speechInitialized) await _initSpeech();

    if (_speechInitialized) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            _textController.text = result.recognizedWords;
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              _sendMessage(result.recognizedWords.trim());
            }
          }
        },
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: query,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isThinking = true;
      _workingAgentName = 'Executive Planner';
      _workingAgentStatus = 'Decomposing task into specialist agent sub-goals...';
      _activeThinkingSteps.clear();
      _activeThinkingSteps.add(const ThoughtLineStep(
        text: 'Executive Planner: Analyzing intent & tool dependencies',
        isDone: false,
        color: Color(0xFF00E5FF),
      ));
    });

    _scrollToBottom();

    // ── Instant Deterministic Reflex Path (<100ms) ──────────────────────────
    final reflex = await JackMasterDispatcher.tryReflexFastPath(query);
    if (reflex != null) {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _activeThinkingSteps.clear();
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: reflex['message']?.toString() ?? 'Action executed, Sir.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
      return;
    }

    final history = _messages.take(12).map((m) => {
      'role': m.isUser ? 'user' : 'assistant',
      'content': m.text,
    }).toList();

    try {
      final multiAgent = ref.read(multiAgentOrchestratorProvider);
      final result = await multiAgent.executeMultiAgentGoal(
        query: query,
        conversationHistory: history,
        onProgress: (agentName, status) {
          if (mounted) {
            setState(() {
              _workingAgentName = agentName;
              _workingAgentStatus = status;

              // Mark earlier active steps as done
              for (int i = 0; i < _activeThinkingSteps.length; i++) {
                final s = _activeThinkingSteps[i];
                if (!s.isDone) {
                  _activeThinkingSteps[i] = ThoughtLineStep(
                    text: s.text,
                    isDone: true,
                    color: s.color,
                  );
                }
              }

              Color agentColor = const Color(0xFF00E5FF);
              if (agentName.contains('Research')) {
                agentColor = const Color(0xFF2DD4BF);
              } else if (agentName.contains('Device') || agentName.contains('DOM')) {
                agentColor = const Color(0xFF38BDF8);
              } else if (agentName.contains('Tool') || agentName.contains('MCP')) {
                agentColor = const Color(0xFFFBBF24);
              } else if (agentName.contains('Telephony')) {
                agentColor = const Color(0xFFA855F7);
              }

              _activeThinkingSteps.add(ThoughtLineStep(
                text: '$agentName: $status',
                isDone: false,
                color: agentColor,
              ));
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isThinking = false;
          _activeThinkingSteps.clear();
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: result.text,
            isUser: false,
            products: result.products,
            steps: result.steps,
            involvedAgents: result.involvedAgents,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();

        // Voice output for continuous conversational loop
        try {
          final clean = result.text
              .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
              .replaceAll('*', '')
              .trim();
          final spokenSnippet =
              clean.length > 200 ? '${clean.substring(0, 200)}...' : clean;
          await _tts.speak(spokenSnippet);
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _activeThinkingSteps.clear();
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'I encountered an issue coordinating sub-agents: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showProductDetails(ProductCardItem prod) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            const SizedBox(height: 18),
            Center(
              child: _LaptopGraphic(
                screenGlowColor: prod.screenGlowColor,
                wallpaperColors: prod.wallpaperColors,
                screenText: prod.screenText,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.title,
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 4),
                        Text(prod.ratingValue,
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Text(prod.reviewsCount,
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Text(
                  prod.price,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Text(
              'Technical Specifications',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...prod.specs.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key,
                          style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 12.5)),
                      Text(entry.value,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Added ${prod.title} to Price Drop Automations!'),
                          backgroundColor: AppColors.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.sell_rounded, size: 16),
                    label: Text('Track Price',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final url = prod.purchaseUrl ??
                          'https://www.google.com/search?q=${Uri.encodeComponent(prod.title)}';
                      AppLauncherHelper.openUrl(url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('View Deal',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.8,
            color: Colors.white70,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // ── Header: Title & Subtitle ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your always-on AI partner.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Messages Stream ───────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  return _buildMessageItem(msg);
                },
              ),
            ),

            // ── React Bits LatticeLoader & ThoughtLine for Multi-Agent AI Thinking ─
            if (_isThinking)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141320),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          LatticeLoader(
                            status: LatticeStatus.working,
                            label: _workingAgentName,
                            pattern: 'orbit',
                            grid: 3,
                            shape: LatticeShape.round,
                            color: const Color(0xFF00E5FF),
                            glow: true,
                            glowColor: const Color(0xFF00E5FF),
                            cellSize: 5.5,
                            gap: 2.0,
                            fontSize: 12,
                            showTimer: true,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '• $_workingAgentStatus',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ThoughtLine(
                      label: '$_workingAgentName: $_workingAgentStatus',
                      glyph: 'sparkle',
                      glyphColor: const Color(0xFF00E5FF),
                      working: true,
                      showTimer: true,
                      steps: _activeThinkingSteps,
                      collapsible: true,
                    ),
                  ],
                ),
              ),

            // ── React Bits PromptBar with @ Sources, / Commands, Model Picker, Effort Slider & VoicePill
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 10.0),
              child: PromptBar(
                controller: _textController,
                focusNode: _focusNode,
                placeholder: 'Ask Jack anything...',
                busy: _isThinking,
                onSend: (text, {attachments, model, effort}) {
                  _sendMessage(text);
                },
                onStop: () {
                  setState(() => _isThinking = false);
                },
                onDictate: () async {
                  await _toggleListening();
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiAgentTrace(_ChatMessage msg) {
    if (msg.steps == null || msg.steps!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ThoughtLine(
        label: '${msg.steps!.length} Sub-Agents Collaborated',
        doneLabel: '${msg.steps!.length} Sub-Agents Executed',
        glyph: 'sparkle',
        glyphColor: const Color(0xFF00E5FF),
        working: false,
        showTimer: false,
        collapsible: true,
        collapseOnSettle: true,
        steps: msg.steps!.map((step) {
          return ThoughtLineStep(
            text: '${step.agentName} • ${step.detail}',
            isDone: true,
            color: step.badgeColor,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageItem(_ChatMessage msg) {
    if (msg.isUser) {
      // User Message Bubble (Right-aligned)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2234),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    // Jack AI Message
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glowing Jack Orb Avatar matching reference image
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: JackOrb(size: 28, state: OrbState.idle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141320),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMultiAgentTrace(msg),
                        _buildRichMessageContent(context, msg.text),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Side-by-side Clickable Product Cards (Matching Reference Screen 06)
            if (msg.products != null && msg.products!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 36.0),
                child: Row(
                  children: msg.products!.map((prod) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _showProductDetails(prod),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141320),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Open Laptop Graphic
                              Center(
                                child: _LaptopGraphic(
                                  screenGlowColor: prod.screenGlowColor,
                                  wallpaperColors: prod.wallpaperColors,
                                  screenText: prod.screenText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                prod.title,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                prod.price,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFBBF24), size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    prod.ratingValue,
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      prod.reviewsCount,
                                      style: GoogleFonts.inter(
                                        color: Colors.white38,
                                        fontSize: 10.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRichMessageContent(BuildContext context, String text) {
    final imageRegex = RegExp(r'!\[(.*?)\]\((.*?)\)');

    // Clean broken lone asterisks caused by linebreaks
    final cleanedText = text
        .replaceAll(RegExp(r'\n\s*\*\*\s*\n'), '\n')
        .replaceAll(RegExp(r'^\s*\*\*\s*$', multiLine: true), '');

    final lines = cleanedText.split('\n');
    final List<Widget> blocks = [];
    final maxBtnWidth = MediaQuery.of(context).size.width * 0.72;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        blocks.add(const SizedBox(height: 5));
        continue;
      }

      // 1. Check for inline markdown image
      final imgMatch = imageRegex.firstMatch(line);
      if (imgMatch != null) {
        final imgUrl = imgMatch.group(2) ?? '';
        final altText = imgMatch.group(1) ?? '';
        if (imgUrl.isNotEmpty) {
          blocks.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imgUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_outlined,
                            color: Colors.white38, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            altText.isNotEmpty ? altText : 'Preview Image',
                            style: GoogleFonts.inter(
                                color: Colors.white54, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          continue;
        }
      }

      // 2. Check for Heading
      if (line.startsWith('### ') || line.startsWith('## ') || line.startsWith('# ')) {
        final headingText = line.replaceFirst(RegExp(r'^#+\s*'), '');
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
            child: Text(
              headingText,
              style: GoogleFonts.inter(
                color: const Color(0xFF00E5FF),
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
        continue;
      }

      // 3. Standalone link line (render as a constrained tappable action chip)
      final standaloneLinkMatch = RegExp(r'^\[(.*?)\]\((https?://[^\s\)]+)\)$').firstMatch(line);
      if (standaloneLinkMatch != null) {
        final label = standaloneLinkMatch.group(1) ?? 'Open Link';
        final url = standaloneLinkMatch.group(2) ?? '';
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                AppLauncherHelper.openUrl(url);
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: maxBtnWidth),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new_rounded,
                        color: Color(0xFF00E5FF), size: 13),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // 4. Line with inline links or markdown formatting (Bold & TextSpans that wrap safely)
      final spans = <InlineSpan>[];
      int lastIndex = 0;

      // Match markdown links [label](url) or bold **bold text**
      final tokenRegex = RegExp(r'(\[(.*?)\]\((https?://[^\s\)]+)\)|\*\*(.*?)\*\*)');
      final matches = tokenRegex.allMatches(line);

      for (final m in matches) {
        if (m.start > lastIndex) {
          spans.add(TextSpan(
            text: line.substring(lastIndex, m.start),
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 13.5, height: 1.45),
          ));
        }

        if (m.group(1)?.startsWith('[') == true) {
          // Markdown link
          final label = m.group(2) ?? 'Link';
          final url = m.group(3) ?? '';
          spans.add(TextSpan(
            text: label,
            style: GoogleFonts.inter(
              color: const Color(0xFF00E5FF),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF00E5FF),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                HapticFeedback.lightImpact();
                AppLauncherHelper.openUrl(url);
              },
          ));
        } else if (m.group(4) != null) {
          // Bold text
          final boldText = m.group(4)!;
          spans.add(TextSpan(
            text: boldText,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ));
        }

        lastIndex = m.end;
      }

      if (lastIndex < line.length) {
        spans.add(TextSpan(
          text: line.substring(lastIndex),
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 13.5, height: 1.45),
        ));
      }

      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 3.0),
          child: Text.rich(
            TextSpan(children: spans),
            softWrap: true,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}

/// Custom Open Laptop Display Graphic matching reference image
class _LaptopGraphic extends StatelessWidget {
  final Color screenGlowColor;
  final List<Color> wallpaperColors;
  final String screenText;

  const _LaptopGraphic({
    required this.screenGlowColor,
    required this.wallpaperColors,
    required this.screenText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Open Screen Lid with Bezel & Glowing Neon Graphic
          Container(
            width: 100,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
              border: Border.all(color: const Color(0xFF2C2C3A), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: screenGlowColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3.5)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: wallpaperColors,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Text(
                        screenText,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Laptop Keyboard Base / Deck
          Container(
            width: 114,
            height: 5.5,
            decoration: const BoxDecoration(
              color: Color(0xFF22222E),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 3,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 22,
                height: 1.2,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
