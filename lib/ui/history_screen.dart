import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/stats/stats_service.dart';
import '../features/session/session_provider.dart';
import 'widgets/heatmap_widget.dart';
import 'widgets/shared_bottom_nav_bar.dart';
import 'theme/bio_theme.dart';

final sessionHistoryProvider = FutureProvider<List<SessionRecord>>((ref) async {
  return ref.read(statsServiceProvider).getSessionHistory();
});

final dailyMinutesProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  return ref.read(statsServiceProvider).getDailyMinutes(days: 35);
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsProvider);
    final historyAsync = ref.watch(sessionHistoryProvider);


    return Scaffold(
      backgroundColor: BioColors.background,
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 1),
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
                children: [
                  GestureDetector(
                    onTap: () => ref.read(sessionStateProvider.notifier).setCheckIn(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BioColors.surfaceContainerHigh,
                        border: Border.all(color: BioColors.outlineVariant),
                      ),
                      child: const Icon(Icons.arrow_back, color: BioColors.onSurface, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'FOCUS HISTORY',
                        style: BioTextStyles.headlineLg.copyWith(
                          letterSpacing: 6.4,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Spacer for centering
                ],
              ),
            ),
            // ── Scrollable content ─────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: BioColors.primaryFixed,
                backgroundColor: BioColors.surfaceContainer,
                onRefresh: () async {
                  ref.invalidate(userStatsProvider);
                  ref.invalidate(sessionHistoryProvider);
                  ref.invalidate(weeklyAnalyticsProvider);
                  ref.invalidate(dailyMinutesProvider);
                  ref.invalidate(distractionHeatmapProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: BioSpacing.marginMain),
                  children: [
                    const SizedBox(height: 16),
                    // ── Stats Summary Card (Bento Grid) ─────────────────
                    statsAsync.when(
                      data: (stats) => _buildStatsSummary(stats),
                      loading: () => _buildStatsSummary(UserStats()),
                      error: (_, __) => _buildStatsSummary(UserStats()),
                    ),
                    const SizedBox(height: BioSpacing.stackGap),
                    // ── Distraction Heatmap ──────────────────────────────
                    Text(
                      'DISTRACTION HEATMAP',
                      style: BioTextStyles.labelCaps.copyWith(
                        color: BioColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final heatmapAsync = ref.watch(distractionHeatmapProvider);
                        return heatmapAsync.when(
                          data: (data) => DistractionHeatmapWidget(data: data),
                          loading: () => _buildLoadingCard(height: 230),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                    const SizedBox(height: BioSpacing.stackGap),
                    // ── Recent Sessions ──────────────────────────────────
                    Text(
                      'RECENT SESSIONS',
                      style: BioTextStyles.labelCaps.copyWith(
                        color: BioColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    historyAsync.when(
                      data: (sessions) => _buildSessionsList(sessions),
                      loading: () => _buildLoadingCard(height: 200),
                      error: (_, __) => _buildEmptyState(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Summary Card (Bento Grid) ────────────────────────────────────────

  Widget _buildStatsSummary(UserStats stats) {
    final totalHours = stats.totalMinutes ~/ 60;
    final totalMins = stats.totalMinutes % 60;

    return Container(
      decoration: BoxDecoration(
        color: BioColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BioColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top row: Current Streak | Best Streak
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _BentoCell(
                    icon: Icons.local_fire_department,
                    iconColor: BioColors.orange500,
                    value: '${stats.currentStreak}',
                    valueColor: BioColors.orange500,
                    label: 'Current Streak',
                  ),
                ),
                Container(width: 1, color: BioColors.outlineVariant.withValues(alpha: 0.2)),
                Expanded(
                  child: _BentoCell(
                    icon: Icons.emoji_events,
                    iconColor: BioColors.green500,
                    value: '${stats.longestStreak}',
                    valueColor: BioColors.green500,
                    label: 'Best Streak',
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: BioColors.outlineVariant.withValues(alpha: 0.2)),
          // Bottom row: Total Focus | Sessions
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _BentoCell(
                    icon: Icons.schedule,
                    iconColor: BioColors.blue400,
                    value: '${totalHours}h ${totalMins}m',
                    valueColor: BioColors.blue400,
                    label: 'Total Focus',
                  ),
                ),
                Container(width: 1, color: BioColors.outlineVariant.withValues(alpha: 0.2)),
                Expanded(
                  child: _BentoCell(
                    icon: Icons.check_circle,
                    iconColor: BioColors.purple500,
                    value: '${stats.totalSessions}',
                    valueColor: BioColors.purple500,
                    label: 'Sessions',
                    iconFilled: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Session List ──────────────────────────────────────────────────────────

  Widget _buildSessionsList(List<SessionRecord> sessions) {
    final recent = sessions.reversed.take(20).toList();
    if (recent.isEmpty) return _buildEmptyState();

    return Column(
      children: recent.map((session) => _buildSessionItem(session)).toList(),
    );
  }

  Widget _buildSessionItem(SessionRecord session) {
    final title = session.taskName.isNotEmpty ? session.taskName : 'Focus Session';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BioColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BioColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Status circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: session.wasSuccessful
                  ? const Color(0xFF11261A)
                  : const Color(0xFF261111),
              border: Border.all(
                color: session.wasSuccessful
                    ? const Color(0xFF1B3A27)
                    : const Color(0xFF3A1B1B),
              ),
            ),
            child: Icon(
              session.wasSuccessful ? Icons.check : Icons.close,
              color: session.wasSuccessful ? BioColors.green500 : BioColors.red500,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Session info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: BioTextStyles.headlineLg.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BioColors.onBackground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(session.completedAt),
                  style: BioTextStyles.bodyMd.copyWith(
                    fontSize: 14,
                    color: BioColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Duration & energy
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${session.durationMinutes}m',
                style: BioTextStyles.headlineLg.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BioColors.blue400,
                ),
              ),
              if (session.energyLevel > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 12, color: BioColors.yellow500),
                    const SizedBox(width: 4),
                    Text(
                      '${session.energyLevel}%',
                      style: BioTextStyles.bodyMd.copyWith(
                        fontSize: 12,
                        color: BioColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: BioColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BioColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: BioColors.primaryFixed, strokeWidth: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: BioColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BioColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 32, color: BioColors.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'No sessions yet',
            style: BioTextStyles.headlineLg.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first focus lock and your stats will start forming here.',
            textAlign: TextAlign.center,
            style: BioTextStyles.bodyMd.copyWith(
              fontSize: 14,
              color: BioColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    String dayStr;
    if (date == today) {
      dayStr = 'Today';
    } else if (date == today.subtract(const Duration(days: 1))) {
      dayStr = 'Yesterday';
    } else {
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      dayStr = '${months[dt.month - 1]} ${dt.day}';
    }

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$dayStr at $hour:$minute $ampm';
  }
}

// ─── Bento Cell Widget ──────────────────────────────────────────────────────

class _BentoCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
  final bool iconFilled;

  const _BentoCell({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
    this.iconFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: BioColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: BioTextStyles.headlineLg.copyWith(
                color: valueColor,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: BioTextStyles.labelCaps.copyWith(
              color: BioColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
