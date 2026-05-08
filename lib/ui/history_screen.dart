import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import '../features/stats/stats_service.dart';
import '../features/session/session_provider.dart';
import 'widgets/heatmap_widget.dart';
import 'widgets/shared_bottom_nav_bar.dart';
import 'theme/luxury_theme.dart';

final sessionHistoryProvider = FutureProvider<List<SessionRecord>>((ref) async {
  return ref.read(statsServiceProvider).getSessionHistory();
});

final dailyMinutesProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  return ref.read(statsServiceProvider).getDailyMinutes(days: 35);
});

enum _SessionFilter { all, successful, failed, highEnergy, intenseLock }

enum _StatsView { list, calendar }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const int _dailyGoalMinutes = 120;
  static const int _weeklyGoalMinutes = 600;

  _SessionFilter _filter = _SessionFilter.all;
  _StatsView _view = _StatsView.list;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsProvider);
    final historyAsync = ref.watch(sessionHistoryProvider);
    final weeklyAnalyticsAsync = ref.watch(weeklyAnalyticsProvider);
    final dailyMinutesAsync = ref.watch(dailyMinutesProvider);

    return Scaffold(
      backgroundColor: LuxuryColors.richBlack,
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 1),
      body: Container(
        decoration: BoxDecoration(gradient: LuxuryGradients.darkBackground),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: RefreshIndicator(
                  color: LuxuryColors.platinumBlue,
                  backgroundColor: LuxuryColors.elevatedSurface,
                  onRefresh: () async {
                    ref.invalidate(userStatsProvider);
                    ref.invalidate(sessionHistoryProvider);
                    ref.invalidate(weeklyAnalyticsProvider);
                    ref.invalidate(dailyMinutesProvider);
                    ref.invalidate(distractionHeatmapProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        statsAsync.when(
                          data: (stats) => _buildFocusCommand(stats),
                          loading: () => _buildLoadingCard(height: 178),
                          error: (_, __) => _buildErrorCard(
                            'Stats are taking a breath. Pull to retry.',
                          ),
                        ),
                        const SizedBox(height: 18),
                        dailyMinutesAsync.when(
                          data: (dailyMinutes) => weeklyAnalyticsAsync.when(
                            data: (analytics) => _buildGoalProgress(
                              dailyMinutes: dailyMinutes,
                              analytics: analytics,
                            ),
                            loading: () => _buildLoadingCard(height: 154),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => _buildLoadingCard(height: 154),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 18),
                        historyAsync.when(
                          data: (sessions) => statsAsync.when(
                            data: (stats) =>
                                _buildLifetimeMetrics(stats, sessions),
                            loading: () => _buildLoadingCard(height: 118),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => _buildLoadingCard(height: 118),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          icon: Icons.insights,
                          title: 'This Week',
                          subtitle: 'Performance, risk windows, and momentum',
                        ),
                        const SizedBox(height: 14),
                        weeklyAnalyticsAsync.when(
                          data: (analytics) =>
                              _buildWeeklyAnalyticsCard(analytics),
                          loading: () => _buildLoadingCard(height: 210),
                          error: (_, __) => _buildErrorCard(
                            'Weekly analytics are unavailable.',
                          ),
                        ),
                        const SizedBox(height: 18),
                        dailyMinutesAsync.when(
                          data: (minutes) => _buildFocusTrend(minutes),
                          loading: () => _buildLoadingCard(height: 132),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 28),
                        historyAsync.when(
                          data: (sessions) => dailyMinutesAsync.when(
                            data: (dailyMinutes) => _buildPersonalRecords(
                              sessions: sessions,
                              dailyMinutes: dailyMinutes,
                            ),
                            loading: () => _buildLoadingCard(height: 178),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => _buildLoadingCard(height: 178),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 28),
                        historyAsync.when(
                          data: (sessions) => statsAsync.when(
                            data: (stats) => _buildCoachingInsights(
                              stats: stats,
                              sessions: sessions,
                            ),
                            loading: () => _buildLoadingCard(height: 180),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => _buildLoadingCard(height: 180),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 28),
                        Consumer(
                          builder: (context, ref, child) {
                            final heatmapAsync = ref.watch(
                              distractionHeatmapProvider,
                            );
                            return heatmapAsync.when(
                              data: (data) =>
                                  DistractionHeatmapWidget(data: data),
                              loading: () => _buildLoadingCard(height: 230),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        _buildHistoryHeader(),
                        const SizedBox(height: 14),
                        _buildViewSwitcher(),
                        const SizedBox(height: 14),
                        historyAsync.when(
                          data: (sessions) => dailyMinutesAsync.when(
                            data: (dailyMinutes) =>
                                _buildHistoryBody(sessions, dailyMinutes),
                            loading: () => _buildLoadingCard(height: 120),
                            error: (_, __) => _buildHistoryBody(sessions, {}),
                          ),
                          loading: () => _buildLoadingCard(height: 120),
                          error: (_, __) => _buildEmptyState(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          _IconActionButton(
            icon: Icons.arrow_back,
            onTap: () => ref.read(sessionStateProvider.notifier).setCheckIn(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stats',
                  style: LuxuryTextStyles.headlineLarge.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your focus patterns, cleaned up.',
                  style: LuxuryTextStyles.bodyMedium.copyWith(
                    color: LuxuryColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _IconActionButton(icon: Icons.ios_share, onTap: _shareWeeklyReport),
          const SizedBox(width: 10),
          _IconActionButton(
            icon: Icons.sync,
            onTap: () {
              _refreshStats();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCommand(UserStats stats) {
    final totalHours = stats.totalMinutes ~/ 60;
    final hasStreak = stats.currentStreak > 0;
    final message = hasStreak
        ? '${stats.currentStreak} day streak is alive'
        : 'Start the next streak today';
    final caption = hasStreak
        ? 'Best streak: ${stats.longestStreak} days'
        : 'One completed lock session starts the chain.';
    final progress = stats.longestStreak == 0
        ? 0.0
        : (stats.currentStreak / stats.longestStreak).clamp(0.0, 1.0);

    final atRisk = _isStreakAtRisk(stats);

    return _GlassPanel(
      padding: const EdgeInsets.all(22),
      glowColor: hasStreak
          ? LuxuryColors.burnishedGold
          : LuxuryColors.platinumBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStreak
                      ? LuxuryGradients.goldGradient
                      : LuxuryGradients.platinumBlueGradient,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (hasStreak
                                  ? LuxuryColors.burnishedGold
                                  : LuxuryColors.platinumBlue)
                              .withValues(alpha: 0.24),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  hasStreak
                      ? Icons.local_fire_department
                      : Icons.play_arrow_rounded,
                  color: LuxuryColors.richBlack,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: LuxuryTextStyles.titleLarge.copyWith(
                        fontSize: 22,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      caption,
                      style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (atRisk) ...[
            const SizedBox(height: 16),
            _WarningStrip(
              icon: Icons.notification_important,
              title: 'Streak risk',
              message: 'One focused session today keeps the chain alive.',
            ),
          ],
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: hasStreak
                  ? LuxuryColors.burnishedGold
                  : LuxuryColors.platinumBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InlineStat(
                  label: 'Lifetime focus',
                  value: '${totalHours}h ${stats.totalMinutes % 60}m',
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: 'Perfect sessions',
                  value: '${stats.perfectSessions}',
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress({
    required Map<DateTime, int> dailyMinutes,
    required WeeklyAnalytics analytics,
  }) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final todayMinutes = dailyMinutes[todayKey] ?? 0;

    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      borderColor: LuxuryColors.burnishedGold.withValues(alpha: 0.2),
      child: Column(
        children: [
          _GoalRow(
            icon: Icons.today,
            label: 'Today goal',
            value: '${todayMinutes}m / ${_dailyGoalMinutes}m',
            progress: todayMinutes / _dailyGoalMinutes,
            color: LuxuryColors.burnishedGold,
          ),
          const SizedBox(height: 16),
          _GoalRow(
            icon: Icons.date_range,
            label: 'Weekly goal',
            value: '${analytics.totalFocusMinutes}m / ${_weeklyGoalMinutes}m',
            progress: analytics.totalFocusMinutes / _weeklyGoalMinutes,
            color: LuxuryColors.platinumBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeMetrics(UserStats stats, List<SessionRecord> sessions) {
    final average = stats.totalSessions == 0
        ? 0
        : (stats.totalMinutes / stats.totalSessions).round();
    final avgInterruptions = sessions.isEmpty
        ? 0.0
        : sessions.fold<int>(0, (sum, s) => sum + s.interruptions) /
              sessions.length;

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.check_circle,
            label: 'Sessions',
            value: '${stats.totalSessions}',
            color: LuxuryColors.amethystLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Icons.timer,
            label: 'Avg length',
            value: '${average}m',
            color: LuxuryColors.platinumBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            icon: Icons.mobile_off,
            label: 'Avg pickup',
            value: avgInterruptions.toStringAsFixed(1),
            color: avgInterruptions == 0
                ? LuxuryColors.emeraldLight
                : LuxuryColors.burnishedGold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAnalyticsCard(WeeklyAnalytics analytics) {
    final focusHours = analytics.totalFocusMinutes ~/ 60;
    final focusMinutes = analytics.totalFocusMinutes % 60;
    final successPercent = (analytics.successRate * 100).round();
    final totalSessions = analytics.totalSessions;

    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      glowColor: LuxuryColors.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _WeeklyHeroNumber(
                  label: 'Focus banked',
                  value: '${focusHours}h ${focusMinutes}m',
                  icon: Icons.savings,
                  color: LuxuryColors.platinumBlue,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: totalSessions == 0 ? 0 : analytics.successRate,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        color: _successColor(successPercent),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$successPercent%',
                          style: LuxuryTextStyles.titleLarge.copyWith(
                            fontSize: 22,
                            color: _successColor(successPercent),
                          ),
                        ),
                        Text(
                          'success',
                          style: LuxuryTextStyles.hint.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniInsight(
                  icon: Icons.done_all,
                  label: 'Won',
                  value: '${analytics.successfulSessions}',
                  color: LuxuryColors.emeraldLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInsight(
                  icon: Icons.close,
                  label: 'Failed',
                  value: '${analytics.failedSessions}',
                  color: LuxuryColors.deepRose,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInsight(
                  icon: Icons.mobile_off,
                  label: 'Pickups',
                  value: '${analytics.totalInterruptions}',
                  color: LuxuryColors.burnishedGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CalloutPill(
            icon: Icons.shield,
            label: 'Clean rate',
            value: '$successPercent% success with $totalSessions sessions',
            color: _successColor(successPercent),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CalloutPill(
                  icon: Icons.trending_up,
                  label: 'Best hour',
                  value: _formatHourLabel(analytics.bestHour),
                  color: LuxuryColors.amethystLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CalloutPill(
                  icon: Icons.hourglass_bottom,
                  label: 'Toughest hour',
                  value: _formatHourLabel(analytics.toughestHour),
                  color: LuxuryColors.roseLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecords({
    required List<SessionRecord> sessions,
    required Map<DateTime, int> dailyMinutes,
  }) {
    final successful = sessions.where((session) => session.wasSuccessful);
    final longest = successful.isEmpty
        ? null
        : successful.reduce(
            (a, b) => a.durationMinutes >= b.durationMinutes ? a : b,
          );
    final highestEnergy = sessions.isEmpty
        ? null
        : sessions.reduce((a, b) => a.energyLevel >= b.energyLevel ? a : b);
    final bestDayEntry = dailyMinutes.entries.isEmpty
        ? null
        : dailyMinutes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final cleanSessions = sessions
        .where((session) => session.wasSuccessful && session.interruptions == 0)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.emoji_events,
          title: 'Personal Records',
          subtitle: 'Your strongest runs and cleanest focus wins',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _RecordTile(
                icon: Icons.timer,
                label: 'Longest',
                value: longest == null ? '--' : '${longest.durationMinutes}m',
                detail: longest?.taskName.isEmpty ?? true
                    ? 'single session'
                    : longest!.taskName,
                color: LuxuryColors.platinumBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RecordTile(
                icon: Icons.calendar_month,
                label: 'Best day',
                value: bestDayEntry == null ? '--' : '${bestDayEntry.value}m',
                detail: bestDayEntry == null
                    ? 'no focus yet'
                    : _formatDate(bestDayEntry.key),
                color: LuxuryColors.burnishedGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RecordTile(
                icon: Icons.bolt,
                label: 'Top energy',
                value: highestEnergy == null
                    ? '--'
                    : '${highestEnergy.energyLevel}%',
                detail: highestEnergy == null
                    ? 'no sessions yet'
                    : _formatDate(highestEnergy.completedAt),
                color: LuxuryColors.roseLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RecordTile(
                icon: Icons.verified,
                label: 'Clean sessions',
                value: '$cleanSessions',
                detail: 'no pickups',
                color: LuxuryColors.emeraldLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoachingInsights({
    required UserStats stats,
    required List<SessionRecord> sessions,
  }) {
    final topTasks = _topTasks(sessions);
    final recoveryMessage = _recoveryMessage(stats, sessions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.psychology,
          title: 'Coaching Insights',
          subtitle: 'What to repeat, avoid, and recover from',
        ),
        const SizedBox(height: 14),
        _GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: LuxuryColors.amethystLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Best focus categories',
                    style: LuxuryTextStyles.labelLarge.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (topTasks.isEmpty)
                Text(
                  'Name your sessions to unlock task-level insights.',
                  style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 13),
                )
              else
                ...topTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RankedTaskRow(task: task),
                  ),
                ),
              const SizedBox(height: 8),
              _WarningStrip(
                icon: Icons.health_and_safety,
                title: 'Recovery cue',
                message: recoveryMessage,
                calm: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFocusTrend(Map<DateTime, int> minutesByDay) {
    final days = minutesByDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final visibleDays = days.length > 14
        ? days.sublist(days.length - 14)
        : days;
    final maxMinutes = visibleDays.fold<int>(
      0,
      (max, entry) => entry.value > max ? entry.value : max,
    );
    final activeDays = visibleDays.where((entry) => entry.value > 0).length;

    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stacked_bar_chart,
                color: LuxuryColors.platinumBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '14 Day Focus Rhythm',
                style: LuxuryTextStyles.labelLarge.copyWith(fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$activeDays/${visibleDays.length} active',
                style: LuxuryTextStyles.hint.copyWith(
                  color: LuxuryColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: visibleDays.map((entry) {
                final height = maxMinutes == 0
                    ? 8.0
                    : 8.0 + (entry.value / maxMinutes) * 58.0;
                final isToday = _isSameDay(entry.key, DateTime.now());
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Tooltip(
                      message: '${_formatDate(entry.key)} - ${entry.value}m',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: entry.value == 0
                                ? [
                                    LuxuryColors.elevatedSurface,
                                    LuxuryColors.elevatedSurface,
                                  ]
                                : [
                                    LuxuryColors.platinumBlue.withValues(
                                      alpha: 0.45,
                                    ),
                                    isToday
                                        ? LuxuryColors.burnishedGold
                                        : LuxuryColors.platinumBlue,
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: LuxuryColors.platinumBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: LuxuryColors.platinumBlue.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(icon, color: LuxuryColors.platinumBlue, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: LuxuryTextStyles.titleLarge.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    return _buildSectionHeader(
      icon: Icons.history,
      title: 'Recent Sessions',
      subtitle: 'Review what held, what broke, and what to repeat',
    );
  }

  Widget _buildViewSwitcher() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SegmentButton(
                icon: Icons.view_list,
                label: 'List',
                selected: _view == _StatsView.list,
                onTap: () => setState(() => _view = _StatsView.list),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SegmentButton(
                icon: Icons.calendar_month,
                label: 'Calendar',
                selected: _view == _StatsView.calendar,
                onTap: () => setState(() => _view = _StatsView.calendar),
              ),
            ),
          ],
        ),
        if (_view == _StatsView.list) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _SessionFilter.values.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChipButton(
                    label: _filterLabel(filter),
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryBody(
    List<SessionRecord> sessions,
    Map<DateTime, int> dailyMinutes,
  ) {
    if (_view == _StatsView.calendar) {
      return _buildCalendarView(dailyMinutes);
    }

    final filtered = _filterSessions(
      sessions,
    ).toList().reversed.take(20).toList();
    if (filtered.isEmpty) {
      return _buildFilteredEmptyState();
    }

    return Column(
      children: filtered.map((session) => _buildSessionCard(session)).toList(),
    );
  }

  Widget _buildCalendarView(Map<DateTime, int> dailyMinutes) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final daysInMonth = nextMonth.difference(monthStart).inDays;
    final leadingDays = monthStart.weekday - 1;
    final cells = leadingDays + daysInMonth;
    final rows = (cells / 7).ceil();

    return _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: LuxuryColors.platinumBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_monthName(now.month)} ${now.year}',
                style: LuxuryTextStyles.labelLarge.copyWith(fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Goal: ${_dailyGoalMinutes}m',
                style: LuxuryTextStyles.hint.copyWith(
                  color: LuxuryColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LuxuryColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(rows, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final cellIndex = rowIndex * 7 + dayIndex;
                  final dayNumber = cellIndex - leadingDays + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 42));
                  }
                  final date = DateTime(now.year, now.month, dayNumber);
                  final minutes = dailyMinutes[date] ?? 0;
                  final progress = (minutes / _dailyGoalMinutes).clamp(
                    0.0,
                    1.0,
                  );
                  final isToday = _isSameDay(date, now);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Tooltip(
                        message: '$minutes focus minutes',
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              LuxuryColors.elevatedSurface,
                              LuxuryColors.emeraldLight,
                              progress,
                            )!.withValues(alpha: minutes == 0 ? 0.7 : 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isToday
                                  ? LuxuryColors.burnishedGold
                                  : Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$dayNumber',
                              style: LuxuryTextStyles.hint.copyWith(
                                color: isToday
                                    ? LuxuryColors.burnishedGold
                                    : LuxuryColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionCard(SessionRecord session) {
    final color = session.wasSuccessful
        ? LuxuryColors.emeraldLight
        : LuxuryColors.deepRose;
    final title = session.taskName.isNotEmpty
        ? session.taskName
        : 'Focus Session';
    final meta = [
      _formatDateTime(session.completedAt),
      session.lockLevel,
    ].join(' - ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _GlassPanel(
        padding: const EdgeInsets.all(14),
        borderColor: color.withValues(alpha: 0.24),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.13),
                border: Border.all(color: color.withValues(alpha: 0.24)),
              ),
              child: Icon(
                session.wasSuccessful ? Icons.check : Icons.close,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: LuxuryTextStyles.titleLarge.copyWith(
                      color: LuxuryColors.textPrimary,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!session.wasSuccessful || session.interruptions > 0) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (session.interruptions > 0)
                          _TinyBadge(
                            icon: Icons.mobile_off,
                            label: '${session.interruptions} pickups',
                            color: LuxuryColors.burnishedGold,
                          ),
                        if (session.emergencyBreaks > 0)
                          _TinyBadge(
                            icon: Icons.warning_amber,
                            label: '${session.emergencyBreaks} breaks',
                            color: LuxuryColors.deepRose,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.durationMinutes}m',
                  style: LuxuryTextStyles.titleLarge.copyWith(
                    color: LuxuryColors.platinumBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                _EnergyChip(level: session.energyLevel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off,
            color: LuxuryColors.textTertiary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'No sessions match this filter',
            style: LuxuryTextStyles.titleLarge.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Try All or complete more sessions to fill this view.',
            textAlign: TextAlign.center,
            style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return _GlassPanel(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: Center(
          child: CircularProgressIndicator(
            color: LuxuryColors.platinumBlue,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      borderColor: LuxuryColors.deepRose.withValues(alpha: 0.24),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: LuxuryColors.deepRose, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _GlassPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxuryColors.platinumBlue.withValues(alpha: 0.08),
              border: Border.all(
                color: LuxuryColors.platinumBlue.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              Icons.history,
              size: 28,
              color: LuxuryColors.platinumBlue.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: LuxuryTextStyles.titleLarge.copyWith(
              color: LuxuryColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first focus lock and your stats will start forming here.',
            textAlign: TextAlign.center,
            style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _refreshStats() {
    ref.invalidate(userStatsProvider);
    ref.invalidate(sessionHistoryProvider);
    ref.invalidate(weeklyAnalyticsProvider);
    ref.invalidate(dailyMinutesProvider);
    ref.invalidate(distractionHeatmapProvider);
  }

  Future<void> _shareWeeklyReport() async {
    try {
      final stats = await ref.read(userStatsProvider.future);
      final analytics = await ref.read(weeklyAnalyticsProvider.future);
      final sessions = await ref.read(sessionHistoryProvider.future);
      final successful = analytics.successfulSessions;
      final successPercent = (analytics.successRate * 100).round();
      final topTasks = _topTasks(sessions);
      final bestTask = topTasks.isEmpty ? 'Focus Session' : topTasks.first.name;
      final message =
          'Bio-Locked weekly focus report\n\n'
          'Focus time: ${analytics.totalFocusMinutes}m\n'
          'Successful sessions: $successful\n'
          'Success rate: $successPercent%\n'
          'Current streak: ${stats.currentStreak} days\n'
          'Best focus category: $bestTask\n'
          'Pickups caught: ${analytics.totalInterruptions}\n\n'
          'Locked in, stayed honest.';
      await Share.share(message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share report: $e'),
          backgroundColor: LuxuryColors.ruby,
        ),
      );
    }
  }

  bool _isStreakAtRisk(UserStats stats) {
    if (stats.currentStreak == 0 || stats.lastSessionDate == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = stats.lastSessionDate!;
    final lastDate = DateTime(last.year, last.month, last.day);
    final daysSince = today.difference(lastDate).inDays;
    return daysSince >= 1 || (daysSince == 0 && now.hour >= 20);
  }

  Iterable<SessionRecord> _filterSessions(List<SessionRecord> sessions) {
    return sessions.where((session) {
      switch (_filter) {
        case _SessionFilter.all:
          return true;
        case _SessionFilter.successful:
          return session.wasSuccessful;
        case _SessionFilter.failed:
          return !session.wasSuccessful;
        case _SessionFilter.highEnergy:
          return session.energyLevel >= 70;
        case _SessionFilter.intenseLock:
          return session.lockLevel.toLowerCase() != 'standard';
      }
    });
  }

  String _filterLabel(_SessionFilter filter) {
    switch (filter) {
      case _SessionFilter.all:
        return 'All';
      case _SessionFilter.successful:
        return 'Won';
      case _SessionFilter.failed:
        return 'Failed';
      case _SessionFilter.highEnergy:
        return 'High energy';
      case _SessionFilter.intenseLock:
        return 'Strict lock';
    }
  }

  List<_TaskAggregate> _topTasks(List<SessionRecord> sessions) {
    final grouped = <String, _TaskAggregate>{};
    for (final session in sessions) {
      final name = session.taskName.trim().isEmpty
          ? 'Focus Session'
          : session.taskName.trim();
      final current =
          grouped[name] ?? _TaskAggregate(name: name, minutes: 0, sessions: 0);
      current.sessions += 1;
      if (session.wasSuccessful) {
        current.minutes += session.durationMinutes;
      }
      grouped[name] = current;
    }

    final tasks = grouped.values.toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));
    return tasks.take(3).where((task) => task.minutes > 0).toList();
  }

  String _recoveryMessage(UserStats stats, List<SessionRecord> sessions) {
    final recentFailed = sessions.reversed
        .where((session) => !session.wasSuccessful)
        .take(3)
        .toList();

    if (recentFailed.isEmpty && stats.recentFailureReasons.isEmpty) {
      return 'No recent failures logged. Keep repeating the same setup.';
    }

    final pickupHeavy = recentFailed.any(
      (session) => session.interruptions >= 2,
    );
    if (pickupHeavy) {
      return 'Your last misses involved pickups. Use a stricter lock level for the next session.';
    }

    if (stats.recentFailureReasons.isNotEmpty) {
      return 'Recent blocker: ${stats.recentFailureReasons.last}. Reduce the next session by 10 minutes and rebuild.';
    }

    return 'After a miss, run one shorter clean session instead of chasing a huge comeback.';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Color _successColor(int successPercent) {
    if (successPercent >= 80) return LuxuryColors.emeraldLight;
    if (successPercent >= 50) return LuxuryColors.burnishedGold;
    return LuxuryColors.deepRose;
  }

  String _formatHourLabel(int? hour) {
    if (hour == null) return '--';
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
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
      dayStr = _formatDate(dt);
    }

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$dayStr at $hour:$minute $ampm';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? glowColor;
  final Color? borderColor;

  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glowColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LuxuryGradients.frostedGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
              if (glowColor != null)
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.12),
                  blurRadius: 34,
                  spreadRadius: -8,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, color: LuxuryColors.platinumBlue, size: 20),
        ),
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _InlineStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(value, style: LuxuryTextStyles.titleLarge.copyWith(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          label,
          style: LuxuryTextStyles.hint.copyWith(
            color: LuxuryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: LuxuryTextStyles.titleLarge.copyWith(
                color: color,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxuryTextStyles.hint.copyWith(
              color: LuxuryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _GoalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: LuxuryTextStyles.labelLarge.copyWith(fontSize: 12),
              ),
            ),
            Text(
              value,
              style: LuxuryTextStyles.hint.copyWith(
                color: LuxuryColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _RecordTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(
            value,
            style: LuxuryTextStyles.titleLarge.copyWith(
              color: color,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: LuxuryTextStyles.hint.copyWith(
              color: LuxuryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxuryTextStyles.hint.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _WarningStrip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool calm;

  const _WarningStrip({
    required this.icon,
    required this.title,
    required this.message,
    this.calm = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = calm ? LuxuryColors.platinumBlue : LuxuryColors.burnishedGold;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LuxuryTextStyles.labelLarge.copyWith(
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedTaskRow extends StatelessWidget {
  final _TaskAggregate task;

  const _RankedTaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxuryTextStyles.bodyMedium.copyWith(
                color: LuxuryColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${task.minutes}m',
            style: LuxuryTextStyles.labelLarge.copyWith(
              color: LuxuryColors.platinumBlue,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${task.sessions}x',
            style: LuxuryTextStyles.hint.copyWith(
              color: LuxuryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? LuxuryColors.platinumBlue
        : LuxuryColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? LuxuryColors.platinumBlue.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? LuxuryColors.platinumBlue.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 8),
            Text(
              label,
              style: LuxuryTextStyles.labelLarge.copyWith(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? LuxuryColors.burnishedGold.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? LuxuryColors.burnishedGold.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: LuxuryTextStyles.hint.copyWith(
            color: selected
                ? LuxuryColors.burnishedGold
                : LuxuryColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TaskAggregate {
  final String name;
  int minutes;
  int sessions;

  _TaskAggregate({
    required this.name,
    required this.minutes,
    required this.sessions,
  });
}

class _WeeklyHeroNumber extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WeeklyHeroNumber({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: LuxuryTextStyles.hint.copyWith(
                color: LuxuryColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: LuxuryTextStyles.displayLarge.copyWith(
              fontSize: 34,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInsight extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniInsight({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 9),
          Text(
            value,
            style: LuxuryTextStyles.titleLarge.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxuryTextStyles.hint.copyWith(
              color: LuxuryColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CalloutPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxuryTextStyles.hint.copyWith(fontSize: 10),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxuryTextStyles.bodyMedium.copyWith(
                    color: LuxuryColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TinyBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: LuxuryTextStyles.hint.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _EnergyChip extends StatelessWidget {
  final int level;

  const _EnergyChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = getLuxuryEnergyColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$level%',
            style: LuxuryTextStyles.hint.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
