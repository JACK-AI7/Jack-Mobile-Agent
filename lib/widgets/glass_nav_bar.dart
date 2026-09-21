import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Floating pill-shaped glass navigation bar.
///
/// Sits at the bottom of the screen with [SafeArea] padding respected by the
/// parent scaffold.  Five icon-only tabs; the active tab shows the icon in
/// [AppColors.accentCyan] with a small glowing indicator dot beneath it.
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // ── Tab definitions ─────────────────────────────────────────────────────────

  static const List<_NavTab> _tabs = [
    _NavTab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavTab(
      icon: Icons.layers_outlined,
      activeIcon: Icons.layers_rounded,
      label: 'Library',
    ),
    _NavTab(
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
      label: 'Builder',
    ),
    _NavTab(
      icon: Icons.checklist_outlined,
      activeIcon: Icons.checklist_rounded,
      label: 'Tasks',
    ),
    _NavTab(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 24 px on left, right, and bottom; sits above the system nav area.
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        height: 72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                // Dark glass fill – slightly lighter than the deep background.
                color: AppColors.navBackground.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (i) {
                  return _NavItem(
                    tab: _tabs[i],
                    isActive: currentIndex == i,
                    onTap: () => onTap(i),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Internal widgets ─────────────────────────────────────────────────────────

/// Immutable data class describing one navigation tab.
class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label; // kept for semantics / accessibility

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Single tappable icon with animated active state and glow indicator dot.
class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tab.label,
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 56,
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon ───────────────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  key: ValueKey(isActive),
                  size: 26,
                  color: isActive ? AppColors.accentCyan : Colors.white38,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppColors.accentCyan.withValues(alpha: 0.55),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),

              const SizedBox(height: 6),

              // ── Active indicator dot ────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: isActive ? 5 : 0,
                height: isActive ? 5 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentCyan,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accentCyan.withValues(alpha: 0.80),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
