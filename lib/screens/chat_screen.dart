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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final String ratingValue;
  final String reviewsCount;
  final String screenText;
  final Color screenGlowColor;
  final List<Color> wallpaperColors;
  final Map<String, String> specs;

  const _ProductCardItem({
    required this.title,
    required this.price,
    required this.ratingValue,
    required this.reviewsCount,
    required this.screenText,
    required this.screenGlowColor,
    required this.wallpaperColors,
    required this.specs,
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

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();

    // Seed canonical conversation from reference specification
    _messages.addAll([
      _ChatMessage(
        id: 'user_1',
        text: 'Find me the best laptop deals\nunder \$1000 for AI/ML development.',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      _ChatMessage(
        id: 'jack_1',
        text:
            'I found some great options for you. These laptops offer the best performance for AI/ML development under \$1000.',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        products: [
          const _ProductCardItem(
            title: 'Lenovo LOQ 15',
            price: '\$799',
            ratingValue: '4.6',
            reviewsCount: '(1.2K reviews)',
            screenText: 'LOQ 15',
            screenGlowColor: Color(0xFF00E5FF),
            wallpaperColors: [
              Color(0xFF00E5FF),
              Color(0xFF2563EB),
              Color(0xFF090915),
            ],
            specs: {
              'GPU': 'NVIDIA RTX 4060 8GB GDDR6',
              'CPU': 'AMD Ryzen 7 7735HS (8 Cores)',
              'RAM': '16 GB DDR5 4800MHz',
              'Storage': '512 GB PCIe 4.0 NVMe SSD',
              'Display': '15.6" 144Hz FHD 100% sRGB',
            },
          ),
          const _ProductCardItem(
            title: 'ASUS TUF A15',
            price: '\$899',
            ratingValue: '4.5',
            reviewsCount: '(856 reviews)',
            screenText: 'TUF A15',
            screenGlowColor: Color(0xFFEF4444),
            wallpaperColors: [
              Color(0xFFEF4444),
              Color(0xFF991B1B),
              Color(0xFF090915),
            ],
            specs: {
              'GPU': 'NVIDIA RTX 4060 8GB (140W Max)',
              'CPU': 'AMD Ryzen 7 7735HS',
              'RAM': '16 GB DDR5 4800MHz',
              'Storage': '512 GB NVMe M.2 SSD',
              'Display': '15.6" 144Hz IPS FreeSync',
            },
          ),
        ],
      ),
    ]);

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialQuery!.trim());
      });
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-GB');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(0.90); // British male baritone JARVIS
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
    });

    _scrollToBottom();

    // Check fast-path reflex dispatcher
    final reflex = await JackMasterDispatcher.tryReflexFastPath(query);
    if (reflex != null) {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: reflex['result']?.toString() ?? 'Action executed.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
      return;
    }

    // App launch handling
    final lower = query.toLowerCase();
    if (lower.startsWith('open ') || lower.startsWith('launch ')) {
      final appName = query.substring(lower.indexOf(' ') + 1).trim();
      final launched = await AppLauncherHelper.launchAppByName(appName);
      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: launched ? 'Opening $appName...' : 'Could not find app $appName.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
      return;
    }

    // Direct LLM reasoning
    try {
      final response =
          await ref.read(directGroqServiceProvider).generate(prompt: query);
      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages.add(_ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'I encountered an issue processing your request: $e',
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

  void _showProductDetails(_ProductCardItem prod) {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening deal link for ${prod.title}...'),
                          backgroundColor: AppColors.surfaceElevated,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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

            // ── Thinking Indicator ────────────────────────────────────────
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

            // ── Bottom Input Bar: Search icon + "Ask a follow-up..." + White Mic button
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
