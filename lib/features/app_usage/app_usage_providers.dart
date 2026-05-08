import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_service.dart';
import '../stats/stats_service.dart';
import 'app_usage_models.dart';
import 'app_usage_service.dart';

final appUsageWindowDaysProvider = Provider<int>((ref) => 7);

final usagePermissionGrantedProvider = FutureProvider<bool>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  if (!settings.appUsageTrackingEnabled) return false;
  return ref.read(appUsageServiceProvider).isSupportedAndGranted();
});

final appUsageEntriesProvider = FutureProvider<List<AppUsageEntry>>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  if (!settings.appUsageTrackingEnabled) return [];

  final days = ref.watch(appUsageWindowDaysProvider);
  final service = ref.read(appUsageServiceProvider);
  final now = DateTime.now();
  final start = now.subtract(Duration(days: days));
  final hasPermission = await service.isUsageAccessGranted();
  if (!hasPermission) return service.getCachedUsageWindow(days: days);
  return service.refreshUsageWindow(start: start, end: now);
});

final topAppUsageProvider = FutureProvider<List<TopAppUsage>>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  if (!settings.appUsageTrackingEnabled) return const [];
  final days = ref.watch(appUsageWindowDaysProvider);
  return ref.read(appUsageServiceProvider).getTopApps(
        days: days,
        categoryOverrides: settings.appCategoryOverrides,
      );
});

final usageHourlyBucketsProvider = FutureProvider<List<HourlyUsageBucket>>((ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  final entries = await ref.watch(appUsageEntriesProvider.future);
  final sessions = await ref.watch(sessionHistoryProvider.future);

  final usageByHour = <int, int>{};
  final distractingByHour = <int, int>{};
  final studyTaggedByHour = <int, int>{};

  for (final item in entries) {
    usageByHour[item.hour] = (usageByHour[item.hour] ?? 0) + item.minutes;
    final category = AppCategory.fromKey(settings.appCategoryOverrides[item.packageName]);
    if (category == AppCategory.distracting) {
      distractingByHour[item.hour] =
          (distractingByHour[item.hour] ?? 0) + item.minutes;
    } else if (category == AppCategory.study) {
      studyTaggedByHour[item.hour] =
          (studyTaggedByHour[item.hour] ?? 0) + item.minutes;
    }
  }

  final focusByHour = _focusMinutesByHour(sessions);
  return List.generate(24, (hour) {
    return HourlyUsageBucket(
      hour: hour,
      totalMinutes: usageByHour[hour] ?? 0,
      distractingMinutes: distractingByHour[hour] ?? 0,
      studyTaggedMinutes: studyTaggedByHour[hour] ?? 0,
      focusMinutes: focusByHour[hour] ?? 0,
    );
  });
});

Map<int, int> _focusMinutesByHour(List<SessionRecord> sessions) {
  final buckets = <int, int>{};
  for (final session in sessions.where((s) => s.wasSuccessful)) {
    final endAt = session.completedAt;
    final startAt = session.startedAt ?? endAt.subtract(Duration(minutes: session.durationMinutes));
    if (!endAt.isAfter(startAt)) continue;

    var cursor = startAt;
    while (cursor.isBefore(endAt)) {
      final hourStart = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour);
      final hourEnd = hourStart.add(const Duration(hours: 1));
      final sliceEnd = hourEnd.isBefore(endAt) ? hourEnd : endAt;
      final minutes = sliceEnd.difference(cursor).inMinutes;
      if (minutes > 0) {
        buckets[cursor.hour] = (buckets[cursor.hour] ?? 0) + minutes;
      }
      cursor = sliceEnd;
    }
  }
  return buckets;
}
