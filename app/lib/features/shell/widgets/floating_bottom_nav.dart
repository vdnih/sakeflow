import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onFabTap;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 83,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 12,
            right: 12,
            height: 60,
            child: _buildPill(),
          ),
          Positioned(
            bottom: 10,
            child: _buildFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: kSurface2.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: kBorderDefault),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 32,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'ホーム',
                index: 0,
                current: currentIndex,
                onTap: onTabChanged,
              ),
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'マップ',
                index: 1,
                current: currentIndex,
                onTap: onTabChanged,
              ),
              const SizedBox(width: 52),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: '分析',
                index: 2,
                current: currentIndex,
                onTap: onTabChanged,
              ),
              _NavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'コレクション',
                index: 3,
                current: currentIndex,
                onTap: onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: onFabTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: kAccentMain,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kAccentGlow,
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt, color: Colors.black, size: 22),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 22,
              color: active ? kAccentMain : kTextMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: active ? kAccentMain : kTextMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
