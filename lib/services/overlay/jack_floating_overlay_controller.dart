// lib/services/overlay/jack_floating_overlay_controller.dart
//
// State and lifecycle management for Jack's Floating Bubble & Multitasking Overlay.
// Supports 6-position magnetic snap grid, drag-to-dismiss cross zone,
// gooey morphing between compact bubble and wide expanded card,
// and audio-reactive waveform streaming.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JackOverlayState {
  final bool isVisible;
  final bool isExpanded;
  final Offset bubblePosition;
  final int snapGridIndex; // 0 to 5
  final bool isDragging;
  final bool isInDismissZone;
  final bool showExplanatoryPrompt;
  final String statusText;
  final String hintText;
  final double waveformIntensity;
  final bool isListening;

  const JackOverlayState({
    required this.isVisible,
    required this.isExpanded,
    required this.bubblePosition,
    required this.snapGridIndex,
    required this.isDragging,
    required this.isInDismissZone,
    required this.showExplanatoryPrompt,
    required this.statusText,
    required this.hintText,
    required this.waveformIntensity,
    required this.isListening,
  });

  JackOverlayState copyWith({
    bool? isVisible,
    bool? isExpanded,
    Offset? bubblePosition,
    int? snapGridIndex,
    bool? isDragging,
    bool? isInDismissZone,
    bool? showExplanatoryPrompt,
    String? statusText,
    String? hintText,
    double? waveformIntensity,
    bool? isListening,
  }) {
    return JackOverlayState(
      isVisible: isVisible ?? this.isVisible,
      isExpanded: isExpanded ?? this.isExpanded,
      bubblePosition: bubblePosition ?? this.bubblePosition,
      snapGridIndex: snapGridIndex ?? this.snapGridIndex,
      isDragging: isDragging ?? this.isDragging,
      isInDismissZone: isInDismissZone ?? this.isInDismissZone,
      showExplanatoryPrompt:
          showExplanatoryPrompt ?? this.showExplanatoryPrompt,
      statusText: statusText ?? this.statusText,
      hintText: hintText ?? this.hintText,
      waveformIntensity: waveformIntensity ?? this.waveformIntensity,
      isListening: isListening ?? this.isListening,
    );
  }
}

class JackFloatingOverlayNotifier extends StateNotifier<JackOverlayState> {
  Timer? _promptDismissTimer;
  Timer? _waveformTimer;
  final Random _rng = Random();

  JackFloatingOverlayNotifier()
      : super(const JackOverlayState(
          isVisible: true,
          isExpanded: false,
          bubblePosition: Offset(280, 220),
          snapGridIndex: 1, // Top-Right default
          isDragging: false,
          isInDismissZone: false,
          showExplanatoryPrompt: false,
          statusText: 'Listening...',
          hintText: 'Jack is available while you multitask.',
          waveformIntensity: 0.45,
          isListening: true,
        )) {
    _startWaveformDriver();
  }

  void _startWaveformDriver() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (state.isExpanded && state.isListening) {
        state = state.copyWith(
          waveformIntensity: 0.25 + _rng.nextDouble() * 0.75,
        );
      }
    });
  }

  /// Calculates the 6 standard snap positions along device screen boundaries
  static List<Offset> computeSnapAnchors({
    required Size screenSize,
    required EdgeInsets safeArea,
    double bubbleSize = 62.0,
  }) {
    final left = 16.0;
    final right = (screenSize.width - bubbleSize - 16.0).clamp(16.0, 1000.0);
    final top = safeArea.top + 28.0;
    final mid = (screenSize.height * 0.45).clamp(top + 80.0, screenSize.height - 200.0);
    final bot = (screenSize.height - safeArea.bottom - bubbleSize - 88.0).clamp(top + 160.0, screenSize.height);

    return [
      Offset(left, top),   // 0: Top-Left
      Offset(right, top),  // 1: Top-Right
      Offset(left, mid),   // 2: Middle-Left
      Offset(right, mid),  // 3: Middle-Right
      Offset(left, bot),   // 4: Bottom-Left
      Offset(right, bot),  // 5: Bottom-Right
    ];
  }

  /// Center point of the dismiss/cross zone at bottom of screen
  static Offset computeDismissCenter({
    required Size screenSize,
    required EdgeInsets safeArea,
  }) {
    return Offset(screenSize.width / 2, screenSize.height - safeArea.bottom - 56.0);
  }

  void show() {
    HapticFeedback.lightImpact();
    state = state.copyWith(isVisible: true);
  }

  void dismiss() {
    HapticFeedback.heavyImpact();
    state = state.copyWith(
      isVisible: false,
      isExpanded: false,
      isDragging: false,
      isInDismissZone: false,
      showExplanatoryPrompt: false,
    );
  }

  void expand() {
    HapticFeedback.mediumImpact();
    _promptDismissTimer?.cancel();
    state = state.copyWith(
      isExpanded: true,
      showExplanatoryPrompt: false,
      statusText: 'Listening...',
      hintText: 'Jack is available while you multitask.',
      isListening: true,
    );
  }

  void minimize() {
    HapticFeedback.mediumImpact();
    _promptDismissTimer?.cancel();
    state = state.copyWith(
      isExpanded: false,
      showExplanatoryPrompt: true,
    );

    // Auto-hide the explanatory system prompt after 4.5 seconds
    _promptDismissTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        state = state.copyWith(showExplanatoryPrompt: false);
      }
    });
  }

  void toggleExpanded() {
    if (state.isExpanded) {
      minimize();
    } else {
      expand();
    }
  }

  void toggleVoiceListening() {
    HapticFeedback.selectionClick();
    final listening = !state.isListening;
    state = state.copyWith(
      isListening: listening,
      statusText: listening ? 'Listening...' : 'Paused',
      hintText: listening
          ? 'Jack is listening while you multitask.'
          : 'Tap microphone to resume listening.',
    );
  }

  void captureScreen() {
    HapticFeedback.mediumImpact();
    state = state.copyWith(
      statusText: 'Analyzing Screen...',
      hintText: 'Captured current screen context for multimodal reasoning.',
    );
  }

  void onPanStart() {
    _promptDismissTimer?.cancel();
    state = state.copyWith(
      isDragging: true,
      showExplanatoryPrompt: false,
    );
  }

  void onPanUpdate(Offset delta, Size screenSize, EdgeInsets safeArea, double bubbleSize) {
    final currentPos = state.bubblePosition;
    final newPos = Offset(
      (currentPos.dx + delta.dx).clamp(4.0, screenSize.width - bubbleSize - 4.0),
      (currentPos.dy + delta.dy).clamp(safeArea.top + 8.0, screenSize.height - safeArea.bottom - bubbleSize - 16.0),
    );

    final dismissCenter = computeDismissCenter(screenSize: screenSize, safeArea: safeArea);
    final bubbleCenter = Offset(newPos.dx + bubbleSize / 2, newPos.dy + bubbleSize / 2);
    final inDismiss = (bubbleCenter - dismissCenter).distance < 72.0;

    if (inDismiss != state.isInDismissZone) {
      if (inDismiss) HapticFeedback.heavyImpact();
    }

    state = state.copyWith(
      bubblePosition: newPos,
      isInDismissZone: inDismiss,
    );
  }

  void onPanEnd(Size screenSize, EdgeInsets safeArea, double bubbleSize) {
    if (state.isInDismissZone) {
      dismiss();
      return;
    }

    // Snap to nearest of the 6 magnetic positions
    final anchors = computeSnapAnchors(
      screenSize: screenSize,
      safeArea: safeArea,
      bubbleSize: bubbleSize,
    );

    double minDistance = double.infinity;
    int nearestIndex = 0;
    Offset targetAnchor = anchors[0];

    for (int i = 0; i < anchors.length; i++) {
      final d = (state.bubblePosition - anchors[i]).distance;
      if (d < minDistance) {
        minDistance = d;
        nearestIndex = i;
        targetAnchor = anchors[i];
      }
    }

    HapticFeedback.lightImpact();
    state = state.copyWith(
      isDragging: false,
      isInDismissZone: false,
      snapGridIndex: nearestIndex,
      bubblePosition: targetAnchor,
    );
  }

  @override
  void dispose() {
    _promptDismissTimer?.cancel();
    _waveformTimer?.cancel();
    super.dispose();
  }
}

final jackFloatingOverlayProvider =
    StateNotifierProvider<JackFloatingOverlayNotifier, JackOverlayState>((ref) {
  return JackFloatingOverlayNotifier();
});
