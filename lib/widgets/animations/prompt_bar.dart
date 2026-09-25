// lib/widgets/animations/prompt_bar.dart
//
// React Bits <PromptBar /> faithful Flutter implementation.
// AI Command Bar with multiline auto-expand, @ sources menu, / slash commands,
// model picker, effort slider with Max-effort particle sparks canvas,
// dictation hook with embedded VoicePill, and morphing send/stop button.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PromptSource {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final bool attach;

  const PromptSource({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    this.attach = false,
  });
}

class PromptCommand {
  final String key;
  final String name;
  final String description;

  const PromptCommand({
    required this.key,
    required this.name,
    required this.description,
  });
}

class PromptModel {
  final String key;
  final String name;
  final String tag;

  const PromptModel({
    required this.key,
    required this.name,
    required this.tag,
  });
}

const List<PromptSource> defaultPromptSources = [
  PromptSource(
    key: 'files',
    name: 'Photos & files',
    description: 'Upload from this device',
    icon: Icons.attach_file_rounded,
    attach: true,
  ),
  PromptSource(
    key: 'web',
    name: 'Web search',
    description: 'Live Google results',
    icon: Icons.public_rounded,
  ),
  PromptSource(
    key: 'sales',
    name: 'Deals & shopping',
    description: 'Live price tracking',
    icon: Icons.trending_up_rounded,
  ),
  PromptSource(
    key: 'docs',
    name: 'Documents',
    description: 'Specs, notes & briefs',
    icon: Icons.description_outlined,
  ),
  PromptSource(
    key: 'mail',
    name: 'Mail',
    description: 'Read and draft messages',
    icon: Icons.mail_outline_rounded,
  ),
  PromptSource(
    key: 'calendar',
    name: 'Calendar',
    description: 'Events & schedule',
    icon: Icons.calendar_today_rounded,
  ),
];

const List<PromptCommand> defaultPromptCommands = [
  PromptCommand(
    key: 'summarize',
    name: '/summarize',
    description: 'Digest the thread so far',
  ),
  PromptCommand(
    key: 'compare',
    name: '/compare',
    description: 'Two options side by side',
  ),
  PromptCommand(
    key: 'draft',
    name: '/draft',
    description: 'Write a first version',
  ),
  PromptCommand(
    key: 'explain',
    name: '/explain',
    description: 'A plain-language walkthrough',
  ),
  PromptCommand(
    key: 'tasks',
    name: '/tasks',
    description: 'Turn this into an actionable plan',
  ),
];

const List<PromptModel> defaultPromptModels = [
  PromptModel(key: 'groq-llama-3.3-70b', name: 'Llama 3.3 70B', tag: 'Ultra-Fast'),
  PromptModel(key: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro', tag: 'Flagship'),
  PromptModel(key: 'jack-autonomous', name: 'Jack Multi-Agent', tag: 'Autonomous'),
];

const List<String> defaultPromptEfforts = [
  'Low',
  'Medium',
  'High',
  'Extra',
  'Max'
];

class PromptBar extends StatefulWidget {
  final String placeholder;
  final List<PromptSource> sources;
  final List<PromptCommand> commands;
  final List<PromptModel> models;
  final String? defaultModelKey;
  final List<String> efforts;
  final String defaultEffort;
  final ValueChanged<String>? onEffortChange;
  final bool busy;
  final void Function(
    String text, {
    List<String>? attachments,
    PromptModel? model,
    String? effort,
  })? onSend;
  final VoidCallback? onStop;
  final Future<List<String>?> Function()? onAttach;
  final Future<String?> Function()? onDictate;
  final Color background;
  final Color color;
  final Color menuBackground;
  final Color sparkColor;
  final double radius;
  final int maxRows;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const PromptBar({
    super.key,
    this.placeholder = 'Ask anything...',
    this.sources = defaultPromptSources,
    this.commands = defaultPromptCommands,
    this.models = defaultPromptModels,
    this.defaultModelKey,
    this.efforts = defaultPromptEfforts,
    this.defaultEffort = 'High',
    this.onEffortChange,
    this.busy = false,
    this.onSend,
    this.onStop,
    this.onAttach,
    this.onDictate,
    this.background = const Color(0xFF141320),
    this.color = const Color(0xFFF5F5F5),
    this.menuBackground = const Color(0xFF1E1C2E),
    this.sparkColor = const Color(0xFFB39DFF),
    this.radius = 20.0,
    this.maxRows = 5,
    this.controller,
    this.focusNode,
  });

  @override
  State<PromptBar> createState() => _PromptBarState();
}

class _PromptBarState extends State<PromptBar> with TickerProviderStateMixin {
  late TextEditingController _textCtrl;
  late FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  final List<String> _attachments = [];
  late PromptModel _selectedModel;
  late int _effortIndex;

  bool _isMenuOpen = false;
  String _menuKind = 'sources'; // 'sources', 'commands'
  String _filterQuery = '';

  // Sparks particle controller (for Max effort)
  late AnimationController _sparksController;
  final List<_SparkParticle> _sparks = [];
  double _typingEnergy = 0.0;

  @override
  void initState() {
    super.initState();

    _textCtrl = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;

    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;

    _selectedModel = widget.models.firstWhere(
      (m) => m.key == widget.defaultModelKey,
      orElse: () => widget.models.first,
    );

    _effortIndex = widget.efforts.indexOf(widget.defaultEffort);
    if (_effortIndex < 0) _effortIndex = (widget.efforts.length / 2).floor();

    _textCtrl.addListener(_onTextChanged);

    _sparksController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_onSparkTick);

    if (_isMaxEffort) {
      _initSparks();
      _sparksController.repeat();
    }
  }

  bool get _isMaxEffort => _effortIndex == widget.efforts.length - 1;

  void _initSparks() {
    _sparks.clear();
    final rand = math.Random();
    for (int i = 0; i < 28; i++) {
      _sparks.add(_SparkParticle(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        radius: 0.9 + rand.nextDouble() * 1.5,
        speedY: 0.002 + rand.nextDouble() * 0.004,
        sway: (rand.nextDouble() - 0.5) * 0.02,
        phase: rand.nextDouble() * math.pi * 2,
        life: rand.nextDouble(),
      ));
    }
  }

  void _onSparkTick() {
    if (!_isMaxEffort) return;

    _typingEnergy *= 0.94;
    for (final p in _sparks) {
      p.y -= p.speedY * (1.0 + _typingEnergy * 2.5);
      p.life += 0.012;
      if (p.y < 0.0 || p.life > 1.0) {
        p.y = 1.0;
        p.x = math.Random().nextDouble();
        p.life = 0.0;
      }
    }
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    final text = _textCtrl.text;
    _typingEnergy = math.min(1.5, _typingEnergy + 0.18);

    // Auto popup trigger for @ or /
    final lastWord = text.split(' ').last;
    if (lastWord.startsWith('@')) {
      setState(() {
        _isMenuOpen = true;
        _menuKind = 'sources';
        _filterQuery = lastWord.substring(1).toLowerCase();
      });
    } else if (lastWord.startsWith('/')) {
      setState(() {
        _isMenuOpen = true;
        _menuKind = 'commands';
        _filterQuery = lastWord.substring(1).toLowerCase();
      });
    } else {
      if (_isMenuOpen) {
        setState(() => _isMenuOpen = false);
      }
    }
  }

  @override
  void dispose() {
    _sparksController.dispose();
    _textCtrl.removeListener(_onTextChanged);
    if (_ownsController) _textCtrl.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    HapticFeedback.lightImpact();
    widget.onSend?.call(
      text,
      attachments: List.from(_attachments),
      model: _selectedModel,
      effort: widget.efforts[_effortIndex],
    );

    _textCtrl.clear();
    setState(() {
      _attachments.clear();
      _isMenuOpen = false;
    });
  }

  void _pickSource(PromptSource source) {
    HapticFeedback.selectionClick();
    if (source.attach) {
      widget.onAttach?.call().then((files) {
        if (files != null && files.isNotEmpty && mounted) {
          setState(() {
            _attachments.addAll(files);
            _isMenuOpen = false;
          });
        }
      });
      return;
    }

    final cur = _textCtrl.text;
    final atIndex = cur.lastIndexOf('@');
    final prefix = atIndex >= 0 ? cur.substring(0, atIndex) : cur;
    _textCtrl.text = '$prefix@${source.name} ';
    _textCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _textCtrl.text.length),
    );
    setState(() => _isMenuOpen = false);
    _focusNode.requestFocus();
  }

  void _pickCommand(PromptCommand cmd) {
    HapticFeedback.selectionClick();
    final cur = _textCtrl.text;
    final slashIndex = cur.lastIndexOf('/');
    final prefix = slashIndex >= 0 ? cur.substring(0, slashIndex) : cur;
    _textCtrl.text = '$prefix${cmd.name} ';
    _textCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _textCtrl.text.length),
    );
    setState(() => _isMenuOpen = false);
    _focusNode.requestFocus();
  }

  void _showModelPicker() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.menuBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select Model',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.models.map((m) {
                  final isSelected = m.key == _selectedModel.key;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      m.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      m.tag,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00E5FF),
                        fontSize: 11.5,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFF00E5FF), size: 20)
                        : null,
                    onTap: () {
                      setState(() => _selectedModel = m);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEffortSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.menuBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final curLevel = widget.efforts[_effortIndex];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reasoning Effort',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            curLevel,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Higher effort gives the multi-agent network more thinking loops and tool calls before answering.',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Faster',
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 11.5)),
                        Text('Smarter',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF00E5FF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF00E5FF),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: Colors.white,
                        overlayColor:
                            const Color(0xFF00E5FF).withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _effortIndex.toDouble(),
                        min: 0,
                        max: (widget.efforts.length - 1).toDouble(),
                        divisions: widget.efforts.length - 1,
                        onChanged: (val) {
                          final idx = val.round();
                          setSheetState(() => _effortIndex = idx);
                          setState(() {
                            _effortIndex = idx;
                            if (_isMaxEffort) {
                              _initSparks();
                              _sparksController.repeat();
                            } else {
                              _sparksController.stop();
                            }
                          });
                          widget.onEffortChange?.call(widget.efforts[idx]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _textCtrl.text.trim().isNotEmpty || _attachments.isNotEmpty;
    final armed = widget.busy || canSend;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Autocomplete / Context Popup Menu ─────────────────────────────
        if (_isMenuOpen)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: widget.menuBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: _menuKind == 'sources'
                    ? widget.sources
                        .where((s) =>
                            s.name.toLowerCase().contains(_filterQuery))
                        .map((s) => ListTile(
                              dense: true,
                              leading: Icon(s.icon,
                                  color: const Color(0xFF00E5FF), size: 18),
                              title: Text(
                                s.name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                s.description,
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () => _pickSource(s),
                            ))
                        .toList()
                    : widget.commands
                        .where((c) =>
                            c.name.toLowerCase().contains(_filterQuery))
                        .map((c) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.flash_on_rounded,
                                  color: Color(0xFFFBBF24), size: 18),
                              title: Text(
                                c.name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                c.description,
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () => _pickCommand(c),
                            ))
                        .toList(),
              ),
            ),
          ),

        // ── Main Command Bar Container ────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: _isMaxEffort
                  ? widget.sparkColor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.12),
              width: _isMaxEffort ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (_isMaxEffort)
                BoxShadow(
                  color: widget.sparkColor.withValues(alpha: 0.14),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Canvas for sparks if Max effort
              if (_isMaxEffort)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.radius),
                    child: CustomPaint(
                      painter: _SparksPainter(
                        sparks: _sparks,
                        sparkColor: widget.sparkColor,
                        energy: _typingEnergy,
                      ),
                    ),
                  ),
                ),

              // Content Layout
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Attachments Chips
                    if (_attachments.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _attachments.map((file) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file_rounded,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  file.split('/').last,
                                  style: GoogleFonts.inter(
                                      color: Colors.white, fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _attachments.remove(file));
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      size: 13, color: Colors.white54),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Auto-expanding Multiline Text Input
                    TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      style: GoogleFonts.inter(
                        color: widget.color,
                        fontSize: 15.0,
                        height: 1.35,
                      ),
                      maxLines: widget.maxRows,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        hintText: widget.placeholder,
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 15.0,
                        ),
                        border: InputBorder.none,
                      ),
                      cursorColor: const Color(0xFF00E5FF),
                    ),

                    const SizedBox(height: 10),

                    // Controls Row: Tools (+), Model Chip, Effort Chip, VoicePill, Send
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Scrollable Left Actions (NEVER overflows on narrow screens or keyboard)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tool Menu Toggle (+)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _isMenuOpen = !_isMenuOpen;
                                      _menuKind = 'sources';
                                      _filterQuery = '';
                                    });
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                    child: const Icon(Icons.add_rounded,
                                        size: 20, color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Model Selector Chip
                                GestureDetector(
                                  onTap: _showModelPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _selectedModel.name,
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.arrow_drop_down_rounded,
                                            size: 16, color: Colors.white38),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Effort Selector Chip
                                GestureDetector(
                                  onTap: _showEffortSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _isMaxEffort
                                          ? widget.sparkColor.withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: _isMaxEffort
                                          ? Border.all(
                                              color: widget.sparkColor.withValues(alpha: 0.5),
                                              width: 0.8,
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 12,
                                          color: _isMaxEffort
                                              ? widget.sparkColor
                                              : Colors.white60,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.efforts[_effortIndex],
                                          style: GoogleFonts.inter(
                                            color: _isMaxEffort
                                                ? widget.sparkColor
                                                : Colors.white70,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Dedicated Glowing Mic Button for Instant Voice Dictation
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.onDictate?.call();
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E2640), Color(0xFF131728)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.mic_rounded,
                                color: Color(0xFF00E5FF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Morphing Send / Stop Button
                        GestureDetector(
                          onTap: () {
                            if (widget.busy) {
                              widget.onStop?.call();
                            } else {
                              _handleSend();
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: armed
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: armed
                                    ? const Color(0xFF00E5FF)
                                    : Colors.white.withValues(alpha: 0.14),
                                width: 1.0,
                              ),
                              boxShadow: armed
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: widget.busy
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: armed ? Colors.black : Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.arrow_upward_rounded,
                                    color: armed ? Colors.black : Colors.white54,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparkParticle {
  double x;
  double y;
  double radius;
  double speedY;
  double sway;
  double phase;
  double life;

  _SparkParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedY,
    required this.sway,
    required this.phase,
    required this.life,
  });
}

class _SparksPainter extends CustomPainter {
  final List<_SparkParticle> sparks;
  final Color sparkColor;
  final double energy;

  _SparksPainter({
    required this.sparks,
    required this.sparkColor,
    required this.energy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in sparks) {
      final px = p.x * size.width + math.sin(p.life * math.pi * 4 + p.phase) * (p.sway * size.width);
      final py = p.y * size.height;
      final alpha = math.sin(p.life * math.pi).clamp(0.0, 1.0) * (0.6 + energy * 0.4);

      paint.color = sparkColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), p.radius * (1.0 + energy * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(_SparksPainter oldDelegate) => true;
}
