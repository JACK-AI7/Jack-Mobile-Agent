// lib/widgets/glass_nav_bar.dart
//
// Floating glass navigation bar matching 12-screen specification exactly:
// [Home] [Explore] [✻ Starburst] [Tasks] [Profile]
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

typedef JackBottomNavigationBar = GlassNavBar;

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isLibraryActive;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isLibraryActive = false,
  });

  static const List<_NavTab> _tabs = [
    _NavTab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavTab(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Tools',
    ),
    _NavTab(
      icon: Icons.auto_awesome, // Fallback, rendered with _StarburstIcon
      activeIcon: Icons.auto_awesome,
      label: '',
    ),
    _NavTab(
      icon: Icons.inbox_outlined,
      activeIcon: Icons.inbox_rounded,
      label: 'Tasks',
    ),
    _NavTab(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        height: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF100E1D).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (i) {
                  return _NavItem(
                    tab: _tabs[i],
                    isActive: currentIndex == i,
                    index: i,
                    isLibraryActive: isLibraryActive && i == 2,
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

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final int index;
  final bool isLibraryActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.index,
    this.isLibraryActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCenter = index == 2;

    if (isCenter && !isLibraryActive) {
      // 8-Ray Starburst center glyph matching reference image exactly
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 58,
          height: 64,
          child: Center(
            child: CustomPaint(
              size: const Size(28, 28),
              painter: _StarburstPainter(),
            ),
          ),
        ),
      );
    }

    final effectiveIcon = isLibraryActive ? Icons.grid_view_rounded : (isActive ? tab.activeIcon : tab.icon);
    final effectiveLabel = isLibraryActive ? 'Library' : tab.label;
    final bool hasLabel = effectiveLabel.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              effectiveIcon,
              size: 22,
              color: isActive ? AppColors.accentCyan : Colors.white54,
              shadows: isActive
                  ? [
                      Shadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.7),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            if (hasLabel) ...[
              const SizedBox(height: 3),
              Text(
                effectiveLabel,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.accentCyan : Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the 8-ray starburst center icon seen in the reference image
class _StarburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerR = size.width * 0.18;
    final outerR = size.width * 0.48;

    final rayPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..style = PaintingStyle.stroke;

    const numRays = 8;
    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * pi) / numRays;
      final start = Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle));
      final end = Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle));

      // Glow pass
      canvas.drawLine(start, end, glowPaint);
      // Crisp white core
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
