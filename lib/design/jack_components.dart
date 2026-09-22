// lib/design/jack_components.dart
//
// Shared Atomic UI Primitives for JACK Agent
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'jack_colors.dart';
import 'jack_typography.dart';
import 'jack_radii.dart';
import 'jack_spacing.dart';

/// Top App Bar across secondary screens
class JackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final Widget? trailing;

  const JackAppBar({super.key, this.onBack, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
        onPressed: onBack ??
            () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
      ),
      centerTitle: true,
      title: Text('JACK AGENT', style: JackTypography.brandHeader()),
      actions: trailing != null ? [trailing!] : null,
    );
  }
}

/// Standard Segmented Filter Chip Row (e.g. [All] [Personal] [Work]...)
class JackSegmentedFilter extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const JackSegmentedFilter({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(i);
              },
              child: Container(
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? JackColors.cyan : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(JackRadii.chip),
                ),
                child: Center(
                  child: Text(
                    options[i],
                    style: JackTypography.chip(selected: active),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Glass card container with blur and subtle border
class JackGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const JackGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = JackRadii.card,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(JackSpacing.cardInternalPadding),
          decoration: BoxDecoration(
            color: JackColors.surfaceGlass.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: JackColors.surfaceBorderSubtle,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
