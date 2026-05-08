import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../stats/stats_service.dart';
import '../level/level_service.dart';

/// Shown on [FinishedScreen] after stats / XP have been persisted.
class SessionCompletionData {
  final List<String> newAchievements;
  final List<String> announcements;
  final String completionMessage;
  final UserStats stats;
  final LevelUpResult? levelResult;

  SessionCompletionData({
    required this.newAchievements,
    required this.announcements,
    required this.completionMessage,
    required this.stats,
    this.levelResult,
  });
}

String getAchievementAnnouncement(String achievement) {
  switch (achievement) {
    case 'first_session':
      return 'THE JOURNEY BEGINS! You\'ve completed your first deep work session!';
    case 'streak_7':
      return 'LEGENDARY! 7 days of unwavering focus!';
    case 'streak_30':
      return 'MYTHICAL STATUS! 30 consecutive days of deep work!';
    case 'hours_10':
      return '10 HOURS DEEP WORK logged — foundation forged!';
    case 'hours_100':
      return '100 HOURS! Elite-tier sustained concentration!';
    case 'no_failures_10':
      return 'PERFECT FOCUS! 10 sessions without a single phone pickup!';
    default:
      return 'Achievement unlocked!';
  }
}

String buildCompletionMessage({
  required String taskName,
  required int durationMinutes,
  required int sessionsCompleted,
  required int currentStreak,
  required bool hadFailures,
}) {
  final task = taskName.trim().isEmpty ? 'your task' : taskName.trim();

  if (hadFailures) {
    return 'Session complete. You still finished $durationMinutes minutes on $task. Consistency beats perfection.';
  }

  if (currentStreak >= 14) {
    return 'Strong finish: $durationMinutes focused minutes on $task. Your $currentStreak-day streak is elite.';
  }

  if (sessionsCompleted <= 3) {
    return 'Great start. You completed $durationMinutes minutes on $task and are building real momentum.';
  }

  return 'You stayed focused for $durationMinutes minutes on $task. Keep this rhythm going.';
}

/// Populated when a timer completes; consumed by [FinishedScreen].
class CompletedSessionFeedbackNotifier extends Notifier<AsyncValue<SessionCompletionData?>> {
  @override
  AsyncValue<SessionCompletionData?> build() => const AsyncValue.data(null);

  void clear() => state = const AsyncValue.data(null);

  void setLoading() => state = const AsyncValue.loading();

  void setReady(SessionCompletionData data) => state = AsyncValue.data(data);
}

final completedSessionFeedbackProvider =
    NotifierProvider<CompletedSessionFeedbackNotifier, AsyncValue<SessionCompletionData?>>(
  CompletedSessionFeedbackNotifier.new,
);
