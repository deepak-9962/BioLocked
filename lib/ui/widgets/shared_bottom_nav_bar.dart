import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/session/session_provider.dart';
import '../theme/bio_theme.dart';

/// Bottom navigation bar matching the HTML reference design.
///
/// Rounded-top pill shape, shadow above, active item gets a filled circle
/// background with the lime primary color on the icon + label.
class SharedBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const SharedBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: BioColors.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.timer,
                label: 'Focus',
                isActive: currentIndex == 0,
                onTap: () => ref.read(sessionStateProvider.notifier).setCheckIn(),
              ),
              _NavItem(
                icon: Icons.bar_chart,
                label: 'Stats',
                isActive: currentIndex == 1,
                onTap: () => ref.read(sessionStateProvider.notifier).setHistory(),
              ),
              _NavItem(
                icon: Icons.bedtime,
                label: 'Sleep',
                isActive: currentIndex == 2,
                onTap: () => ref.read(sessionStateProvider.notifier).setRecoveryMode(),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Account',
                isActive: currentIndex == 3,
                onTap: () => ref.read(sessionStateProvider.notifier).setAccountSettings(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? BioColors.primaryFixed : BioColors.onSurfaceVariant;
    final opacity = isActive ? 1.0 : 0.6;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isActive ? BioColors.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: BioTextStyles.labelCaps.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
