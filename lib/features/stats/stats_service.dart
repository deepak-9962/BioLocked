import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A single session record for history
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

/// Local stats for tracking achievements and streaks
class UserStats {
  int totalSessions;
  int totalMinutes;
  int currentStreak;
  int longestStreak;
  int perfectSessions; // Sessions with no phone pickups
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
  static const _progressTable = 'user_progress';

  Future<UserStats> getStats() async {
    final data = await _storage.read(key: _statsKey);
    if (data != null) {
      try {
        return UserStats.fromJson(jsonDecode(data));
      } catch (e) {
        debugPrint('[StatsService] Failed to decode local stats: $e');
      }
    }
    final remoteStats = await _loadRemoteStats();
    if (remoteStats != null) {
      await _storage.write(key: _statsKey, value: jsonEncode(remoteStats.toJson()));
      return remoteStats;
    }
    return UserStats();
  }

  Future<void> saveStats(UserStats stats) async {
    await _storage.write(key: _statsKey, value: jsonEncode(stats.toJson()));
    await _syncStatsToRemote(stats);
  }

  /// One-time helper to push existing local progress into Supabase.
  Future<void> backfillLocalToRemote() async {
    final userId = _currentUserId();
    if (userId == null) return;

    final localStatsRaw = await _storage.read(key: _statsKey);
    final localHistoryRaw = await _storage.read(key: _historyKey);
    if (localStatsRaw == null && localHistoryRaw == null) return;

    final payload = <String, dynamic>{
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (localStatsRaw != null) {
      try {
        final decoded = jsonDecode(localStatsRaw);
        if (decoded is Map) {
          payload['stats_json'] = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('[StatsService] Failed to decode local stats for backfill: $e');
      }
    }

    if (localHistoryRaw != null) {
      try {
        final decoded = jsonDecode(localHistoryRaw);
        if (decoded is List) {
          payload['history_json'] = decoded
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
        }
      } catch (e) {
        debugPrint('[StatsService] Failed to decode local history for backfill: $e');
      }
    }

    if (!payload.containsKey('stats_json') && !payload.containsKey('history_json')) {
      return;
    }

    try {
      await Supabase.instance.client.from(_progressTable).upsert(
        payload,
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('[StatsService] Local backfill failed: $e');
    }
  }

  /// Get session history
  Future<List<SessionRecord>> getSessionHistory() async {
    final data = await _storage.read(key: _historyKey);
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        return jsonList.map((j) => SessionRecord.fromJson(j)).toList();
      } catch (e) {
        debugPrint('[StatsService] Failed to decode local session history: $e');
      }
    }
    final remoteHistory = await _loadRemoteHistory();
    if (remoteHistory != null) {
      await _storage.write(
        key: _historyKey,
        value: jsonEncode(remoteHistory.map((s) => s.toJson()).toList()),
      );
      return remoteHistory;
    }
    return [];
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
    await _syncHistoryToRemote(history);
  }

  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (e) {
      debugPrint('[StatsService] Supabase not available: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchRemoteProgressRow() async {
    final userId = _currentUserId();
    if (userId == null) return null;
    try {
      final rows = await Supabase.instance.client
          .from(_progressTable)
          .select('stats_json,history_json')
          .eq('user_id', userId)
          .limit(1);
      if (rows.isEmpty) return null;
      return Map<String, dynamic>.from(rows.first as Map);
    } catch (e) {
      debugPrint('[StatsService] Remote progress fetch failed: $e');
    }
    return null;
  }

  Future<UserStats?> _loadRemoteStats() async {
    final row = await _fetchRemoteProgressRow();
    if (row == null) return null;
    final rawStats = row['stats_json'];
    if (rawStats is! Map) return null;
    try {
      return UserStats.fromJson(Map<String, dynamic>.from(rawStats));
    } catch (e) {
      debugPrint('[StatsService] Failed to decode remote stats: $e');
      return null;
    }
  }

  Future<List<SessionRecord>?> _loadRemoteHistory() async {
    final row = await _fetchRemoteProgressRow();
    if (row == null) return null;
    final rawHistory = row['history_json'];
    if (rawHistory is! List) return null;
    try {
      return rawHistory
          .map((entry) => SessionRecord.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList();
    } catch (e) {
      debugPrint('[StatsService] Failed to decode remote history: $e');
      return null;
    }
  }

  Future<void> _syncStatsToRemote(UserStats stats) async {
    final userId = _currentUserId();
    if (userId == null) return;
    try {
      await Supabase.instance.client.from(_progressTable).upsert(
        {
          'user_id': userId,
          'stats_json': stats.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('[StatsService] Remote stats sync failed: $e');
    }
  }

  Future<void> _syncHistoryToRemote(List<SessionRecord> history) async {
    final userId = _currentUserId();
    if (userId == null) return;
    try {
      await Supabase.instance.client.from(_progressTable).upsert(
        {
          'user_id': userId,
          'history_json': history.map((s) => s.toJson()).toList(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('[StatsService] Remote history sync failed: $e');
    }
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
    ));
    
    // Update totals
    stats.totalSessions++;
    stats.totalMinutes += durationMinutes;
    
    if (!hadFailures) {
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
    
    // Perfect sessions
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

    final minutesByHour = <int, int>{};
    for (final session in successful) {
      final hour = session.completedAt.hour;
      minutesByHour[hour] = (minutesByHour[hour] ?? 0) + session.durationMinutes;
    }

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
