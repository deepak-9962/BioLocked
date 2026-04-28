import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/session/session_provider.dart';
import '../theme/luxury_theme.dart';

class SharedBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const SharedBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xE609090B),
        border: Border(top: BorderSide(color: LuxuryColors.richBlack)), // slightly visible divider
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.timer,
            label: 'FOCUS',
            isActive: currentIndex == 0,
            onTap: () => ref.read(sessionStateProvider.notifier).setCheckIn(),
          ),
          _buildNavItem(
            icon: Icons.bar_chart,
            label: 'STATS',
            isActive: currentIndex == 1,
            onTap: () => ref.read(sessionStateProvider.notifier).setHistory(),
          ),
          _buildNavItem(
            icon: Icons.bedtime,
            label: 'SLEEP',
            isActive: currentIndex == 2,
            onTap: () => ref.read(sessionStateProvider.notifier).setRecoveryMode(),
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'ACCOUNT',
            isActive: currentIndex == 3,
            onTap: () => ref.read(sessionStateProvider.notifier).setAccountSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? LuxuryColors.platinumBlue : LuxuryColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? LuxuryColors.platinumBlue.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
