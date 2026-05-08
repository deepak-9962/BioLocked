import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/coins/coins_service.dart';
import '../features/session/session_provider.dart';
import '../features/stats/stats_service.dart';
import 'theme/web_app_theme.dart';
import 'widgets/shared_bottom_nav_bar.dart';

class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energyLevel = ref.watch(energyLevelProvider);
    final lockLevel = ref.watch(lockLevelProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final coinsAsync = ref.watch(coinBalanceProvider);

    return WebAppScaffold(
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 0),
      child: Column(
        children: [
          WebTopBar(
            trailing: IconButton(
              onPressed: () {
                ref.read(sessionStateProvider.notifier).setAccountSettings();
              },
              icon: const Icon(Icons.settings_outlined, color: WebAppColors.text),
              tooltip: 'Settings',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                const Text('ANDROID LOCK ENGINE + WEB DASHBOARD', style: WebAppText.eyebrow),
                const SizedBox(height: 14),
                const Text('Your focus command center', style: WebAppText.title),
                const SizedBox(height: 12),
                const Text(
                  'Start a locked Android session here. Your completed sessions sync to the web dashboard with the same account.',
                  style: WebAppText.body,
                ),
                const SizedBox(height: 24),
                statsAsync.when(
                  data: (stats) => _buildMetrics(stats, coinsAsync),
                  loading: () => _buildMetrics(UserStats(), coinsAsync),
                  error: (_, __) => _buildMetrics(UserStats(), coinsAsync),
                ),
                const SizedBox(height: 18),
                _EnergyCard(energyLevel: energyLevel),
                const SizedBox(height: 18),
                WebCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline, color: WebAppColors.blue),
                          const SizedBox(width: 10),
                          Text('${lockLevel.label} lock', style: WebAppText.sectionTitle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _lockDescription(lockLevel),
                        style: WebAppText.body,
                      ),
                      const SizedBox(height: 18),
                      WebPrimaryButton(
                        label: 'Enter tunnel',
                        icon: Icons.bolt,
                        onPressed: () {
                          ref.read(sessionStateProvider.notifier).setTunnelSetup();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.08,
                  children: [
                    _ActionCard(
                      icon: Icons.bar_chart,
                      title: 'History',
                      body: 'Review sessions and patterns.',
                      onTap: () => ref.read(sessionStateProvider.notifier).setHistory(),
                    ),
                    _ActionCard(
                      icon: Icons.spa_outlined,
                      title: 'Recovery',
                      body: 'Low-energy mode without strict lock.',
                      onTap: () => ref.read(sessionStateProvider.notifier).setRecoveryMode(),
                    ),
                    _ActionCard(
                      icon: Icons.done_all,
                      title: 'Micro-wins',
                      body: 'Protect momentum with small wins.',
                      onTap: () => ref.read(sessionStateProvider.notifier).setMicroWinsMode(),
                    ),
                    _ActionCard(
                      icon: Icons.person_outline,
                      title: 'Account',
                      body: 'Manage sync and defaults.',
                      onTap: () => ref.read(sessionStateProvider.notifier).setAccountSettings(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(UserStats stats, AsyncValue<int> coinsAsync) {
    final coins = coinsAsync.maybeWhen(data: (value) => value, orElse: () => 0);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        WebMetricTile(
          label: 'Focus hours',
          value: '${stats.totalMinutes ~/ 60}h',
          icon: Icons.timer_outlined,
        ),
        WebMetricTile(
          label: 'Streak',
          value: '${stats.currentStreak}d',
          icon: Icons.local_fire_department_outlined,
        ),
        WebMetricTile(
          label: 'Sessions',
          value: '${stats.totalSessions}',
          icon: Icons.check_circle_outline,
        ),
        WebMetricTile(
          label: 'Coins',
          value: '$coins',
          icon: Icons.toll_outlined,
        ),
      ],
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

    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Energy check-in', style: WebAppText.sectionTitle),
              Text(
                '$energyLevel%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: WebAppText.body),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: energyLevel / 100,
              backgroundColor: WebAppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                energyLevel < 40
                    ? WebAppColors.blue
                    : energyLevel < 70
                        ? WebAppColors.gold
                        : WebAppColors.green,
              ),
            ),
          ),
          Slider(
            value: energyLevel.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: WebAppColors.cream,
            inactiveColor: WebAppColors.border,
            onChanged: (value) {
              ref.read(energyLevelProvider.notifier).set(value.round());
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WebCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: WebAppColors.textMuted),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: WebAppColors.textMuted, fontSize: 12, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
