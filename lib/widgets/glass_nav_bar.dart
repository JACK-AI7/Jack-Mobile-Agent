import 'dart:ui';
import 'package:flutter/material.dart';

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151515).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home_filled, 0),
                _buildNavItem(Icons.explore_outlined, Icons.explore, 1),
                _buildNavItem(Icons.star_border, Icons.star, 2, isSpecial: true),
                _buildNavItem(Icons.task_outlined, Icons.task, 3),
                _buildNavItem(Icons.person_outline, Icons.person, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outline, IconData filled, int index, {bool isSpecial = false}) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF2B6BFF) : Colors.white54;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFF2B6BFF).withValues(alpha: 0.2) : Colors.transparent,
          boxShadow: isSelected && isSpecial
              ? [
                  BoxShadow(
                    color: const Color(0xFF2B6BFF).withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Icon(
          isSelected ? filled : outline,
          color: color,
          size: isSpecial ? 32 : 28,
        ),
      ),
    );
  }
}
