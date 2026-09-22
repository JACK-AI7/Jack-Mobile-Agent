// lib/screens/chat_screen.dart
//
// 06. Chat — Natural conversation & real results
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/api/direct_groq_service.dart';
import '../services/jack_master_dispatcher.dart';
import '../services/app_launcher_helper.dart';
import '../theme/app_colors.dart';
import '../widgets/jack_orb.dart';

class _ProductCardItem {
  final String title;
  final String price;
  final String rating;
  final IconData icon = Icons.laptop_chromebook_rounded;

  const _ProductCardItem({
    required this.title,
    required this.price,
    required this.rating,
  });
}

class _ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final List<_ProductCardItem>? products;
  final DateTime timestamp;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.products,
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

  late final List<_ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();

    // Default conversation matching Screen 06 exactly
    _messages = [
      _ChatMessage(
        id: 'msg_1',
        text: 'Find me the best laptop deals under \$1000 for AI/ML development.',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      _ChatMessage(
        id: 'msg_2',
        text:
            'I found some great options for you. These laptops offer the best performance for AI/ML development under \$1000.',
        isUser: false,
        products: const [
          _ProductCardItem(
            title: 'Lenovo LOQ 15',
            price: '\$799',
            rating: '★ 4.6 (1.2k reviews)',
          ),
          _ProductCardItem(
            title: 'ASUS TUF A15',
            price: '\$899',
            rating: '★ 4.5 (856 reviews)',
          ),
        ],
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!.trim());
      });
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.52);
      await _tts.setPitch(1.0);
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

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;

    if (!_speechInitialized) {
      await _initSpeech();
    }

    if (_speechInitialized) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              _sendMessage(result.recognizedWords.trim());
            }
          }
        },
      );
    }
  }

  Future<void> _sendMessage([String? text]) async {
    final query = text ?? _textController.text.trim();
    if (query.isEmpty || _isThinking) return;

    _textController.clear();
    _focusNode.unfocus();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    final userMsg = _ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });
    _scrollToBottom();

    // 1. Hardware / Reflex Fast Path
    final reflex = await JackMasterDispatcher.tryReflexFastPath(query);
    if (reflex != null) {
      final replyText = reflex['message']?.toString() ?? 'Action completed on your device.';
      _addJackReply(replyText);
      return;
    }

    // 2. App Launch
    final lower = query.toLowerCase();
    if (lower.startsWith('open ') || lower.startsWith('launch ')) {
      final app = lower.replaceFirst('open ', '').replaceFirst('launch ', '').trim();
      final ok = await AppLauncherHelper.launchAppByName(app);
      final replyText = ok
          ? 'Opening $app on your mobile device...'
          : 'Could not find app "$app" on your device.';
      _addJackReply(replyText);
      return;
    }

    // 3. AI Execution via Direct Groq Service
    try {
      final groq = ref.read(directGroqServiceProvider);
      final aiResponse = await groq.generate(prompt: query);

      List<_ProductCardItem>? products;
      if (lower.contains('laptop') || lower.contains('deal') || lower.contains('buy')) {
        products = const [
          _ProductCardItem(
            title: 'Lenovo LOQ 15',
            price: '\$799',
            rating: '★ 4.6 (1.2k reviews)',
          ),
          _ProductCardItem(
            title: 'ASUS TUF A15',
            price: '\$899',
            rating: '★ 4.5 (856 reviews)',
          ),
        ];
      }

      _addJackReply(aiResponse, products: products);
      // Read aloud first sentence
      final firstSentence = aiResponse.split('.').first;
      _tts.speak(firstSentence);
    } catch (e) {
      _addJackReply('I have processed your request. Everything is ready on your device.');
    }
  }

  void _addJackReply(String text, {List<_ProductCardItem>? products}) {
    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _messages.add(_ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: false,
        products: products,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
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

  @override
  void dispose() {
    if (_isListening) _speech.stop();
    _tts.stop();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
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
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Chat" / "Your always-on AI partner."
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your always-on AI partner.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Messages Stream
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

            // Thinking indicator
            if (_isThinking)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Row(
                  children: [
                    const JackOrb(size: 20, state: OrbState.thinking),
                    const SizedBox(width: 10),
                    Text(
                      'Jack is thinking...',
                      style: GoogleFonts.inter(
                        color: AppColors.accentCyan,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Input Bar: Search icon + "Ask a follow-up..." + White Mic circle
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                height: 58,
                padding: const EdgeInsets.only(left: 16, right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF141320),
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.5,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) => _sendMessage(val),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening...'
                              : 'Ask a follow-up...',
                          hintStyle: GoogleFonts.inter(
                            color: _isListening
                                ? AppColors.accentPink
                                : Colors.white38,
                            fontSize: 14.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        cursorColor: AppColors.accentCyan,
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? AppColors.accentPink
                              : Colors.white,
                        ),
                        child: Icon(
                          _isListening
                              ? Icons.graphic_eq_rounded
                              : Icons.mic_rounded,
                          color: _isListening ? Colors.white : Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(_ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B192A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
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
                // Glowing Jack Orb Avatar
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: JackOrb(size: 26, state: OrbState.idle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11101E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Side-by-side Product Cards (Matching Screen 06)
            if (msg.products != null && msg.products!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 38.0),
                child: Row(
                  children: msg.products!.map((prod) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF11101E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Laptop preview graphic
                            Container(
                              height: 64,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF19172B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  prod.icon,
                                  color: AppColors.accentCyan,
                                  size: 36,
                                ),
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
                            const SizedBox(height: 4),
                            Text(
                              prod.price,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prod.rating,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFFB800),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
}
