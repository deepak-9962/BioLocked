import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/session/session_provider.dart';
import '../theme/web_app_theme.dart';

class SharedBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const SharedBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: const BoxDecoration(
        color: WebAppColors.background,
        border: Border(top: BorderSide(color: WebAppColors.border)),
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
    final color = isActive ? WebAppColors.cream : WebAppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? WebAppColors.surfaceStrong : Colors.transparent,
          border: Border.all(
            color: isActive ? WebAppColors.borderStrong : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
