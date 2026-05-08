import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../features/stats/stats_service.dart';
import '../features/session/session_provider.dart';
import 'widgets/heatmap_widget.dart';
import 'widgets/app_usage_tab.dart';
import 'widgets/insights_reports_tab.dart';
import 'widgets/shared_bottom_nav_bar.dart';
import 'theme/luxury_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsProvider);
    final historyAsync = ref.watch(sessionHistoryProvider);
    final weeklyAnalyticsAsync = ref.watch(weeklyAnalyticsProvider);

    return Scaffold(
      backgroundColor: LuxuryColors.richBlack,
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 1),
      body: Container(
        decoration: BoxDecoration(
          gradient: LuxuryGradients.darkBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          ref.read(sessionStateProvider.notifier).setCheckIn(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LuxuryColors.cardBackground,
                          border: Border.all(
                            color:
                                LuxuryColors.platinumBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: LuxuryColors.platinumBlue,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'FOCUS HISTORY',
                        style: LuxuryTextStyles.headlineLarge.copyWith(
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: LuxuryColors.platinumBlue,
                labelColor: LuxuryColors.platinumBlue,
                unselectedLabelColor: LuxuryColors.textSecondary,
                tabs: const [
                  Tab(text: 'OVERVIEW'),
                  Tab(text: 'INSIGHTS'),
                  Tab(text: 'APP USAGE'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          statsAsync.when(
                            data: _buildStatsSummary,
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'THIS WEEK',
                            style: LuxuryTextStyles.labelLarge.copyWith(
                              color: LuxuryColors.textSecondary,
                              letterSpacing: 3,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          weeklyAnalyticsAsync.when(
                            data: _buildWeeklyAnalyticsCard,
                            loading: () => SizedBox(
                              height: 130,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: LuxuryColors.platinumBlue,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 32),
                          Consumer(
                            builder: (context, ref, _) {
                              final heatmapAsync =
                                  ref.watch(distractionHeatmapProvider);
                              return heatmapAsync.when(
                                data: (data) =>
                                    DistractionHeatmapWidget(data: data),
                                loading: () => SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: LuxuryColors.platinumBlue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'RECENT SESSIONS',
                            style: LuxuryTextStyles.labelLarge.copyWith(
                              color: LuxuryColors.textSecondary,
                              letterSpacing: 3,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          historyAsync.when(
                            data: (sessions) => sessions.isEmpty
                                ? _buildEmptyState()
                                : Column(
                                    children: sessions
                                        .reversed
                                        .take(20)
                                        .map(_buildSessionCard)
                                        .toList(),
                                  ),
                            loading: () => SizedBox(
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: LuxuryColors.platinumBlue,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            error: (_, __) => _buildEmptyState(),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    const InsightsReportsTab(),
                    const AppUsageTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(UserStats stats) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LuxuryGradients.frostedGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.local_fire_department,
                      value: '${stats.currentStreak}',
                      label: 'Current Streak',
                      color: LuxuryColors.burnishedGold,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: LuxuryColors.textSecondary.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.emoji_events,
                      value: '${stats.longestStreak}',
                      label: 'Best Streak',
                      color: LuxuryColors.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: LuxuryColors.textSecondary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.access_time,
                      value: '${stats.totalMinutes ~/ 60}h ${stats.totalMinutes % 60}m',
                      label: 'Total Focus',
                      color: LuxuryColors.platinumBlue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: LuxuryColors.textSecondary.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.check_circle,
                      value: '${stats.totalSessions}',
                      label: 'Sessions',
                      color: LuxuryColors.amethyst,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: LuxuryTextStyles.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: LuxuryTextStyles.bodyMedium.copyWith(
            color: LuxuryColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAnalyticsCard(WeeklyAnalytics analytics) {
    final focusHours = analytics.totalFocusMinutes ~/ 60;
    final focusMinutes = analytics.totalFocusMinutes % 60;
    final successPercent = (analytics.successRate * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LuxuryColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: LuxuryColors.burnishedGold.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildWeeklyMetric(
                      icon: Icons.timer,
                      label: 'Focus Time',
                      value: '${focusHours}h ${focusMinutes}m',
                      color: LuxuryColors.platinumBlue,
                    ),
                  ),
                  Expanded(
                    child: _buildWeeklyMetric(
                      icon: Icons.shield,
                      label: 'Success',
                      value: '$successPercent%',
                      color: LuxuryColors.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildWeeklyMetric(
                      icon: Icons.report_problem,
                      label: 'Failed Sessions',
                      value: '${analytics.failedSessions}',
                      color: LuxuryColors.deepRose,
                    ),
                  ),
                  Expanded(
                    child: _buildWeeklyMetric(
                      icon: Icons.mobile_off,
                      label: 'Pickups Caught',
                      value: '${analytics.totalInterruptions}',
                      color: LuxuryColors.burnishedGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildWeeklyMetric(
                      icon: Icons.trending_up,
                      label: 'Best Hour',
                      value: _formatHourLabel(analytics.bestHour),
                      color: LuxuryColors.amethyst,
                    ),
                  ),
                  Expanded(
                    child: _buildWeeklyMetric(
                      icon: Icons.hourglass_bottom,
                      label: 'Toughest Hour',
                      value: _formatHourLabel(analytics.toughestHour),
                      color: LuxuryColors.champagneGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: LuxuryTextStyles.titleLarge.copyWith(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: LuxuryTextStyles.bodyMedium.copyWith(
              color: LuxuryColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHourLabel(int? hour) {
    if (hour == null) return '--';
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }

  Color _getHeatmapColor(int minutes) {
    if (minutes == 0) return LuxuryColors.elevatedSurface;
    if (minutes < 15) return LuxuryColors.emerald.withValues(alpha: 0.2);
    if (minutes < 30) return LuxuryColors.emerald.withValues(alpha: 0.4);
    if (minutes < 60) return LuxuryColors.emerald.withValues(alpha: 0.6);
    if (minutes < 120) return LuxuryColors.emerald.withValues(alpha: 0.8);
    return LuxuryColors.emerald;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildSessionCard(SessionRecord session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LuxuryColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: session.wasSuccessful
                    ? LuxuryColors.emerald.withValues(alpha: 0.3)
                    : LuxuryColors.deepRose.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: session.wasSuccessful
                        ? LuxuryColors.emerald.withValues(alpha: 0.15)
                        : LuxuryColors.deepRose.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    session.wasSuccessful ? Icons.check : Icons.close,
                    color: session.wasSuccessful
                        ? LuxuryColors.emerald
                        : LuxuryColors.deepRose,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.taskName.isNotEmpty
                            ? session.taskName
                            : 'Focus Session',
                        style: LuxuryTextStyles.titleLarge.copyWith(
                          color: LuxuryColors.textPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(session.completedAt),
                        style: LuxuryTextStyles.bodyMedium.copyWith(
                          color: LuxuryColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${session.durationMinutes}m',
                      style: LuxuryTextStyles.titleLarge.copyWith(
                        color: LuxuryColors.platinumBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 12,
                          color: LuxuryColors.burnishedGold,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${session.energyLevel}%',
                          style: LuxuryTextStyles.bodyMedium.copyWith(
                            color: LuxuryColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      dayStr = _formatDate(dt);
    }
    
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    
    return '$dayStr at $hour:$minute $ampm';
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: LuxuryColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: LuxuryTextStyles.titleLarge.copyWith(
              color: LuxuryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first focus session\nto see your history here',
            textAlign: TextAlign.center,
            style: LuxuryTextStyles.bodyMedium.copyWith(
              color: LuxuryColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
