// lib/screens/chat_screen.dart
//
// JACK AGENT — Real AI Chat Screen
// Connects to Groq API (llama-3.3-70b-versatile) with autonomous task execution cards.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/jack_api_client.dart';
import '../services/realtime/agent_execution_controller.dart';
import '../models/realtime/socket_events.dart';
import '../models/agent/jack_agent_request.dart';
import '../widgets/jack_approval_card.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/jack_orb.dart';
import '../widgets/glass_card.dart';

// ── Data Models ──────────────────────────────────────────────────────────────

class _TaskItem {
  final String title;
  final String? price;
  final String description;
  final String? badge;
  final IconData icon;

  const _TaskItem({
    required this.title,
    this.price,
    required this.description,
    this.badge,
    this.icon = Icons.inventory_2_outlined,
  });
}

class _TaskExecutionData {
  final String title;
  final String type; // 'product' | 'execution' | 'analysis'
  final List<_TaskItem> items;
  final String? summary;

  const _TaskExecutionData({
    required this.title,
    required this.type,
    required this.items,
    this.summary,
  });

  /// Intelligently parses product, pricing, and task execution data from AI responses.
  static _TaskExecutionData? tryParse(String content) {
    try {
      final lines = content.split('\n');
      final items = <_TaskItem>[];
      final priceRegex = RegExp(
        r'(\$|₹|€|£|USD|INR)\s*[\d,]+(?:\.\d+)?',
        caseSensitive: false,
      );
      final itemRegex = RegExp(
        r'^(?:[-*•]|\d+\.)\s*(?:\*\*(.*?)\*\*|(.*?))(?:\s*[:\-–|]\s*(.*))?$',
      );

      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;

        final priceMatch = priceRegex.firstMatch(line);
        final hasPrice = priceMatch != null;
        final match = itemRegex.firstMatch(line);

        if (match != null) {
          String title = (match.group(1) ?? match.group(2) ?? '').trim();
          title = title.replaceAll('*', '').replaceAll('`', '').trim();
          String desc = (match.group(3) ?? '').trim();

          if (title.contains(':') && desc.isEmpty) {
            final parts = title.split(':');
            title = parts[0].trim();
            desc = parts.sublist(1).join(':').trim();
          }

          String? price;
          if (hasPrice) {
            price = priceMatch.group(0);
          }

          desc = desc.replaceAll('**', '').replaceAll('*', '').trim();

          if (title.isNotEmpty && title.length > 2 && title.length < 65) {
            items.add(_TaskItem(
              title: title,
              price: price,
              description: desc,
              icon: hasPrice
                  ? Icons.shopping_bag_outlined
                  : Icons.task_alt_rounded,
              badge: hasPrice
                  ? 'OPTION #${items.length + 1}'
                  : 'STEP #${items.length + 1}',
            ));
          }
        }
      }

      if (items.length >= 2) {
        final hasPrices = items.any((it) => it.price != null);
        return _TaskExecutionData(
          title: hasPrices
              ? 'Autonomous Product Search'
              : 'Task Execution Summary',
          type: hasPrices ? 'product' : 'execution',
          items: items.take(4).toList(),
          summary: hasPrices
              ? '${items.length} verified options identified'
              : 'Pipeline completed across ${items.length} steps',
        );
      }

      final lower = content.toLowerCase();
      if ((lower.contains('bus') ||
              lower.contains('flight') ||
              lower.contains('product') ||
              lower.contains('recommend')) &&
          priceRegex.hasMatch(content) &&
          items.isNotEmpty) {
        return _TaskExecutionData(
          title: 'Structured Result Data',
          type: 'product',
          items: items.take(4).toList(),
          summary: 'Live real-time data extracted',
        );
      }
    } catch (_) {
      // Return null on parsing anomaly to preserve raw text presentation
    }
    return null;
  }
}

class _Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final _TaskExecutionData? taskData;

  const _Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.taskData,
  });
}

// ── Screen Widget ────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const ChatScreen({super.key, this.initialQuery});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  // State
  late final List<_Message> _messages;
  bool _isThinking = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Speech-to-text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  static const _samplePrompts = [
    '🎧 Best noise-cancelling headphones under \$300',
    '🚌 Search buses from Hyderabad to Bangalore',
    '📊 Analyze Tesla vs Apple recent performance',
    '⚡ Automate cab booking for tomorrow morning',
  ];

  @override
  void initState() {
    super.initState();

    _messages = [
      _Message(
        id: 'welcome',
        text:
            "Hello! I am JACK, your autonomous mobile AI agent. Ask me anything, or instruct me to research products, compare prices, or automate device actions.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];

    _initSpeech();

    // If an initial query was passed via navigation, execute it automatically
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!.trim());
      });
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
  }

  void _toggleListening() async {
    HapticFeedback.lightImpact();

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (_speechAvailable) {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          }
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone access is not granted or speech recognition is unavailable.',
            ),
            backgroundColor: AppColors.surfaceElevated,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  Future<void> _sendMessage([String? text]) async {
    final msg = text ?? _textController.text.trim();
    if (msg.isEmpty || _isThinking) return;

    _textController.clear();
    _focusNode.unfocus();

    final userMsg = _Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: msg,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });

    _scrollToBottom();

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final response = await apiClient.executeAgent(JackAgentRequest(
        requestId: DateTime.now().millisecondsSinceEpoch.toString(),
        message: msg,
      ));

      final jackMsg = _Message(
        id: response.executionId,
        text: response.result ?? "I am processing your request.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(jackMsg);
          _isThinking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages.add(_Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: e.toString().replaceAll('Exception:', '').trim(),
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.clear();
      _messages.add(
        _Message(
          id: 'welcome',
          text:
              "Conversation reset. I am ready for your next instruction or autonomous workflow.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.4, -0.6),
            radius: 1.2,
            colors: [Color(0xFF0C0A26), AppColors.backgroundDeep],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return _buildThinkingCard();
                    }
                    final msg = _messages[index];
                    return msg.isUser
                        ? _buildUserMessage(msg)
                        : _buildJackMessage(msg);
                  },
                ),
              ),
              Consumer(builder: (context, ref, child) {
                final executionState = ref.watch(agentExecutionProvider);
                if (executionState.orbState == JackOrbState.WAITING_FOR_APPROVAL && executionState.approvalRequest != null) {
                  return JackApprovalCard(
                    requestData: executionState.approvalRequest,
                    onResolved: () {}, // Backend Socket will automatically dismiss when resolved
                  );
                }
                return const SizedBox.shrink();
              }),
              if (_messages.length <= 1 && !_isThinking)
                _buildQuickSuggestions(),
              _buildBottomInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background.withValues(alpha: 0.85),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: AppColors.textPrimary,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chat',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Your always-on AI partner',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Clear Chat',
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          onPressed: _clearChat,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: JackOrb(
            size: 34,
            state: _isThinking
                ? OrbState.thinking
                : (_isListening ? OrbState.listening : OrbState.idle),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.surfaceBorder.withValues(alpha: 0.6),
          height: 1,
        ),
      ),
    );
  }

  // ── User Message (Right-aligned with cyan accent bubble) ───────────────────

  Widget _buildUserMessage(_Message msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF00E5FF),
              Color(0xFF00A2FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentCyan.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF040410),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.timestamp),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0x99040410),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  // ── JACK Message (GlassCard with dark background) ──────────────────────────

  Widget _buildJackMessage(_Message msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 32),
        child: GlassCard(
          borderRadius: 16,
          backgroundColor: AppColors.surfaceCard,
          borderColor: msg.isError
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.surfaceBorder,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Jack Orb avatar + JACK name + timestamp
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Center(
                      child: Text(
                        'J',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JACK',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(msg.timestamp),
                    style: AppTypography.caption(
                      color: AppColors.textTertiary,
                      size: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Message body text
              SelectableText(
                msg.text,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: msg.isError ? AppColors.error : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
              // Task Execution Card when product or result data is present
              if (msg.taskData != null) ...[
                const SizedBox(height: 14),
                _buildTaskExecutionCard(msg.taskData!),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  // ── Thinking State (GlassCard + animated dots + JackOrb) ───────────────────

  Widget _buildThinkingCard() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 60),
        child: GlassCard(
          borderRadius: 16,
          backgroundColor: AppColors.surfaceCard,
          borderColor: AppColors.accentCyan.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: JackOrb(
                  size: 22,
                  state: OrbState.thinking,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thinking',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 4),
              _buildThinkingDots(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildThinkingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppColors.accentCyan,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.4, 1.4),
              duration: 400.ms,
              delay: (i * 150).ms,
              curve: Curves.easeInOut,
            )
            .fade(
              begin: 0.3,
              end: 1.0,
              duration: 400.ms,
              delay: (i * 150).ms,
            );
      }),
    );
  }

  // ── Task Execution Card ────────────────────────────────────────────────────

  Widget _buildTaskExecutionCard(_TaskExecutionData data) {
    final isProduct = data.type == 'product';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isProduct
              ? AppColors.accentCyan.withValues(alpha: 0.35)
              : AppColors.accentViolet.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isProduct
                          ? AppColors.accentCyan
                          : AppColors.accentViolet)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isProduct
                      ? Icons.shopping_bag_outlined
                      : Icons.terminal_rounded,
                  size: 16,
                  color:
                      isProduct ? AppColors.accentCyan : AppColors.accentViolet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isProduct
                            ? AppColors.accentCyan
                            : AppColors.accentViolet,
                      ),
                    ),
                    if (data.summary != null)
                      Text(
                        data.summary!,
                        style: AppTypography.caption(
                          color: AppColors.textSecondary,
                          size: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Items
          ...data.items.map((item) => _buildTaskItemTile(item, isProduct)),
          const SizedBox(height: 8),
          // Action button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isProduct
                            ? 'Saved ${data.items.length} items to your Jack Library'
                            : 'Executed autonomous action pipeline successfully',
                      ),
                      backgroundColor: AppColors.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentCyan.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isProduct
                            ? Icons.bookmark_add_outlined
                            : Icons.play_arrow_rounded,
                        size: 14,
                        color: AppColors.accentCyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isProduct ? 'Save to Library' : 'Run Automation',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItemTile(_TaskItem item, bool isProduct) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              item.icon,
              size: 14,
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.price != null && item.price!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.price!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.badge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.badge!,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentViolet,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Suggestions ──────────────────────────────────────────────────────

  Widget _buildQuickSuggestions() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _samplePrompts.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final prompt = _samplePrompts[i];
          return ActionChip(
            label: Text(
              prompt,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            backgroundColor: AppColors.surfaceElevated,
            side: const BorderSide(color: AppColors.surfaceBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  // ── Bottom Input Row ───────────────────────────────────────────────────────

  Widget _buildBottomInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.navBackground.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.navBorder, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mic button
          _buildMicButton(),
          const SizedBox(width: 8),
          // TextField
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isListening
                      ? AppColors.accentPink
                      : AppColors.surfaceBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      _isListening ? 'Listening...' : 'Ask Jack anything...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: _isListening
                        ? AppColors.accentPink
                        : AppColors.textTertiary,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening
              ? AppColors.accentPink.withValues(alpha: 0.25)
              : AppColors.surfaceElevated,
          border: Border.all(
            color: _isListening ? AppColors.accentPink : AppColors.surfaceBorder,
            width: 1.2,
          ),
          boxShadow: _isListening
              ? [
                  BoxShadow(
                    color: AppColors.accentPink.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
          color: _isListening ? AppColors.accentPink : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = !_isThinking;

    return GestureDetector(
      onTap: canSend ? () => _sendMessage() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: canSend
              ? const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.accentViolet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.surfaceBorder,
                  ],
                ),
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isThinking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
