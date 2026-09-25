import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:developer';
import '../jack_orb.dart';
import '../../services/api/direct_groq_service.dart';
import '../../services/jack_master_dispatcher.dart';
import '../../services/voice/jack_male_voice_helper.dart';

class JackGlobalOverlay extends StatefulWidget {
  const JackGlobalOverlay({super.key});

  @override
  State<JackGlobalOverlay> createState() => _JackGlobalOverlayState();
}

class _JackGlobalOverlayState extends State<JackGlobalOverlay> {
  bool isExpanded = false;
  
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  final DirectGroqService _groq = DirectGroqService();
  
  bool _isListening = false;
  String _activeTranscript = "Tap the orb to speak.";
  String _jackResponse = "";
  OrbState _orbState = OrbState.idle;

  @override
  void initState() {
    super.initState();
    _initEngine();
    FlutterOverlayWindow.overlayListener.listen((event) {
      log("Overlay Event: $event");
    });
  }

  Future<void> _initEngine() async {
    try {
      await JackMaleVoiceHelper.configureMaleBaritoneVoice(_tts);
      await _stt.initialize();
    } catch (e) {
      log("Overlay voice init error: $e");
    }
  }

  void _startListening() async {
    if (!isExpanded) _toggleExpanded();
    await _tts.stop();
    
    setState(() {
      _isListening = true;
      _activeTranscript = "Listening...";
      _orbState = OrbState.listening;
    });

    try {
      await _stt.listen(
        onResult: (result) {
          setState(() {
            _activeTranscript = result.recognizedWords;
          });
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _processQuery(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 15),
        ),
      );
    } catch (_) {
      setState(() {
        _isListening = false;
        _orbState = OrbState.idle;
      });
    }
  }

  void _processQuery(String query) async {
    setState(() {
      _isListening = false;
      _orbState = OrbState.thinking;
      _activeTranscript = query;
      _jackResponse = "Thinking...";
    });

    try {
      // First, try hardware/reflex commands
      final reflex = await JackMasterDispatcher.tryReflexFastPath(query);
      if (reflex != null) {
        final reflexReply = reflex['message']?.toString() ?? 'Done.';
        setState(() {
          _jackResponse = reflexReply;
          _orbState = OrbState.speaking;
        });
        await _tts.speak(reflexReply);
        _tts.setCompletionHandler(() {
          if (mounted) {
            setState(() {
              _orbState = OrbState.idle;
            });
          }
        });
        return;
      }

      // If not hardware, use LLM
      final prompt = "You are Jack, a British male AI assistant. Respond to this concisely in 1-2 sentences: $query";
      String reply = await _groq.generate(prompt: prompt);
      reply = reply.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();
      
      setState(() {
        _jackResponse = reply;
        _orbState = OrbState.speaking;
      });
      
      await _tts.speak(reply);
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _orbState = OrbState.idle;
          });
        }
      });
    } catch (e) {
      setState(() {
        _jackResponse = "Network error.";
        _orbState = OrbState.error;
      });
      await _tts.speak("I seem to have lost connection.");
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }

  void _toggleExpanded() async {
    setState(() {
      isExpanded = !isExpanded;
    });
    if (isExpanded) {
      await FlutterOverlayWindow.resizeOverlay(
        WindowSize.matchParent, 
        110, // Full-width horizontal bar hovering at bottom like Gemini Live
        true,
      );
    } else {
      await FlutterOverlayWindow.resizeOverlay(
        120, 
        120, // Compact bubble size for pure Jack Orb
        true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: isExpanded 
          ? _buildHorizontalPillArray()
          : Center(
              child: JackOrb(
                size: 88, 
                state: _orbState,
                enable3dTouch: true,
                onTap: _toggleExpanded,
              ),
            ),
    );
  }

  Widget _buildHorizontalPillArray() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Camera / Lens Action
          _buildCircleButton(Icons.camera_alt_rounded, null),
          const SizedBox(width: 8),
          
          // 2. Upload / Tools Context Action
          _buildCircleButton(Icons.upload_rounded, null),
          const SizedBox(width: 8),
          
          // 3. Wide Gemini-Style Dynamic Waveform Pill with Jack's Color Combo
          _buildCentralWaveformPill(),
          const SizedBox(width: 8),
          
          // 4. Voice Mic Action
          _buildCircleButton(
            Icons.mic_rounded, 
            _startListening, 
            isActive: _isListening || _orbState == OrbState.listening,
          ),
          const SizedBox(width: 8),
          
          // 5. Close / Dismiss Action
          _buildCircleButton(Icons.close_rounded, () {
            FlutterOverlayWindow.closeOverlay();
          }),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback? onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? const Color(0xFF7C3AED) : const Color(0xFF141320),
          border: Border.all(
            color: isActive ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.12), 
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive 
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.55) 
                  : Colors.black.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 23),
      ),
    );
  }

  Widget _buildCentralWaveformPill() {
    final isActive = (_orbState == OrbState.listening || _orbState == OrbState.thinking || _orbState == OrbState.speaking);
    
    return Tooltip(
      message: _jackResponse.isNotEmpty ? _jackResponse : _activeTranscript,
      child: GestureDetector(
        onTap: _toggleExpanded, // Tap to collapse back to floating Jack Orb
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 145,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0B18), // Deep obsidian background
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15), 
              width: 1.2,
            ),
            boxShadow: [
              // Signature Multi-Color Bloom underneath the pill (Jack's Color Combo)
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: isActive ? 0.55 : 0.28), // Magenta/Pink on left
                blurRadius: 20,
                offset: const Offset(-18, 8),
              ),
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: isActive ? 0.70 : 0.35), // Violet in center
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: isActive ? 0.65 : 0.32), // Electric Cyan on right
                blurRadius: 20,
                offset: const Offset(18, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // ── Jack's Multi-tone Glowing Bottom Edge (Pink -> Purple -> Cyan) ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFEC4899).withValues(alpha: 0.85), // Magenta Pink
                        const Color(0xFFFFD166).withValues(alpha: 0.75), // Peach Sunrise
                        const Color(0xFF7C3AED).withValues(alpha: 0.90), // Royal Purple
                        const Color(0xFF00E5FF).withValues(alpha: 0.95), // Electric Cyan
                      ],
                    ),
                  ),
                ),
              ),
              
              // Top mask to diffuse the glow smoothly upward
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0D0B18).withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              
              // ── Animated Waveform Bars in Center ──
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    12,
                    (index) {
                      double barHeight = 4.0;
                      if (isActive) {
                        barHeight = (index % 3 == 0) ? 22.0 : ((index % 2 == 0) ? 14.0 : 7.0);
                        if (_orbState == OrbState.thinking) {
                          barHeight = (index % 2 == 0) ? 15.0 : 8.0;
                        }
                      }
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 3.5,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.75),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
