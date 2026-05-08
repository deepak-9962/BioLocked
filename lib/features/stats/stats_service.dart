import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_usage/app_usage_models.dart';
import '../app_usage/app_usage_service.dart';
import '../settings/app_settings_service.dart';

/// A single session record for history.
///
/// [durationMinutes] is **elapsed** focus time (minutes from session start to end).
/// When present, [plannedDurationMinutes] is the timer goal chosen at setup.
class SessionRecord {
  final String id;
  final String taskName;
  final int durationMinutes;
  final DateTime completedAt;
  final bool wasSuccessful;
  final int energyLevel;
  final int interruptions;
  final int emergencyBreaks;
  final String lockLevel;
  final int? plannedDurationMinutes;
  final DateTime? startedAt;
  final String? failureReason;

  SessionRecord({
    required this.id,
    required this.taskName,
    required this.durationMinutes,
    required this.completedAt,
    required this.wasSuccessful,
    required this.energyLevel,
    this.interruptions = 0,
    this.emergencyBreaks = 0,
    this.lockLevel = 'standard',
    this.plannedDurationMinutes,
    this.startedAt,
    this.failureReason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskName': taskName,
    'durationMinutes': durationMinutes,
    'completedAt': completedAt.toIso8601String(),
    'wasSuccessful': wasSuccessful,
    'energyLevel': energyLevel,
    'interruptions': interruptions,
    'emergencyBreaks': emergencyBreaks,
    'lockLevel': lockLevel,
    if (plannedDurationMinutes != null) 'plannedDurationMinutes': plannedDurationMinutes,
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
    if (failureReason != null) 'failureReason': failureReason,
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    id: json['id'] ?? '',
    taskName: json['taskName'] ?? '',
    durationMinutes: json['durationMinutes'] ?? 0,
    completedAt: DateTime.parse(json['completedAt']),
    wasSuccessful: json['wasSuccessful'] ?? true,
    energyLevel: json['energyLevel'] ?? 50,
    interruptions: json['interruptions'] ?? 0,
    emergencyBreaks: json['emergencyBreaks'] ?? 0,
    lockLevel: json['lockLevel'] ?? 'standard',
    plannedDurationMinutes: json['plannedDurationMinutes'] as int?,
    startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
    failureReason: json['failureReason'] as String?,
  );
}

class WeeklyAnalytics {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalFocusMinutes;
  final int successfulSessions;
  final int failedSessions;
  final int totalInterruptions;
  final int emergencyBreaks;
  final int? bestHour;
  final int? toughestHour;

  const WeeklyAnalytics({
    required this.weekStart,
    required this.weekEnd,
    required this.totalFocusMinutes,
    required this.successfulSessions,
    required this.failedSessions,
    required this.totalInterruptions,
    required this.emergencyBreaks,
    required this.bestHour,
    required this.toughestHour,
  });

  int get totalSessions => successfulSessions + failedSessions;

  double get successRate {
    if (totalSessions == 0) return 0;
    return successfulSessions / totalSessions;
  }
}

/// Four trailing calendar weeks of session success rates (index 0 = oldest week).
class RollingCompletionTrends {
  final List<double> weeklySuccessRates;
  final int longestSuccessfulSessionRun;
  final double recoveryRateAfterFailure;

  const RollingCompletionTrends({
    required this.weeklySuccessRates,
    required this.longestSuccessfulSessionRun,
    required this.recoveryRateAfterFailure,
  });
}

class LockLevelStatsRow {
  final String lockLevel;
  final int totalMinutesSuccessful;
  final int sessionsTotal;
  final int sessionsSuccessful;
  final double emergencyBreaksPerSession;

  double get successRate =>
      sessionsTotal == 0 ? 0 : sessionsSuccessful / sessionsTotal;

  const LockLevelStatsRow({
    required this.lockLevel,
    required this.totalMinutesSuccessful,
    required this.sessionsTotal,
    required this.sessionsSuccessful,
    required this.emergencyBreaksPerSession,
  });
}

class SessionLengthDistribution {
  final Map<int, int> histogramMinutesBucket;
  final double avgCompletedLength;
  final double avgFailedLength;

  const SessionLengthDistribution({
    required this.histogramMinutesBucket,
    required this.avgCompletedLength,
    required this.avgFailedLength,
  });
}

class InterruptionIntensitySummary {
  final double avgInterruptionsPerCompletedSession;
  final double percentSessionsZeroInterruptions;
  final double avgInterruptionsWhenPickupHeavyLock;

  const InterruptionIntensitySummary({
    required this.avgInterruptionsPerCompletedSession,
    required this.percentSessionsZeroInterruptions,
    required this.avgInterruptionsWhenPickupHeavyLock,
  });
}

class EnergyBandSummary {
  final String bandLabel;
  final int sessions;
  final double successRate;
  final double avgInterruptions;

  const EnergyBandSummary({
    required this.bandLabel,
    required this.sessions,
    required this.successRate,
    required this.avgInterruptions,
  });
}

/// Parsed failure labels from stored reasons / SessionRecords.
class FailureTaxonomySummary {
  final Map<String, int> countsByCategory;

  const FailureTaxonomySummary({required this.countsByCategory});
}

class ConsistencyReport {
  final double consistencyScore30d;
  final int activeDaysLast30;
  final int currentWeekSuccessfulMinutes;
  final int previousWeekSuccessfulMinutes;
  final int currentWeekSessionCount;
  final int previousWeekSessionCount;

  const ConsistencyReport({
    required this.consistencyScore30d,
    required this.activeDaysLast30,
    required this.currentWeekSuccessfulMinutes,
    required this.previousWeekSuccessfulMinutes,
    required this.currentWeekSessionCount,
    required this.previousWeekSessionCount,
  });
}

/// Focus minutes by weekday (1=Mon..7=Sun) and clock hour.
class FocusHeatmapSummary {
  final Map<String, int> weekdayHourToMinutes;

  const FocusHeatmapSummary({required this.weekdayHourToMinutes});
}

class TaskLeaderboardEntry {
  final String taskName;
  final int totalMinutes;
  final int sessionCount;
  final int successfulCount;
  final double avgInterruptions;

  double get successRate =>
      sessionCount == 0 ? 0 : successfulCount / sessionCount;

  const TaskLeaderboardEntry({
    required this.taskName,
    required this.totalMinutes,
    required this.sessionCount,
    required this.successfulCount,
    required this.avgInterruptions,
  });
}

/// Tier-A analytics bundle + coach strings for the Insights screen.
class InsightsAnalyticsBundle {
  final RollingCompletionTrends rollingTrends;
  final Map<String, LockLevelStatsRow> lockLevelBreakdown;
  final SessionLengthDistribution lengthDistribution;
  final InterruptionIntensitySummary interruptionIntensity;
  final List<EnergyBandSummary> energyBands;
  final FailureTaxonomySummary failureTaxonomy;
  final ConsistencyReport consistency;
  final FocusHeatmapSummary focusHeatmap;
  final List<TaskLeaderboardEntry> taskLeaderboard;
  final List<TopAppUsage> topAppsWeek;
  final List<HourlyUsageBucket> usageHourly;
  final int? highestDistractionHour;
  final int? bestStudyHour;
  final double studyVsDistractingRatio;
  final List<String> coachInsights;
  /// Clock hour (0–23) when successful sessions **ended**; median across sessions.
  final int? medianSuccessfulCompletionHour;

  const InsightsAnalyticsBundle({
    required this.rollingTrends,
    required this.lockLevelBreakdown,
    required this.lengthDistribution,
    required this.interruptionIntensity,
    required this.energyBands,
    required this.failureTaxonomy,
    required this.consistency,
    required this.focusHeatmap,
    required this.taskLeaderboard,
    required this.topAppsWeek,
    required this.usageHourly,
    required this.highestDistractionHour,
    required this.bestStudyHour,
    required this.studyVsDistractingRatio,
    required this.coachInsights,
    required this.medianSuccessfulCompletionHour,
  });
}

/// Local stats for tracking achievements and streaks
class UserStats {
  int totalSessions;
  int totalMinutes;
  int currentStreak;
  int longestStreak;
  /// Completed sessions with **zero** pickup interruptions (see [recordSessionComplete]).
  int perfectSessions;
  DateTime? lastSessionDate;
  List<String> recentFailureReasons;
  List<String> earnedAchievements;

  UserStats({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.perfectSessions = 0,
    this.lastSessionDate,
    List<String>? recentFailureReasons,
    List<String>? earnedAchievements,
  }) : recentFailureReasons = recentFailureReasons ?? [],
       earnedAchievements = earnedAchievements ?? [];

  Map<String, dynamic> toJson() => {
    'totalSessions': totalSessions,
    'totalMinutes': totalMinutes,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'perfectSessions': perfectSessions,
    'lastSessionDate': lastSessionDate?.toIso8601String(),
    'recentFailureReasons': recentFailureReasons,
    'earnedAchievements': earnedAchievements,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalSessions: json['totalSessions'] ?? 0,
    totalMinutes: json['totalMinutes'] ?? 0,
    currentStreak: json['currentStreak'] ?? 0,
    longestStreak: json['longestStreak'] ?? 0,
    perfectSessions: json['perfectSessions'] ?? 0,
    lastSessionDate: json['lastSessionDate'] != null 
        ? DateTime.parse(json['lastSessionDate']) 
        : null,
    recentFailureReasons: List<String>.from(json['recentFailureReasons'] ?? []),
    earnedAchievements: List<String>.from(json['earnedAchievements'] ?? []),
  );
}

class StatsService {
  static const _storage = FlutterSecureStorage();
  static const _statsKey = 'user_stats';
  static const _historyKey = 'session_history';
  final _settingsService = AppSettingsService();
  final _appUsageService = AppUsageService();

  Future<UserStats> getStats() async {
    final data = await _storage.read(key: _statsKey);
    if (data == null) return UserStats();
    try {
      return UserStats.fromJson(jsonDecode(data));
    } catch (e) {
      return UserStats();
    }
  }

  Future<void> saveStats(UserStats stats) async {
    await _storage.write(key: _statsKey, value: jsonEncode(stats.toJson()));
  }

  /// Get session history
  Future<List<SessionRecord>> getSessionHistory() async {
    final data = await _storage.read(key: _historyKey);
    if (data == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((j) => SessionRecord.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a session to history
  Future<void> _saveSessionToHistory(SessionRecord session) async {
    final history = await getSessionHistory();
    history.add(session);
    // Keep last 100 sessions
    if (history.length > 100) {
      history.removeRange(0, history.length - 100);
    }
    await _storage.write(
      key: _historyKey,
      value: jsonEncode(history.map((s) => s.toJson()).toList()),
    );
  }

  /// Get sessions for a specific date
  Future<List<SessionRecord>> getSessionsForDate(DateTime date) async {
    final history = await getSessionHistory();
    return history.where((s) {
      return s.completedAt.year == date.year &&
          s.completedAt.month == date.month &&
          s.completedAt.day == date.day;
    }).toList();
  }

  /// Get daily focus minutes for the last N days (for heatmap)
  Future<Map<DateTime, int>> getDailyMinutes({int days = 30}) async {
    final history = await getSessionHistory();
    final now = DateTime.now();
    final result = <DateTime, int>{};
    
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      result[date] = 0;
    }
    
    for (final session in history) {
      if (!session.wasSuccessful) continue;

      final date = DateTime(
        session.completedAt.year,
        session.completedAt.month,
        session.completedAt.day,
      );
      if (result.containsKey(date)) {
        result[date] = result[date]! + session.durationMinutes;
      }
    }
    
    return result;
  }

  /// Record a completed session and check for new achievements
  Future<List<String>> recordSessionComplete({
    required int durationMinutes,
    required bool hadFailures,
    String taskName = '',
    int energyLevel = 50,
    int interruptions = 0,
    int emergencyBreaks = 0,
    String lockLevel = 'standard',
    int? plannedDurationMinutes,
    DateTime? startedAt,
  }) async {
    final stats = await getStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Save session to history
    await _saveSessionToHistory(SessionRecord(
      id: now.millisecondsSinceEpoch.toString(),
      taskName: taskName,
      durationMinutes: durationMinutes,
      completedAt: now,
      wasSuccessful: !hadFailures,
      energyLevel: energyLevel,
      interruptions: interruptions,
      emergencyBreaks: emergencyBreaks,
      lockLevel: lockLevel,
      plannedDurationMinutes: plannedDurationMinutes,
      startedAt: startedAt,
    ));
    
    // Update totals
    stats.totalSessions++;
    stats.totalMinutes += durationMinutes;
    
    final trulyPerfectPickup = interruptions == 0 && !hadFailures;
    if (trulyPerfectPickup) {
      stats.perfectSessions++;
    }
    
    // Update streak
    if (stats.lastSessionDate != null) {
      final lastDate = DateTime(
        stats.lastSessionDate!.year,
        stats.lastSessionDate!.month,
        stats.lastSessionDate!.day,
      );
      final difference = today.difference(lastDate).inDays;
      
      if (difference == 0) {
        // Same day, streak continues
      } else if (difference == 1) {
        // Next day, streak increases
        stats.currentStreak++;
      } else {
        // Streak broken
        stats.currentStreak = 1;
      }
    } else {
      stats.currentStreak = 1;
    }
    
    if (stats.currentStreak > stats.longestStreak) {
      stats.longestStreak = stats.currentStreak;
    }
    
    stats.lastSessionDate = now;
    
    // Check for new achievements
    final newAchievements = <String>[];
    
    // First session
    if (stats.totalSessions == 1 && !stats.earnedAchievements.contains('first_session')) {
      newAchievements.add('first_session');
      stats.earnedAchievements.add('first_session');
    }
    
    // Streak achievements
    if (stats.currentStreak >= 7 && !stats.earnedAchievements.contains('streak_7')) {
      newAchievements.add('streak_7');
      stats.earnedAchievements.add('streak_7');
    }
    if (stats.currentStreak >= 30 && !stats.earnedAchievements.contains('streak_30')) {
      newAchievements.add('streak_30');
      stats.earnedAchievements.add('streak_30');
    }
    
    // Hours achievements
    final totalHours = stats.totalMinutes ~/ 60;
    if (totalHours >= 10 && !stats.earnedAchievements.contains('hours_10')) {
      newAchievements.add('hours_10');
      stats.earnedAchievements.add('hours_10');
    }
    if (totalHours >= 100 && !stats.earnedAchievements.contains('hours_100')) {
      newAchievements.add('hours_100');
      stats.earnedAchievements.add('hours_100');
    }
    
    // Zero-interruption streak milestone (aligned with coins perfect-session bonus).
    if (stats.perfectSessions >= 10 && !stats.earnedAchievements.contains('no_failures_10')) {
      newAchievements.add('no_failures_10');
      stats.earnedAchievements.add('no_failures_10');
    }
    
    await saveStats(stats);
    return newAchievements;
  }

  /// Record a failed session
  Future<void> recordSessionFailed(
    String reason, {
    int durationMinutes = 0,
    String taskName = '',
    int energyLevel = 50,
    int interruptions = 0,
    int emergencyBreaks = 0,
    String lockLevel = 'standard',
    int? plannedDurationMinutes,
    DateTime? startedAt,
  }) async {
    final stats = await getStats();
    final now = DateTime.now();

    await _saveSessionToHistory(
      SessionRecord(
        id: 'failed_${now.millisecondsSinceEpoch}',
        taskName: taskName,
        durationMinutes: durationMinutes,
        completedAt: now,
        wasSuccessful: false,
        energyLevel: energyLevel,
        interruptions: interruptions,
        emergencyBreaks: emergencyBreaks,
        lockLevel: lockLevel,
        failureReason: reason,
        plannedDurationMinutes: plannedDurationMinutes,
        startedAt: startedAt,
      ),
    );
    
    // Add to recent failures (keep last 5)
    stats.recentFailureReasons.add(reason);
    if (stats.recentFailureReasons.length > 5) {
      stats.recentFailureReasons.removeAt(0);
    }

    // Emergency breaks carry an immediate streak penalty.
    if (reason.toLowerCase().contains('emergency break')) {
      if (stats.currentStreak > 0) {
        stats.currentStreak = stats.currentStreak - 1;
      }
    }
    
    await saveStats(stats);
  }

  Future<WeeklyAnalytics> getWeeklyAnalytics() async {
    final history = await getSessionHistory();
    final now = DateTime.now();
    final weekEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final weekSessions = history.where((session) {
      return !session.completedAt.isBefore(weekStart) &&
          !session.completedAt.isAfter(weekEnd);
    }).toList();

    final successful = weekSessions.where((s) => s.wasSuccessful).toList();
    final failed = weekSessions.where((s) => !s.wasSuccessful).length;

    final totalFocusMinutes = successful.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final totalInterruptions = weekSessions.fold<int>(
      0,
      (sum, session) => sum + session.interruptions,
    );
    final emergencyBreaks = weekSessions.fold<int>(
      0,
      (sum, session) => sum + session.emergencyBreaks,
    );

    final minutesByHour = _studyMinutesByHour(successful);

    int? bestHour;
    int? toughestHour;
    if (minutesByHour.isNotEmpty) {
      final sorted = minutesByHour.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      bestHour = sorted.first.key;
      toughestHour = sorted.last.key;
    }

    return WeeklyAnalytics(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalFocusMinutes: totalFocusMinutes,
      successfulSessions: successful.length,
      failedSessions: failed,
      totalInterruptions: totalInterruptions,
      emergencyBreaks: emergencyBreaks,
      bestHour: bestHour,
      toughestHour: toughestHour,
    );
  }

  /// Get time of day category
  String getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'early_morning';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  /// Check if streak is at risk
  Future<bool> isStreakAtRisk() async {
    final stats = await getStats();
    if (stats.currentStreak == 0 || stats.lastSessionDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      stats.lastSessionDate!.year,
      stats.lastSessionDate!.month,
      stats.lastSessionDate!.day,
    );
    
  // If last session was yesterday and it's getting late, streak is at risk
    final difference = today.difference(lastDate).inDays;
    return difference >= 1 || (difference == 0 && now.hour >= 20);
  }

  /// Get distraction heatmap data: "weekday-hour" -> count
  /// weekday: 1 (Mon) to 7 (Sun)
  Future<Map<String, int>> getDistractionHeatmap() async {
    final history = await getSessionHistory();
    final heatmap = <String, int>{};

    for (final session in history) {
      if (session.interruptions > 0) {
        final weekday = session.completedAt.weekday;
        final hour = session.completedAt.hour;
        final key = '$weekday-$hour';
        heatmap[key] = (heatmap[key] ?? 0) + session.interruptions;
      }
    }

    return heatmap;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Minutes aggregated when sessions ended (proxy until full session-start telemetry everywhere).
  Future<Map<String, int>> getFocusMinutesHeatmap() async {
    final history = await getSessionHistory();
    return _studyMinutesByWeekdayHour(history.where((s) => s.wasSuccessful).toList());
  }

  Map<int, int> _studyMinutesByHour(List<SessionRecord> sessions) {
    final buckets = <int, int>{};
    for (final session in sessions) {
      _distributeSessionAcrossHours(session, (hour, minutes, {required weekday}) {
        buckets[hour] = (buckets[hour] ?? 0) + minutes;
      });
    }
    return buckets;
  }

  Map<String, int> _studyMinutesByWeekdayHour(List<SessionRecord> sessions) {
    final heatmap = <String, int>{};
    for (final session in sessions) {
      _distributeSessionAcrossHours(session, (hour, minutes, {required weekday}) {
        final key = '$weekday-$hour';
        heatmap[key] = (heatmap[key] ?? 0) + minutes;
      });
    }
    return heatmap;
  }

  void _distributeSessionAcrossHours(
    SessionRecord session,
    void Function(int hour, int minutes, {required int weekday}) onSlice,
  ) {
    final endAt = session.completedAt;
    final startAt =
        session.startedAt ?? endAt.subtract(Duration(minutes: session.durationMinutes));
    if (!endAt.isAfter(startAt)) return;
    var cursor = startAt;
    while (cursor.isBefore(endAt)) {
      final hourStart = DateTime(cursor.year, cursor.month, cursor.day, cursor.hour);
      final hourEnd = hourStart.add(const Duration(hours: 1));
      final sliceEnd = hourEnd.isBefore(endAt) ? hourEnd : endAt;
      final minutes = sliceEnd.difference(cursor).inMinutes;
      if (minutes > 0) {
        onSlice(cursor.hour, minutes, weekday: cursor.weekday);
      }
      cursor = sliceEnd;
    }
  }

  RollingCompletionTrends _computeRollingTrends(List<SessionRecord> history) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final rates = <double>[];

    for (var w = 3; w >= 0; w--) {
      final weekEnd = today.subtract(Duration(days: w * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      final inWeek = history.where((s) {
        final d = _dateOnly(s.completedAt);
        return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
      }).toList();
      final ok = inWeek.where((s) => s.wasSuccessful).length;
      final total = inWeek.length;
      rates.add(total == 0 ? 0 : ok / total);
    }

    final chronological = [...history]..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    var bestRun = 0;
    var run = 0;
    for (final s in chronological) {
      if (s.wasSuccessful) {
        run++;
        if (run > bestRun) bestRun = run;
      } else {
        run = 0;
      }
    }

    final failDates = <DateTime>{};
    final successDates = <DateTime>{};
    for (final s in history) {
      final d = _dateOnly(s.completedAt);
      if (s.wasSuccessful) {
        successDates.add(d);
      } else {
        failDates.add(d);
      }
    }

    var recoveryEligible = 0;
    var recoveryMade = 0;
    for (final fd in failDates) {
      recoveryEligible++;
      final nextDay = fd.add(const Duration(days: 1));
      if (successDates.contains(nextDay)) recoveryMade++;
    }
    final recoveryRate =
        recoveryEligible == 0 ? 1.0 : recoveryMade / recoveryEligible;

    return RollingCompletionTrends(
      weeklySuccessRates: rates,
      longestSuccessfulSessionRun: bestRun,
      recoveryRateAfterFailure: recoveryRate,
    );
  }

  Map<String, LockLevelStatsRow> _lockBreakdown(List<SessionRecord> history) {
    final levels = ['soft', 'standard', 'hard'];
    final result = <String, LockLevelStatsRow>{};
    for (final level in levels) {
      final subset = history.where((s) => s.lockLevel == level).toList();
      if (subset.isEmpty) {
        result[level] = LockLevelStatsRow(
          lockLevel: level,
          totalMinutesSuccessful: 0,
          sessionsTotal: 0,
          sessionsSuccessful: 0,
          emergencyBreaksPerSession: 0,
        );
        continue;
      }
      final ok = subset.where((s) => s.wasSuccessful).toList();
      final minutes =
          ok.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final emergencySum =
          subset.fold<int>(0, (sum, s) => sum + s.emergencyBreaks);
      result[level] = LockLevelStatsRow(
        lockLevel: level,
        totalMinutesSuccessful: minutes,
        sessionsTotal: subset.length,
        sessionsSuccessful: ok.length,
        emergencyBreaksPerSession:
            subset.isEmpty ? 0 : emergencySum / subset.length,
      );
    }
    return result;
  }

  SessionLengthDistribution _lengthDistribution(List<SessionRecord> history) {
    final hist = <int, int>{};
    final completed =
        history.where((s) => s.wasSuccessful).toList();
    final failed =
        history.where((s) => !s.wasSuccessful).toList();

    for (final s in completed) {
      final bucket = ((s.durationMinutes / 15).floor() * 15).clamp(0, 180);
      hist[bucket] = (hist[bucket] ?? 0) + 1;
    }

    final avgOk = completed.isEmpty
        ? 0.0
        : completed.fold<double>(
              0,
              (sum, s) => sum + s.durationMinutes,
            ) /
            completed.length;
    final avgFail = failed.isEmpty
        ? 0.0
        : failed.fold<double>(
              0,
              (sum, s) => sum + s.durationMinutes,
            ) /
            failed.length;

    return SessionLengthDistribution(
      histogramMinutesBucket: hist,
      avgCompletedLength: avgOk,
      avgFailedLength: avgFail,
    );
  }

  InterruptionIntensitySummary _interruptionIntensity(List<SessionRecord> history) {
    final completed =
        history.where((s) => s.wasSuccessful).toList();
    if (completed.isEmpty) {
      return const InterruptionIntensitySummary(
        avgInterruptionsPerCompletedSession: 0,
        percentSessionsZeroInterruptions: 0,
        avgInterruptionsWhenPickupHeavyLock: 0,
      );
    }
    final sumPickups =
        completed.fold<double>(0, (sum, s) => sum + s.interruptions);
    final zero = completed.where((s) => s.interruptions == 0).length;

    final heavyWithPickup = completed.where(
      (s) =>
          (s.lockLevel == 'hard' || s.lockLevel == 'standard') &&
          s.interruptions > 0,
    ).toList();
    final heavyAvg = heavyWithPickup.isEmpty
        ? 0.0
        : heavyWithPickup.fold<double>(
              0,
              (sum, s) => sum + s.interruptions,
            ) /
            heavyWithPickup.length;

    return InterruptionIntensitySummary(
      avgInterruptionsPerCompletedSession: sumPickups / completed.length,
      percentSessionsZeroInterruptions: zero / completed.length,
      avgInterruptionsWhenPickupHeavyLock: heavyAvg,
    );
  }

  List<EnergyBandSummary> _energyBands(List<SessionRecord> history) {
    String band(int energy) {
      if (energy < 40) return 'Low energy';
      if (energy < 70) return 'Medium energy';
      return 'High energy';
    }

    final groups = <String, List<SessionRecord>>{};
    for (final s in history) {
      final b = band(s.energyLevel);
      groups.putIfAbsent(b, () => []).add(s);
    }

    final labels = ['Low energy', 'Medium energy', 'High energy'];
    return labels.map((label) {
      final subset = groups[label] ?? [];
      if (subset.isEmpty) {
        return EnergyBandSummary(
          bandLabel: label,
          sessions: 0,
          successRate: 0,
          avgInterruptions: 0,
        );
      }
      final ok = subset.where((s) => s.wasSuccessful).length;
      final pickupSum =
          subset.fold<double>(0, (sum, s) => sum + s.interruptions);
      return EnergyBandSummary(
        bandLabel: label,
        sessions: subset.length,
        successRate: ok / subset.length,
        avgInterruptions: pickupSum / subset.length,
      );
    }).toList();
  }

  String _failureCategory(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('emergency')) return 'Emergency break';
    if (r.contains('lift')) return 'Device lifted too long';
    if (r.contains('abandon')) return 'Session abandoned';
    return 'Other / misc';
  }

  FailureTaxonomySummary _failureTaxonomy(List<SessionRecord> history) {
    final counts = <String, int>{};
    for (final s in history) {
      if (s.wasSuccessful) continue;
      final reason = s.failureReason ?? 'Unknown';
      final cat = _failureCategory(reason);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return FailureTaxonomySummary(countsByCategory: counts);
  }

  ConsistencyReport _consistency(List<SessionRecord> history) {
    final today = _dateOnly(DateTime.now());
    final activeDays = <DateTime>{};
    for (var i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      final hasWin = history.any((s) {
        final d = _dateOnly(s.completedAt);
        return d == day && s.wasSuccessful;
      });
      if (hasWin) activeDays.add(day);
    }

    int minutesForWeekEnding(DateTime weekEnd) {
      final start = weekEnd.subtract(const Duration(days: 6));
      return history
          .where((s) =>
              s.wasSuccessful &&
              !_dateOnly(s.completedAt).isBefore(start) &&
              !_dateOnly(s.completedAt).isAfter(weekEnd))
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    }

    int sessionsForWeekEnding(DateTime weekEnd) {
      final start = weekEnd.subtract(const Duration(days: 6));
      return history
          .where((s) =>
              !_dateOnly(s.completedAt).isBefore(start) &&
              !_dateOnly(s.completedAt).isAfter(weekEnd))
          .length;
    }

    final curWeekEnd = today;
    final prevWeekEnd = curWeekEnd.subtract(const Duration(days: 7));

    return ConsistencyReport(
      consistencyScore30d: activeDays.length / 30,
      activeDaysLast30: activeDays.length,
      currentWeekSuccessfulMinutes: minutesForWeekEnding(curWeekEnd),
      previousWeekSuccessfulMinutes: minutesForWeekEnding(prevWeekEnd),
      currentWeekSessionCount: sessionsForWeekEnding(curWeekEnd),
      previousWeekSessionCount: sessionsForWeekEnding(prevWeekEnd),
    );
  }

  List<TaskLeaderboardEntry> _taskLeaderboard(List<SessionRecord> history) {
    final byTask = <String, List<SessionRecord>>{};
    for (final s in history) {
      final name =
          s.taskName.trim().isEmpty ? '(Untitled task)' : s.taskName.trim();
      byTask.putIfAbsent(name, () => []).add(s);
    }
    final entries = byTask.entries.map((e) {
      final list = e.value;
      final ok = list.where((s) => s.wasSuccessful).toList();
      final mins =
          ok.fold<int>(0, (sum, s) => sum + s.durationMinutes);
      final pickupSum =
          list.fold<double>(0, (sum, s) => sum + s.interruptions);
      return TaskLeaderboardEntry(
        taskName: e.key,
        totalMinutes: mins,
        sessionCount: list.length,
        successfulCount: ok.length,
        avgInterruptions: list.isEmpty ? 0 : pickupSum / list.length,
      );
    }).toList()
      ..sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return entries.take(12).toList();
  }

  List<TopAppUsage> _computeTopApps(
    List<AppUsageEntry> entries,
    Map<String, String> categoryOverrides, {
    int limit = 8,
  }) {
    final map = <String, TopAppUsage>{};
    for (final row in entries) {
      final existing = map[row.packageName];
      final nextMinutes = (existing?.minutes ?? 0) + row.minutes;
      map[row.packageName] = TopAppUsage(
        packageName: row.packageName,
        appLabel: row.appLabel.isEmpty ? (existing?.appLabel ?? row.packageName) : row.appLabel,
        minutes: nextMinutes,
        category: AppCategory.fromKey(categoryOverrides[row.packageName]),
      );
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));
    return sorted.take(limit).toList();
  }

  List<HourlyUsageBucket> _mergeStudyAndUsageHourly(
    List<AppUsageEntry> usageEntries,
    List<SessionRecord> history,
    Map<String, String> categoryOverrides,
  ) {
    final totalByHour = <int, int>{};
    final distractingByHour = <int, int>{};
    final studyTaggedByHour = <int, int>{};
    for (final row in usageEntries) {
      totalByHour[row.hour] = (totalByHour[row.hour] ?? 0) + row.minutes;
      final category = AppCategory.fromKey(categoryOverrides[row.packageName]);
      if (category == AppCategory.distracting) {
        distractingByHour[row.hour] = (distractingByHour[row.hour] ?? 0) + row.minutes;
      }
      if (category == AppCategory.study) {
        studyTaggedByHour[row.hour] = (studyTaggedByHour[row.hour] ?? 0) + row.minutes;
      }
    }

    final focusByHour =
        _studyMinutesByHour(history.where((s) => s.wasSuccessful).toList());
    return List.generate(24, (hour) {
      return HourlyUsageBucket(
        hour: hour,
        totalMinutes: totalByHour[hour] ?? 0,
        distractingMinutes: distractingByHour[hour] ?? 0,
        studyTaggedMinutes: studyTaggedByHour[hour] ?? 0,
        focusMinutes: focusByHour[hour] ?? 0,
      );
    });
  }

  List<String> _coachInsights(
    InsightsAnalyticsBundle bundle,
    List<SessionRecord> history,
  ) {
    final lines = <String>[];
    final locks = bundle.lockLevelBreakdown;

    double rate(String k) => locks[k]?.successRate ?? 0;
    int n(String k) => locks[k]?.sessionsTotal ?? 0;

    if (n('hard') >= 2 &&
        n('soft') >= 2 &&
        rate('hard') > rate('soft') + 0.12) {
      lines.add(
        'Hard lock sessions finish more reliably than soft lock for you recently — consider standard/hard for deep blocks.',
      );
    }

    if (bundle.consistency.currentWeekSuccessfulMinutes >
            bundle.consistency.previousWeekSuccessfulMinutes &&
        bundle.consistency.previousWeekSuccessfulMinutes > 0) {
      lines.add(
        'This week already beats last week on focused minutes — momentum is compounding.',
      );
    } else if (bundle.consistency.currentWeekSuccessfulMinutes <
            bundle.consistency.previousWeekSuccessfulMinutes * 0.7 &&
        bundle.consistency.previousWeekSuccessfulMinutes >= 45) {
      lines.add(
        'Focused minutes dipped vs last week — one shorter tunnel today still protects your streak psychology.',
      );
    }

    if (bundle.interruptionIntensity.percentSessionsZeroInterruptions >= 0.5 &&
        history.where((s) => s.wasSuccessful).length >= 5) {
      lines.add(
        'Over half of completed sessions had zero pickups — elite phone discipline.',
      );
    }

    if (bundle.failureTaxonomy.countsByCategory['Device lifted too long'] !=
            null &&
        bundle.failureTaxonomy.countsByCategory['Device lifted too long']! >=
            3) {
      lines.add(
        'Most friction came from lifting the device — softer lock or shorter tunnels might rebuild tolerance.',
      );
    }

    if (bundle.energyBands.any((b) => b.bandLabel == 'Low energy' && b.sessions >= 3)) {
      final low =
          bundle.energyBands.firstWhere((b) => b.bandLabel == 'Low energy');
      if (low.successRate < 0.45 && low.sessions >= 4) {
        lines.add(
          'Completion rate is tougher on low-energy days — shorter sessions then beat heroic failures.',
        );
      }
    }

    if (bundle.highestDistractionHour != null && bundle.bestStudyHour != null) {
      if (bundle.highestDistractionHour == bundle.bestStudyHour) {
        lines.add(
          'Your top study hour is also your highest distraction hour — blocking distracting apps in that window should unlock cleaner focus.',
        );
      }
    }

    if (bundle.studyVsDistractingRatio < 1.0 && bundle.studyVsDistractingRatio > 0) {
      lines.add(
        'Distracting app time currently outweighs focus time — protecting a fixed daily focus block will rebalance this quickly.',
      );
    }

    if (lines.isEmpty) {
      lines.add(
        'Keep logging tunnels — as history grows, insights here become sharper week over week.',
      );
    }
    return lines.take(5).toList();
  }

  Future<InsightsAnalyticsBundle> getInsightsAnalytics() async {
    final history = await getSessionHistory();
    final settings = await _settingsService.load();
    final rolling = _computeRollingTrends(history);
    final locks = _lockBreakdown(history);
    final length = _lengthDistribution(history);
    final interrupts = _interruptionIntensity(history);
    final energy = _energyBands(history);
    final failures = _failureTaxonomy(history);
    final consistency = _consistency(history);
    final focusHeat =
        FocusHeatmapSummary(weekdayHourToMinutes: await getFocusMinutesHeatmap());
    final tasks = _taskLeaderboard(history);
    final now = DateTime.now();
    final usageStart = now.subtract(const Duration(days: 7));
    List<AppUsageEntry> usageRows = [];
    if (settings.appUsageTrackingEnabled) {
      try {
        final granted = await _appUsageService.isUsageAccessGranted();
        usageRows = granted
            ? await _appUsageService.refreshUsageWindow(start: usageStart, end: now)
            : await _appUsageService.getCachedUsageWindow(days: 7);
      } catch (_) {
        usageRows = await _appUsageService.getCachedUsageWindow(days: 7);
      }
    }
    final topApps = _computeTopApps(
      usageRows,
      settings.appCategoryOverrides,
    );
    final usageHourly = _mergeStudyAndUsageHourly(
      usageRows,
      history,
      settings.appCategoryOverrides,
    );
    final highestDistractionHour = usageHourly
        .where((r) => r.distractingMinutes > 0)
        .fold<HourlyUsageBucket?>(
          null,
          (best, row) =>
              best == null || row.distractingMinutes > best.distractingMinutes
              ? row
              : best,
        )
        ?.hour;
    final bestStudyHour = usageHourly
        .where((r) => r.focusMinutes > 0)
        .fold<HourlyUsageBucket?>(
          null,
          (best, row) =>
              best == null || row.focusMinutes > best.focusMinutes ? row : best,
        )
        ?.hour;
    final totalDistracting = usageHourly.fold<int>(
      0,
      (sum, row) => sum + row.distractingMinutes,
    );
    final totalFocus = usageHourly.fold<int>(0, (sum, row) => sum + row.focusMinutes);
    final studyVsDistractingRatio = totalDistracting == 0
        ? (totalFocus > 0 ? totalFocus.toDouble() : 0.0)
        : totalFocus / totalDistracting;

    final successHours = history
        .where((s) => s.wasSuccessful)
        .map((s) => s.completedAt.hour)
        .toList()
      ..sort();
    final medianHour = successHours.isEmpty
        ? null
        : successHours[successHours.length ~/ 2];

    final bundle = InsightsAnalyticsBundle(
      rollingTrends: rolling,
      lockLevelBreakdown: locks,
      lengthDistribution: length,
      interruptionIntensity: interrupts,
      energyBands: energy,
      failureTaxonomy: failures,
      consistency: consistency,
      focusHeatmap: focusHeat,
      taskLeaderboard: tasks,
      topAppsWeek: topApps,
      usageHourly: usageHourly,
      highestDistractionHour: highestDistractionHour,
      bestStudyHour: bestStudyHour,
      studyVsDistractingRatio: studyVsDistractingRatio,
      coachInsights: const [],
      medianSuccessfulCompletionHour: medianHour,
    );
    final coach = _coachInsights(bundle, history);
    return InsightsAnalyticsBundle(
      rollingTrends: rolling,
      lockLevelBreakdown: locks,
      lengthDistribution: length,
      interruptionIntensity: interrupts,
      energyBands: energy,
      failureTaxonomy: failures,
      consistency: consistency,
      focusHeatmap: focusHeat,
      taskLeaderboard: tasks,
      topAppsWeek: topApps,
      usageHourly: usageHourly,
      highestDistractionHour: highestDistractionHour,
      bestStudyHour: bestStudyHour,
      studyVsDistractingRatio: studyVsDistractingRatio,
      coachInsights: coach,
      medianSuccessfulCompletionHour: medianHour,
    );
  }

  static String _csvEscape(String? field) {
    if (field == null || field.isEmpty) return '';
    final s = field;
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  Future<File> exportHistoryToCsvFile() async {
    final history = await getSessionHistory();
    final buffer = StringBuffer();
    buffer.writeln(
      'id,taskName,durationMinutes,plannedDurationMinutes,startedAt,completedAt,successful,energyLevel,interruptions,emergencyBreaks,lockLevel,failureReason',
    );
    for (final s in history) {
      buffer.writeln([
        _csvEscape(s.id),
        _csvEscape(s.taskName),
        s.durationMinutes,
        s.plannedDurationMinutes ?? '',
        s.startedAt?.toIso8601String() ?? '',
        s.completedAt.toIso8601String(),
        s.wasSuccessful,
        s.energyLevel,
        s.interruptions,
        s.emergencyBreaks,
        _csvEscape(s.lockLevel),
        _csvEscape(s.failureReason),
      ].join(','));
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/bio_locked_sessions_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  Future<void> shareHistoryCsv() async {
    final file = await exportHistoryToCsvFile();
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Bio-Locked session export',
    );
  }
}

final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  return ref.read(statsServiceProvider).getStats();
});

final weeklyAnalyticsProvider = FutureProvider<WeeklyAnalytics>((ref) async {
  return ref.read(statsServiceProvider).getWeeklyAnalytics();
});

final distractionHeatmapProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(statsServiceProvider).getDistractionHeatmap();
});

final insightsAnalyticsProvider = FutureProvider<InsightsAnalyticsBundle>((ref) async {
  return ref.read(statsServiceProvider).getInsightsAnalytics();
});

final sessionHistoryProvider = FutureProvider<List<SessionRecord>>((ref) async {
  return ref.read(statsServiceProvider).getSessionHistory();
});

final dailyMinutesProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  return ref.read(statsServiceProvider).getDailyMinutes(days: 35);
});
