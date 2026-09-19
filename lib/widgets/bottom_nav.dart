// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'jack_orb.dart';

class JackBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const JackBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.explore_rounded, label: 'Explore'),
    _NavItem(icon: null, label: 'Jack'), // center orb
    _NavItem(icon: Icons.folder_rounded, label: 'Library'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        border: const Border(
          top: BorderSide(color: AppColors.navBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isCenter = i == 2;
              final isActive = i == currentIndex;

              if (isCenter) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Center(
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: JackOrb(
                          size: 52,
                          state: OrbState.idle,
                          onTap: () => onTap(i),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        width: 36,
                        height: 28,
                        decoration: isActive
                            ? BoxDecoration(
                                color: AppColors.accentCyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: isActive ? AppColors.navActive : AppColors.navInactive,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(item.label, style: AppTypography.navLabel(active: isActive)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData? icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
