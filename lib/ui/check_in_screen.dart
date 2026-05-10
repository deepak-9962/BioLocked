import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/coins/coins_service.dart';
import '../features/session/session_provider.dart';
import '../features/stats/stats_service.dart';
import 'theme/bio_theme.dart';
import 'widgets/shared_bottom_nav_bar.dart';

class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energyLevel = ref.watch(energyLevelProvider);
    final lockLevel = ref.watch(lockLevelProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final coinsAsync = ref.watch(coinBalanceProvider);

    return Scaffold(
      backgroundColor: BioColors.background,
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            // ── TopAppBar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BioSpacing.marginMain,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: BioColors.onSurface, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'BIO-LOCKED',
                        style: BioTextStyles.headlineLg.copyWith(
                          letterSpacing: 6.4, // 0.2em
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => ref.read(sessionStateProvider.notifier).setAccountSettings(),
                    child: Icon(Icons.settings, color: BioColors.onSurfaceVariant, size: 24),
                  ),
                ],
              ),
            ),
            // ── Scrollable content ─────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: BioSpacing.marginMain),
                children: [
                  // ── Hero Section ──────────────────────────────────────
                  const SizedBox(height: 16),
                  Text(
                    'ANDROID LOCK ENGINE + WEB DASHBOARD',
                    style: BioTextStyles.labelCaps.copyWith(
                      color: BioColors.primaryFixed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your focus command center',
                    style: BioTextStyles.headlineXl,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start a locked Android session here. Your completed sessions sync to the web dashboard with the same account.',
                    style: BioTextStyles.bodyMd.copyWith(
                      color: BioColors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Daily Focus Goal ──────────────────────────────────
                  statsAsync.when(
                    data: (stats) => _buildDailyGoal(stats),
                    loading: () => _buildDailyGoal(UserStats()),
                    error: (_, __) => _buildDailyGoal(UserStats()),
                  ),
                  const SizedBox(height: BioSpacing.stackGap),
                  // ── Stats Grid ────────────────────────────────────────
                  statsAsync.when(
                    data: (stats) => _buildStatsGrid(stats, coinsAsync),
                    loading: () => _buildStatsGrid(UserStats(), coinsAsync),
                    error: (_, __) => _buildStatsGrid(UserStats(), coinsAsync),
                  ),
                  const SizedBox(height: BioSpacing.stackGap),
                  // ── Energy Check-in ───────────────────────────────────
                  _EnergyCard(energyLevel: energyLevel),
                  const SizedBox(height: BioSpacing.gutterCard),
                  // ── Standard Lock Start ───────────────────────────────
                  _LockStartCard(lockLevel: lockLevel),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoal(UserStats stats) {
    // Calculate daily goal percentage (target: 120min)
    const targetMinutes = 120;
    final todayMinutes = stats.totalMinutes;
    final percentage = ((todayMinutes / targetMinutes) * 100).clamp(0, 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BioDecorations.cardBg(borderRadius: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Daily Focus Goal',
                style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurface),
              ),
              Text(
                '$percentage%',
                style: BioTextStyles.statDisplay.copyWith(
                  fontSize: 32,
                  height: 36 / 32,
                  color: BioColors.primaryFixed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: BioColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(BioColors.primaryFixed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserStats stats, AsyncValue<int> coinsAsync) {
    final coins = coinsAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    final hours = stats.totalMinutes ~/ 60;
    final remaining = stats.totalMinutes % 60;
    final focusDisplay = remaining > 0 ? '$hours.${(remaining * 10 ~/ 60)}h' : '${hours}h';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: BioSpacing.gutterCard,
      mainAxisSpacing: BioSpacing.gutterCard,
      childAspectRatio: 0.95,
      children: [
        _StatCard(icon: Icons.timer_outlined, value: focusDisplay, label: 'Focus hours'),
        _StatCard(icon: Icons.local_fire_department_outlined, value: '${stats.currentStreak}d', label: 'Streak'),
        _StatCard(icon: Icons.check_circle_outline, value: '${stats.totalSessions}', label: 'Sessions'),
        _StatCard(icon: Icons.toll_outlined, value: '$coins', label: 'Coins'),
      ],
    );
  }

}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BioDecorations.cardBg(borderRadius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: BioColors.onSurfaceVariant, size: 24),
          const Spacer(),
          Text(
            value,
            style: BioTextStyles.statDisplay.copyWith(fontSize: 48),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Energy Card ──────────────────────────────────────────────────────────────

class _EnergyCard extends ConsumerWidget {
  final int energyLevel;

  const _EnergyCard({required this.energyLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = switch (energyLevel) {
      >= 80 => 'Peak focus',
      >= 60 => 'Ready for focus',
      >= 40 => 'Moderate energy',
      >= 20 => 'Low energy',
      _ => 'Rest recommended',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BioDecorations.cardBg(borderRadius: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Energy check-in',
                      style: BioTextStyles.headlineLg.copyWith(fontSize: 24, height: 32 / 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '$energyLevel%',
                style: BioTextStyles.statDisplay.copyWith(fontSize: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.battery_1_bar, color: BioColors.onSurfaceVariant, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: BioColors.primaryFixed,
                    inactiveTrackColor: BioColors.cardBorder,
                    thumbColor: BioColors.primaryFixed,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: energyLevel.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      ref.read(energyLevelProvider.notifier).set(value.round());
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.battery_charging_full, color: BioColors.primaryFixed, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Lock Start Card ──────────────────────────────────────────────────────────

class _LockStartCard extends ConsumerWidget {
  final SessionLockLevel lockLevel;

  const _LockStartCard({required this.lockLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BioDecorations.innerBg(
        borderRadius: 8,
        borderColor: BioColors.primaryFixed.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: BioColors.primaryFixed, size: 24),
              const SizedBox(width: 8),
              Text(
                '${lockLevel.label} lock',
                style: BioTextStyles.headlineLg.copyWith(fontSize: 24, height: 32 / 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _lockDescription(lockLevel),
            style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ref.read(sessionStateProvider.notifier).setTunnelSetup(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BioColors.primaryFixed,
                foregroundColor: BioColors.onPrimaryFixed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                textStyle: BioTextStyles.headlineLg.copyWith(fontSize: 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt, size: 24, color: BioColors.onPrimaryFixed),
                  const SizedBox(width: 8),
                  Text(
                    'Enter tunnel',
                    style: BioTextStyles.headlineLg.copyWith(
                      fontSize: 20,
                      color: BioColors.onPrimaryFixed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lockDescription(SessionLockLevel lockLevel) {
    switch (lockLevel) {
      case SessionLockLevel.soft:
        return 'Flexible lock with more grace and emergency breaks.';
      case SessionLockLevel.standard:
        return 'Balanced enforcement with overlay, kiosk mode, and one daily emergency break.';
      case SessionLockLevel.hard:
        return 'Strictest mode. Short grace window and no emergency breaks.';
    }
  }
}
