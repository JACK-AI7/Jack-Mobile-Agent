// lib/design/jack_components.dart
//
// Shared Atomic UI Primitives for JACK Agent
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../widgets/glass_nav_bar.dart';
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
  final VoidCallback? onTap;
  final Color? borderColor;

  const JackGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = JackRadii.card,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(JackSpacing.cardInternalPadding),
          decoration: BoxDecoration(
            color: JackColors.surfaceGlass.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? JackColors.surfaceBorderSubtle,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

/// Specialized alias for JackGlassContainer
typedef JackGlassCard = JackGlassContainer;

/// Universal List Card with leading widget, title, subtitle, and trailing action
class JackListCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const JackListCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JackGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: JackTypography.cardTitle(),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: JackTypography.cardSubtitle(),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Automation screen row card with icon, title, schedule and toggle
class JackAutomationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const JackAutomationCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return JackGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: JackTypography.cardTitle()),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: JackTypography.cardSubtitle(),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: Colors.white,
              activeTrackColor: JackColors.cyan,
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Task item card with real status indicator (checkmark or spinner)
class JackTaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final Color iconColor;
  final VoidCallback? onTap;

  const JackTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JackGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check_rounded, color: iconColor, size: 18)
                  : SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: JackTypography.cardTitle()),
                const SizedBox(height: 2),
                Text(subtitle, style: JackTypography.cardSubtitle()),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white30,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Real Brand Tool Card with SVG rendering for Google, GitHub, Notion, Slack, Gmail
class JackToolCard extends StatelessWidget {
  final String name;
  final String? svgAsset;
  final IconData? fallbackIcon;
  final Color? fallbackColor;
  final bool isConnected;
  final VoidCallback? onTap;

  const JackToolCard({
    super.key,
    required this.name,
    this.svgAsset,
    this.fallbackIcon,
    this.fallbackColor,
    required this.isConnected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JackGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF141322),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Center(
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset!,
                      width: 24,
                      height: 24,
                    )
                  : Icon(
                      fallbackIcon ?? Icons.extension_rounded,
                      color: fallbackColor ?? Colors.white,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: JackTypography.cardTitle()),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'Connected' : 'Connect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isConnected ? FontWeight.w400 : FontWeight.w600,
                    color: isConnected ? JackColors.emerald : JackColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white30,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Library Agent Card with vibrant glyph container
class JackAgentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const JackAgentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return JackGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: JackTypography.cardTitle()),
                const SizedBox(height: 2),
                Text(subtitle, style: JackTypography.cardSubtitle()),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white30,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Reusable Unified Bottom Navigation Component
typedef JackBottomNavigation = GlassNavBar;
