import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sensors/sensor_service.dart';
import '../sensors/screen_state_service.dart';
import '../sensors/wakelock_service.dart';
import '../sensors/vibration_service.dart';
import '../audio/sound_service.dart';
import '../stats/stats_service.dart';
import '../dnd/dnd_service.dart';
import '../grayscale/grayscale_service.dart';
import '../coins/coins_service.dart';
import '../accountability/accountability_service.dart';
import '../kiosk/kiosk_service.dart';
import '../notifications/notification_service.dart';
import 'session_logger.dart';

enum SessionState {
  idle, setup, checkIn, tunnelSetup, waitingForFaceDown, inProgress, alarm, finished, recoveryMode, microWinsMode, history, accountSettings
}

enum SessionLockLevel {
  soft,
  standard,
  hard,
}

extension SessionLockLevelConfig on SessionLockLevel {
  String get label {
    switch (this) {
      case SessionLockLevel.soft:
        return 'Soft';
      case SessionLockLevel.standard:
        return 'Standard';
      case SessionLockLevel.hard:
        return 'Hard';
    }
  }

  String get keyName {
    switch (this) {
      case SessionLockLevel.soft:
        return 'soft';
      case SessionLockLevel.standard:
        return 'standard';
      case SessionLockLevel.hard:
        return 'hard';
    }
  }

  int get graceSeconds {
    switch (this) {
      case SessionLockLevel.soft:
        return 15;
      case SessionLockLevel.standard:
        return 10;
      case SessionLockLevel.hard:
        return 5;
    }
  }

  int get maxEmergencyBreaksPerDay {
    switch (this) {
      case SessionLockLevel.soft:
        return 2;
      case SessionLockLevel.standard:
        return 1;
      case SessionLockLevel.hard:
        return 0;
    }
  }

  Duration emergencyBreakCooldown(int customMinutes) {
    switch (this) {
      case SessionLockLevel.soft:
        return const Duration(minutes: 10);
      case SessionLockLevel.standard:
        return Duration(minutes: customMinutes);
      case SessionLockLevel.hard:
        return Duration.zero;
    }
  }
}

class EmergencyBreakResult {
  final bool allowed;
  final String message;
  final DateTime? cooldownUntil;

  const EmergencyBreakResult({
    required this.allowed,
    required this.message,
    this.cooldownUntil,
  });
}

// Provider to store previous verification image for progress comparison.
class PreviousVerificationImageNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void set(Uint8List? value) => state = value;
  void clear() => state = null;
}

final previousVerificationImageProvider =
    NotifierProvider<PreviousVerificationImageNotifier, Uint8List?>(
  PreviousVerificationImageNotifier.new,
);

class SessionStateMachine extends Notifier<SessionState> {
  StreamSubscription<bool>? _sensorSubscription;
  Timer? _gracePeriodTimer;
  Timer? _sessionTimer;
  String? _currentSessionId;
  final _uuid = const Uuid();
  DateTime? _sessionStartTime;

  @override
  SessionState build() {
    final sensorService = ref.watch(sensorServiceProvider);
    
    _sensorSubscription?.cancel();
    _sensorSubscription = sensorService.isFaceDownStream.listen(_handleSensorUpdate);
    
    ref.onDispose(() {
      _sensorSubscription?.cancel();
      _gracePeriodTimer?.cancel();
      _sessionTimer?.cancel();
    });
    
    return SessionState.idle;
  }

  void _handleSensorUpdate(bool isFaceDown) {
    if (state == SessionState.waitingForFaceDown && isFaceDown) {
      // Vibrate to confirm placement
      ref.read(soundServiceProvider).stopAlarm();
      ref.read(vibrationServiceProvider).confirmationVibrate();
      setInProgress();
    } else if (state == SessionState.inProgress && !isFaceDown) {
      // User picked up the phone - trigger alarm!
      _startGracePeriod();
    } else if (state == SessionState.alarm && isFaceDown) {
      // User put it back down - safe!
      _cancelGracePeriod();
      state = SessionState.inProgress;
      ref.read(soundServiceProvider).stopAlarm();
      ref.read(soundServiceProvider).speak("Safe.");
    }
  }

  void _startGracePeriod() {
    state = SessionState.alarm;
    ref.read(sessionInterruptionsProvider.notifier).increment();
    ref.read(soundServiceProvider).startAlarm();
    _gracePeriodTimer?.cancel();
    final graceSeconds = ref.read(lockLevelProvider).graceSeconds;
    _gracePeriodTimer = Timer(Duration(seconds: graceSeconds), () {
      // Time's up!
      _failSession('Lifted device for too long');
    });
  }

  void _cancelGracePeriod() {
    _gracePeriodTimer?.cancel();
  }

  void _failSession(String reason) {
    ref.read(soundServiceProvider).stopAlarm();
    ref.read(soundServiceProvider).speak("Session Failed.");

    unawaited(_recordFailedSession(reason));
    
    final destructionMode = ref.read(destructionModeProvider);
    final lockLevel = ref.read(lockLevelProvider);

    if (lockLevel == SessionLockLevel.hard) {
      _logSessionEnd('$reason (Hard lock)', false);
      reset();
      return;
    }
    
    if (destructionMode) {
      _logSessionEnd(reason, false);
      reset();
    } else {
      final currentHealth = ref.read(healthProvider);
      if (currentHealth <= 1) {
        ref.read(healthProvider.notifier).decrement();
        _logSessionEnd('$reason (Health depleted)', false);
        reset();
      } else {
        ref.read(healthProvider.notifier).decrement();
        state = SessionState.inProgress;
      }
    }
  }

  void _logSessionEnd(String reason, bool success) {
    if (_currentSessionId != null) {
      final elapsedMinutes = _sessionStartTime == null
          ? 0
          : DateTime.now().difference(_sessionStartTime!).inMinutes;
      ref.read(sessionLoggerProvider).logSessionEnd(
        sessionId: _currentSessionId!,
        success: success,
        reason: reason,
        durationMinutes: elapsedMinutes,
        interruptions: ref.read(sessionInterruptionsProvider),
        emergencyBreaks: ref.read(sessionEmergencyBreaksProvider),
      );
    }
  }

  void setSetup() => state = SessionState.setup;
  void setCheckIn() => state = SessionState.checkIn;
  void setTunnelSetup() => state = SessionState.tunnelSetup;
  void setAccountSettings() => state = SessionState.accountSettings;
  
  void setWaitingForFaceDown() {
    final cooldownUntil = ref.read(emergencyBreakCooldownUntilProvider);
    final now = DateTime.now();
    if (cooldownUntil != null && cooldownUntil.isAfter(now)) {
      final remainingMinutes = cooldownUntil.difference(now).inMinutes + 1;
      ref
          .read(soundServiceProvider)
          .speak('Emergency break cooldown. Wait $remainingMinutes minutes.');
      return;
    }

    state = SessionState.waitingForFaceDown;
    ref.read(sensorServiceProvider).startListening();
    ref.read(soundServiceProvider).startAlarm();
  }

  void setInProgress() {
    state = SessionState.inProgress;
    ref.read(wakelockServiceProvider).enable();
    ref.read(soundServiceProvider).speak("Deep Work Started.");
    
    // Reset Health
    ref.read(healthProvider.notifier).reset();
    ref.read(sessionInterruptionsProvider.notifier).reset();
    ref.read(sessionEmergencyBreaksProvider.notifier).reset();

    // 🔕 Enable DND — only calls allowed
    unawaited(ref.read(dndServiceProvider).enableFocusDnd());

    // 🌑 Enable Grayscale Mode
    ref.read(grayscaleModeProvider.notifier).enable();
    
    // 🔒 Enable Kiosk Mode for Hard/Standard Lock
    final lockLevel = ref.read(lockLevelProvider);
    if (lockLevel == SessionLockLevel.hard || lockLevel == SessionLockLevel.standard) {
      unawaited(ref.read(kioskServiceProvider).enableKioskMode());
    }

    // 👁️ Start Screen-On detection
    ref.read(screenStateServiceProvider).startListening();

    // Start Session Logging
    _currentSessionId = _uuid.v4();
    final taskName = ref.read(taskNameProvider);
    final duration = ref.read(taskDurationProvider);
    final energy = ref.read(energyLevelProvider);
    
    // Start the session timer
    _sessionStartTime = DateTime.now();
    ref.read(remainingSecondsProvider.notifier).set(duration * 60);
    _startSessionTimer();
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _failSession('No signed-in user');
      return;
    }

    ref.read(sessionLoggerProvider).logSessionStart(
      sessionId: _currentSessionId!,
      userId: userId,
      taskName: taskName,
      durationMinutes: duration,
      energyLevel: energy,
      interruptions: 0,
      emergencyBreaks: 0,
      lockLevel: ref.read(lockLevelProvider).keyName,
    );
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == SessionState.inProgress || state == SessionState.alarm) {
        final remaining = ref.read(remainingSecondsProvider);
        if (remaining <= 0) {
          timer.cancel();
          setFinished();
        } else {
          ref.read(remainingSecondsProvider.notifier).set(remaining - 1);
        }
      }
    });
  }

  void setFinished() {
    _logSessionEnd('Completed', true);
    ref.read(soundServiceProvider).speak("Session Completed. Good job.");
    state = SessionState.finished;

    final elapsed = _sessionStartTime == null
        ? ref.read(taskDurationProvider)
        : DateTime.now().difference(_sessionStartTime!).inMinutes;
    final interruptions = ref.read(sessionInterruptionsProvider);
    final emergencyBreaks = ref.read(sessionEmergencyBreaksProvider);

    // 🏆 Record session and award Focus Coins
    unawaited(() async {
      // 1. Record in stats service (which updates streaks)
      await ref.read(statsServiceProvider).recordSessionComplete(
        durationMinutes: elapsed,
        hadFailures: false,
        taskName: ref.read(taskNameProvider),
        energyLevel: ref.read(energyLevelProvider),
        interruptions: interruptions,
        emergencyBreaks: emergencyBreaks,
        lockLevel: ref.read(lockLevelProvider).keyName,
      );

      // 2. Get fresh stats to see the new streak
      final stats = await ref.read(statsServiceProvider).getStats();

      // 3. Award coins with real streak awareness
      await ref.read(coinsServiceProvider).awardCoins(
        durationMinutes: elapsed,
        interruptions: interruptions,
        streakDays: stats.currentStreak,
      );
    }());

    // 👥 Notify accountability partner on success (if configured)
    unawaited(_notifyPartnerSuccess());

    _cleanup();
  }

  Future<void> _notifyPartnerSuccess() async {
    final partner = await ref.read(accountabilityServiceProvider).getPartner();
    if (partner == null || !partner.notifyOnSuccess) return;
    final elapsed = _sessionStartTime == null
        ? ref.read(taskDurationProvider)
        : DateTime.now().difference(_sessionStartTime!).inMinutes;
    await ref.read(accountabilityServiceProvider).notifyPartnerOfSuccess(
      taskName: ref.read(taskNameProvider),
      durationMinutes: elapsed,
      partnerName: partner.name,
    );
  }

  void setRecoveryMode() => state = SessionState.recoveryMode;

  void setMicroWinsMode() => state = SessionState.microWinsMode;

  void setHistory() => state = SessionState.history;

  Future<EmergencyBreakResult> requestEmergencyBreak() async {
    if (state != SessionState.inProgress && state != SessionState.alarm) {
      return const EmergencyBreakResult(
        allowed: false,
        message: 'Emergency break is only available during a session.',
      );
    }

    final lockLevel = ref.read(lockLevelProvider);
    if (lockLevel == SessionLockLevel.hard) {
      return const EmergencyBreakResult(
        allowed: false,
        message: 'Hard lock mode disables emergency breaks.',
      );
    }

    final now = DateTime.now();
    final cooldownUntil = ref.read(emergencyBreakCooldownUntilProvider);
    if (cooldownUntil != null && cooldownUntil.isAfter(now)) {
      final remaining = cooldownUntil.difference(now).inMinutes + 1;
      return EmergencyBreakResult(
        allowed: false,
        message: 'Emergency break cooling down. Try again in $remaining minutes.',
        cooldownUntil: cooldownUntil,
      );
    }

    _resetEmergencyBreaksIfNewDay(now);
    final usedToday = ref.read(emergencyBreaksUsedTodayProvider);
    final maxBreaks = lockLevel.maxEmergencyBreaksPerDay;
    if (usedToday >= maxBreaks) {
      return EmergencyBreakResult(
        allowed: false,
        message: 'Daily emergency break limit reached ($maxBreaks).',
      );
    }

    final settings = await NotificationService.getSettings();
    final nextCooldown = now.add(lockLevel.emergencyBreakCooldown(settings.cooldownMinutes));
    ref.read(emergencyBreaksUsedTodayProvider.notifier).set(usedToday + 1);
    ref.read(emergencyBreakDayProvider.notifier).set(
          DateTime(now.year, now.month, now.day),
        );
    ref.read(emergencyBreakCooldownUntilProvider.notifier).set(nextCooldown);
    ref.read(sessionEmergencyBreaksProvider.notifier).increment();

    unawaited(_recordFailedSession('Emergency break used'));
    _logSessionEnd('Emergency break used', false);
    ref.read(soundServiceProvider).speak('Emergency break used. Cooldown started.');
    reset();

    return EmergencyBreakResult(
      allowed: true,
      message: 'Emergency break activated. Session ended with penalty.',
      cooldownUntil: nextCooldown,
    );
  }

  void giveUpSession() {
    if (state != SessionState.inProgress && state != SessionState.alarm) {
      reset();
      return;
    }

    unawaited(_recordFailedSession('Session abandoned'));
    _logSessionEnd('Session abandoned', false);
    ref.read(soundServiceProvider).speak('Session ended.');

    // 👥 Notify accountability partner on failure
    unawaited(_notifyPartnerFailure('Session abandoned'));

    reset();
  }

  Future<void> _notifyPartnerFailure(String reason) async {
    final partner = await ref.read(accountabilityServiceProvider).getPartner();
    if (partner == null || !partner.notifyOnFailure) return;
    final elapsed = _sessionStartTime == null
        ? 0
        : DateTime.now().difference(_sessionStartTime!).inMinutes;
    await ref.read(accountabilityServiceProvider).notifyPartnerOfFailure(
      taskName: ref.read(taskNameProvider),
      elapsedMinutes: elapsed,
      reason: reason,
      partnerName: partner.name,
    );
  }
  
  void reset() {
    state = SessionState.idle;
    _cleanup();
    // Go back to check-in instead of idle
    Future.microtask(() => state = SessionState.checkIn);
  }

  void _resetEmergencyBreaksIfNewDay(DateTime now) {
    final lastDay = ref.read(emergencyBreakDayProvider);
    final today = DateTime(now.year, now.month, now.day);
    if (lastDay == null ||
        lastDay.year != today.year ||
        lastDay.month != today.month ||
        lastDay.day != today.day) {
      ref.read(emergencyBreaksUsedTodayProvider.notifier).set(0);
      ref.read(emergencyBreakDayProvider.notifier).set(today);
    }
  }

  Future<void> _recordFailedSession(String reason) async {
    final elapsedMinutes = _sessionStartTime == null
        ? 0
        : DateTime.now().difference(_sessionStartTime!).inMinutes;

    await ref.read(statsServiceProvider).recordSessionFailed(
          reason,
          durationMinutes: elapsedMinutes,
          taskName: ref.read(taskNameProvider),
          energyLevel: ref.read(energyLevelProvider),
          interruptions: ref.read(sessionInterruptionsProvider),
          emergencyBreaks: ref.read(sessionEmergencyBreaksProvider),
          lockLevel: ref.read(lockLevelProvider).keyName,
        );
  }

  void _cleanup() {
    _gracePeriodTimer?.cancel();
    _sessionTimer?.cancel();
    ref.read(sensorServiceProvider).stopListening();
    ref.read(wakelockServiceProvider).disable();
    ref.read(soundServiceProvider).stopAlarm();

    // 🔕 Restore DND
    unawaited(ref.read(dndServiceProvider).disableFocusDnd());
    
    // 🔓 Disable Kiosk Mode
    unawaited(ref.read(kioskServiceProvider).disableKioskMode());

    // 🌑 Disable Grayscale
    ref.read(grayscaleModeProvider.notifier).disable();

    // 👁️ Stop Screen-On detection
    ref.read(screenStateServiceProvider).stopListening();

    _currentSessionId = null;
    _sessionStartTime = null;
  }
}

final sessionStateProvider = NotifierProvider<SessionStateMachine, SessionState>(SessionStateMachine.new);

class HealthNotifier extends Notifier<int> {
  @override
  int build() => 3;
  void decrement() => state = state > 0 ? state - 1 : 0;
  void reset() => state = 3;
}
final healthProvider = NotifierProvider<HealthNotifier, int>(HealthNotifier.new);

class EnergyLevelNotifier extends Notifier<int> {
  @override
  int build() => 50;
  void set(int value) => state = value;
}
final energyLevelProvider = NotifierProvider<EnergyLevelNotifier, int>(EnergyLevelNotifier.new);

class TaskNameNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}
final taskNameProvider = NotifierProvider<TaskNameNotifier, String>(TaskNameNotifier.new);

class TaskDurationNotifier extends Notifier<int> {
  @override
  int build() => 45;
  void set(int value) => state = value;
}
final taskDurationProvider = NotifierProvider<TaskDurationNotifier, int>(TaskDurationNotifier.new);

class DestructionModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void set(bool value) => state = value;
}
final destructionModeProvider = NotifierProvider<DestructionModeNotifier, bool>(DestructionModeNotifier.new);

class LockLevelNotifier extends Notifier<SessionLockLevel> {
  @override
  SessionLockLevel build() => SessionLockLevel.standard;
  void set(SessionLockLevel value) => state = value;
}
final lockLevelProvider = NotifierProvider<LockLevelNotifier, SessionLockLevel>(
  LockLevelNotifier.new,
);

class SessionInterruptionsNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state = state + 1;
  void reset() => state = 0;
}
final sessionInterruptionsProvider =
    NotifierProvider<SessionInterruptionsNotifier, int>(
  SessionInterruptionsNotifier.new,
);

class SessionEmergencyBreaksNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state = state + 1;
  void reset() => state = 0;
}
final sessionEmergencyBreaksProvider =
    NotifierProvider<SessionEmergencyBreaksNotifier, int>(
  SessionEmergencyBreaksNotifier.new,
);

class EmergencyBreaksUsedTodayNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int value) => state = value;
}
final emergencyBreaksUsedTodayProvider =
    NotifierProvider<EmergencyBreaksUsedTodayNotifier, int>(
  EmergencyBreaksUsedTodayNotifier.new,
);

class EmergencyBreakDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void set(DateTime? value) => state = value;
}
final emergencyBreakDayProvider =
    NotifierProvider<EmergencyBreakDayNotifier, DateTime?>(
  EmergencyBreakDayNotifier.new,
);

class EmergencyBreakCooldownNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void set(DateTime? value) => state = value;
}
final emergencyBreakCooldownUntilProvider =
    NotifierProvider<EmergencyBreakCooldownNotifier, DateTime?>(
  EmergencyBreakCooldownNotifier.new,
);

class RemainingSecondsNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int value) => state = value;
}
final remainingSecondsProvider = NotifierProvider<RemainingSecondsNotifier, int>(RemainingSecondsNotifier.new);

// Demo Mode - allows users to try the app without AI verification
class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void enable() => state = true;
  void disable() => state = false;
}
final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(DemoModeNotifier.new);
