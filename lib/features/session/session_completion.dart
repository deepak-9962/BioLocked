import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../level/level_service.dart';
import '../stats/stats_service.dart';

class SessionCompletionData {
  final List<String> newAchievements;
  final List<String> announcements;
  final String completionMessage;
  final UserStats stats;
  final LevelUpResult? levelResult;

  const SessionCompletionData({
    required this.newAchievements,
    required this.announcements,
    required this.completionMessage,
    required this.stats,
    this.levelResult,
  });
}

class CompletedSessionFeedbackNotifier
    extends Notifier<AsyncValue<SessionCompletionData?>> {
  @override
  AsyncValue<SessionCompletionData?> build() {
    unawaited(_load());
    return const AsyncLoading();
  }

  Future<void> _load() async {
    try {
      final stats = await ref.read(statsServiceProvider).getStats();
      state = AsyncData(
        SessionCompletionData(
          newAchievements: const [],
          announcements: const [],
          completionMessage: 'Session completed. Keep the momentum going.',
          stats: stats,
          levelResult: null,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void setLoading() {
    state = const AsyncLoading();
  }

  void setReady(SessionCompletionData data) {
    state = AsyncData(data);
  }

  void setError(Object error, StackTrace stackTrace) {
    state = AsyncError(error, stackTrace);
  }

  void clear() {
    state = const AsyncData(null);
  }
}

final completedSessionFeedbackProvider = NotifierProvider<
    CompletedSessionFeedbackNotifier, AsyncValue<SessionCompletionData?>>(
  CompletedSessionFeedbackNotifier.new,
);
