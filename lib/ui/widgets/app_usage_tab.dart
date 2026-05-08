import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/app_usage/app_usage_models.dart';
import '../../features/app_usage/app_usage_providers.dart';
import '../../features/app_usage/app_usage_service.dart';
import '../theme/luxury_theme.dart';
import 'hourly_usage_chart.dart';

class AppUsageTab extends ConsumerWidget {
  const AppUsageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(usagePermissionGrantedProvider);
    final topAppsAsync = ref.watch(topAppUsageProvider);
    final hourlyAsync = ref.watch(usageHourlyBucketsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(usagePermissionGrantedProvider);
        ref.invalidate(appUsageEntriesProvider);
        ref.invalidate(topAppUsageProvider);
        ref.invalidate(usageHourlyBucketsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        children: [
          permissionAsync.when(
            data: (granted) => _permissionCard(context, ref, granted),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => _permissionCard(context, ref, false),
          ),
          const SizedBox(height: 18),
          _sectionTitle('TOP APPS (WEEK)'),
          const SizedBox(height: 10),
          topAppsAsync.when(
            data: (apps) {
              if (apps.isEmpty) return _empty('No app usage data available yet.');
              return Column(
                children: apps
                    .map(
                      (app) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _glass(
                          '${app.appLabel.isEmpty ? app.packageName : app.appLabel} · ${app.minutes} min · ${app.category.key}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => _loading(),
            error: (_, __) => _empty('Could not load top apps.'),
          ),
          const SizedBox(height: 18),
          _sectionTitle('HOURLY USAGE'),
          const SizedBox(height: 10),
          hourlyAsync.when(
            data: (rows) => _hourlyCard(rows),
            loading: () => _loading(),
            error: (_, __) => _empty('Could not load hourly usage.'),
          ),
        ],
      ),
    );
  }

  Widget _permissionCard(BuildContext context, WidgetRef ref, bool granted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: LuxuryColors.cardBackground,
        border: Border.all(color: LuxuryColors.subtleBorder),
      ),
      child: Row(
        children: [
          Icon(
            granted ? Icons.verified_user : Icons.shield_outlined,
            color: granted ? LuxuryColors.emerald : LuxuryColors.burnishedGold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              granted
                  ? 'Usage access granted'
                  : 'Usage access required for per-app tracking',
              style: LuxuryTextStyles.bodyMedium,
            ),
          ),
          if (!granted)
            TextButton(
              onPressed: () async {
                await ref.read(appUsageServiceProvider).requestUsagePermissionFlow();
                ref.invalidate(usagePermissionGrantedProvider);
              },
              child: const Text('Grant'),
            ),
        ],
      ),
    );
  }

  Widget _hourlyCard(List<HourlyUsageBucket> rows) {
    final highestDistracting = rows
        .where((r) => r.distractingMinutes > 0)
        .fold<HourlyUsageBucket?>(
          null,
          (best, row) =>
              best == null || row.distractingMinutes > best.distractingMinutes
              ? row
              : best,
        );
    final bestFocus = rows.where((r) => r.focusMinutes > 0).fold<HourlyUsageBucket?>(
      null,
      (best, row) => best == null || row.focusMinutes > best.focusMinutes ? row : best,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: LuxuryColors.cardBackground,
        border: Border.all(color: LuxuryColors.platinumBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HourlyUsageChart(buckets: rows),
          const SizedBox(height: 10),
          Text(
            'Most distracting hour: ${_hourLabel(highestDistracting?.hour)}',
            style: LuxuryTextStyles.bodyMedium,
          ),
          Text(
            'Best study hour: ${_hourLabel(bestFocus?.hour)}',
            style: LuxuryTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _glass(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: LuxuryColors.cardBackground,
        border: Border.all(color: LuxuryColors.subtleBorder),
      ),
      child: Text(text, style: LuxuryTextStyles.bodyMedium),
    );
  }

  Widget _empty(String message) {
    return Text(
      message,
      style: LuxuryTextStyles.bodyMedium.copyWith(color: LuxuryColors.textSecondary),
    );
  }

  Widget _loading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: LuxuryColors.platinumBlue,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: LuxuryTextStyles.labelLarge.copyWith(
        color: LuxuryColors.textSecondary,
        letterSpacing: 2,
      ),
    );
  }

  String _hourLabel(int? hour) {
    if (hour == null) return '--';
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h $period';
  }
}
