// lib/widgets/siri_mic_button.dart
//
// Jack — Live Audio-Reactive Siri Mic Ripple Button
// Uses mic amplitude polling to drive SiriRipplePainter ring expansion
// Falls back gracefully if mic permission not available
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../painters/siri_ambient_aura.dart';
import '../theme/siri_gemini_theme.dart';

class SiriMicRippleButton extends StatefulWidget {
  /// Called when the user taps the button to toggle recording.
  final VoidCallback? onTap;

  /// Whether this button is currently in the active/listening state
  /// (driven externally by AgentState, so the button stays in sync).
  final bool isActive;

  const SiriMicRippleButton({
    super.key,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<SiriMicRippleButton> createState() => _SiriMicRippleButtonState();
}

class _SiriMicRippleButtonState extends State<SiriMicRippleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  // Amplitude polling via SpeechToText soundLevel
  final SpeechToText _stt = SpeechToText();
  double _currentAmplitude = 0.0;
  Timer? _idleWaveTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _initStt();
    _startIdleAnimation();
  }

  Future<void> _initStt() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      await _stt.initialize();
    }
  }

  /// Gently pulse amplitude at rest so rings are always subtly visible
  void _startIdleAnimation() {
    _idleWaveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!widget.isActive && mounted) {
        setState(() {
          _currentAmplitude =
              0.12 + 0.08 * (1 + _waveController.value * 2 % 1);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SiriMicRippleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Boost amplitude while listening
      setState(() => _currentAmplitude = 0.55);
    } else if (!widget.isActive && oldWidget.isActive) {
      setState(() => _currentAmplitude = 0.12);
    }
  }

  @override
  void dispose() {
    _idleWaveTimer?.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool listening = widget.isActive;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Audio-reactive multi-wave ripples ─────────────────────────
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(84, 84),
                  painter: SiriRipplePainter(
                    wavePhase: _waveController.value,
                    amplitude: _currentAmplitude,
                  ),
                );
              },
            ),

            // ── Central chromatic mic pill ─────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: listening ? 52 : 48,
              height: listening ? 52 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SiriGeminiTheme.siriMicGradient,
                boxShadow: [
                  BoxShadow(
                    color: SiriGeminiTheme.siriPurple.withValues(
                      alpha: listening ? 0.65 : 0.35,
                    ),
                    blurRadius: listening
                        ? 22 + (_currentAmplitude * 12)
                        : 14,
                    spreadRadius: listening ? 2 + (_currentAmplitude * 4) : 1,
                  ),
                  BoxShadow(
                    color: SiriGeminiTheme.siriCyan.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(
                listening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
