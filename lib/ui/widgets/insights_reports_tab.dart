import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/stats/stats_service.dart';
import '../theme/luxury_theme.dart';

/// Advanced analytics + CSV export (History → Insights tab).
class InsightsReportsTab extends ConsumerWidget {
  const InsightsReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsAnalyticsProvider);

    return RefreshIndicator(
      color: LuxuryColors.platinumBlue,
      onRefresh: () async {
        ref.invalidate(insightsAnalyticsProvider);
        ref.invalidate(sessionHistoryProvider);
      },
      child: insightsAsync.when(
        loading: () => ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: CircularProgressIndicator(
                color: LuxuryColors.platinumBlue,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
        error: (_, __) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Could not load insights.',
              style: LuxuryTextStyles.bodyLarge.copyWith(color: LuxuryColors.rubyRed),
            ),
          ],
        ),
        data: (bundle) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            _sectionTitle('COACH INSIGHTS'),
            const SizedBox(height: 12),
            ...bundle.coachInsights.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _glassParagraph(line),
              ),
            ),
            const SizedBox(height: 28),
            _sectionTitle('CONSISTENCY'),
            const SizedBox(height: 12),
            _metricRow(
              'Active days (30d)',
              '${bundle.consistency.activeDaysLast30} / 30',
            ),
            _metricRow(
              'Consistency score',
              '${(bundle.consistency.consistencyScore30d * 100).round()}%',
            ),
            _metricRow(
              'This week focus',
              '${bundle.consistency.currentWeekSuccessfulMinutes} min',
            ),
            _metricRow(
              'Last week focus',
              '${bundle.consistency.previousWeekSuccessfulMinutes} min',
            ),
            _metricRow(
              'Sessions (this / prev week)',
              '${bundle.consistency.currentWeekSessionCount} / ${bundle.consistency.previousWeekSessionCount}',
            ),
            const SizedBox(height: 28),
            _sectionTitle('ROLLING 4-WEEK SUCCESS'),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < bundle.rollingTrends.weeklySuccessRates.length; i++)
                  Expanded(
                    child: _miniStat(
                      'W${i + 1}',
                      '${(bundle.rollingTrends.weeklySuccessRates[i] * 100).round()}%',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _metricRow(
              'Longest success run',
              '${bundle.rollingTrends.longestSuccessfulSessionRun} sessions',
            ),
            _metricRow(
              'Recovery after a fail day',
              '${(bundle.rollingTrends.recoveryRateAfterFailure * 100).round()}%',
            ),
            const SizedBox(height: 28),
            _sectionTitle('LOCK LEVEL'),
            const SizedBox(height: 12),
            ...bundle.lockLevelBreakdown.entries.map((e) {
              final r = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _glassParagraph(
                  '${r.lockLevel.toUpperCase()} · '
                  '${r.sessionsSuccessful}/${r.sessionsTotal} ok · '
                  '${r.totalMinutesSuccessful} min · '
                  'EB avg ${r.emergencyBreaksPerSession.toStringAsFixed(2)}',
                ),
              );
            }),
            const SizedBox(height: 28),
            _sectionTitle('PICKUPS & FLOW'),
            const SizedBox(height: 12),
            _metricRow(
              'Avg pickups / completed session',
              bundle.interruptionIntensity.avgInterruptionsPerCompletedSession
                  .toStringAsFixed(2),
            ),
            _metricRow(
              'Sessions with zero pickups',
              '${(bundle.interruptionIntensity.percentSessionsZeroInterruptions * 100).round()}%',
            ),
            _metricRow(
              'Avg pickups (std/hard, when >0)',
              bundle.interruptionIntensity.avgInterruptionsWhenPickupHeavyLock
                  .toStringAsFixed(2),
            ),
            if (bundle.medianSuccessfulCompletionHour != null)
              _metricRow(
                'Median finish hour (successful)',
                _formatHour(bundle.medianSuccessfulCompletionHour!),
              ),
            const SizedBox(height: 28),
            _sectionTitle('SESSION LENGTH (15m buckets)'),
            const SizedBox(height: 12),
            _histogram(bundle.lengthDistribution.histogramMinutesBucket),
            _metricRow(
              'Avg completed length',
              '${bundle.lengthDistribution.avgCompletedLength.toStringAsFixed(0)} min',
            ),
            _metricRow(
              'Avg failed length',
              '${bundle.lengthDistribution.avgFailedLength.toStringAsFixed(0)} min',
            ),
            const SizedBox(height: 28),
            _sectionTitle('ENERGY VS OUTCOME'),
            const SizedBox(height: 12),
            ...bundle.energyBands.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _glassParagraph(
                  '${b.bandLabel}: ${b.sessions} sessions · '
                  '${(b.successRate * 100).round()}% ok · '
                  '${b.avgInterruptions.toStringAsFixed(2)} pickups avg',
                ),
              ),
            ),
            const SizedBox(height: 28),
            _sectionTitle('FAILURE BREAKDOWN'),
            const SizedBox(height: 12),
            if (bundle.failureTaxonomy.countsByCategory.isEmpty)
              Text(
                'No failures logged yet.',
                style: LuxuryTextStyles.bodyMedium.copyWith(
                  color: LuxuryColors.textSecondary,
                ),
              )
            else
              ...bundle.failureTaxonomy.countsByCategory.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _glassParagraph('${e.key}: ${e.value}'),
                ),
              ),
            const SizedBox(height: 28),
            _sectionTitle('TASK LEADERBOARD'),
            const SizedBox(height: 12),
            if (bundle.taskLeaderboard.isEmpty)
              Text(
                'Complete sessions with named tasks for richer stats.',
                style: LuxuryTextStyles.bodyMedium.copyWith(
                  color: LuxuryColors.textSecondary,
                ),
              )
            else
              ...bundle.taskLeaderboard.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _glassParagraph(
                    '${t.taskName}: ${t.totalMinutes} min · '
                    '${t.successfulCount}/${t.sessionCount} ok · '
                    '${(t.successRate * 100).round()}% · '
                    '${t.avgInterruptions.toStringAsFixed(2)} pickups',
                  ),
                ),
              ),
            const SizedBox(height: 28),
            _sectionTitle('APP USAGE CROSS-SIGNAL'),
            const SizedBox(height: 12),
            _metricRow(
              'Study vs distracting ratio',
              bundle.studyVsDistractingRatio.toStringAsFixed(2),
            ),
            _metricRow(
              'Highest distraction hour',
              bundle.highestDistractionHour == null
                  ? '--'
                  : _formatHour(bundle.highestDistractionHour!),
            ),
            _metricRow(
              'Best study hour',
              bundle.bestStudyHour == null
                  ? '--'
                  : _formatHour(bundle.bestStudyHour!),
            ),
            if (bundle.topAppsWeek.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bundle.topAppsWeek.take(5).map(
                (app) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _glassParagraph(
                    '${app.appLabel}: ${app.minutes} min · ${app.category.key}',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: LuxuryColors.platinumBlue,
                  side: BorderSide(
                    color: LuxuryColors.platinumBlue.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.ios_share_outlined),
                label: Text(
                  'EXPORT SESSION CSV',
                  style: LuxuryTextStyles.labelLarge.copyWith(
                    letterSpacing: 2,
                  ),
                ),
                onPressed: () async {
                  await ref.read(statsServiceProvider).shareHistoryCsv();
                  ref.invalidate(insightsAnalyticsProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: LuxuryTextStyles.labelLarge.copyWith(
        color: LuxuryColors.textSecondary,
        letterSpacing: 3,
        fontSize: 12,
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: LuxuryTextStyles.bodyMedium.copyWith(
                color: LuxuryColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: LuxuryTextStyles.titleLarge.copyWith(
              color: LuxuryColors.platinumBlue,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: LuxuryColors.cardBackground,
        border: Border.all(
          color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: LuxuryTextStyles.bodyMedium.copyWith(
              fontSize: 10,
              color: LuxuryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: LuxuryTextStyles.titleLarge.copyWith(
              fontSize: 13,
              color: LuxuryColors.emerald,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassParagraph(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: LuxuryColors.cardBackground,
        border: Border.all(
          color: LuxuryColors.platinumBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        text,
        style: LuxuryTextStyles.bodyMedium.copyWith(
          color: LuxuryColors.textPrimary,
          height: 1.35,
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h $period';
  }

  Widget _histogram(Map<int, int> buckets) {
    if (buckets.isEmpty) {
      return Text(
        'No completed sessions yet.',
        style: LuxuryTextStyles.bodyMedium.copyWith(
          color: LuxuryColors.textSecondary,
        ),
      );
    }
    final keys = buckets.keys.toList()..sort();
    final maxC = buckets.values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: keys.map((k) {
          final c = buckets[k] ?? 0;
          final h = maxC == 0 ? 4.0 : 8 + (72 * c / maxC);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          LuxuryColors.platinumBlue.withValues(alpha: 0.35),
                          LuxuryColors.platinumBlue.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$k',
                    style: LuxuryTextStyles.bodyMedium.copyWith(fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
