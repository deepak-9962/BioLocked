import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionLogger {
  final SupabaseClient _supabase;

  SessionLogger(this._supabase);

  /// [sessionId] must match the row primary key (same UUID as local session).
  Future<void> logSessionStart({
    required String sessionId,
    required String userId,
    required String taskName,
    required int durationMinutes,
    required int energyLevel,
  }) async {
    try {
      await _supabase.from('sessions').insert({
        'id': sessionId,
        'user_id': userId,
        'task_name': taskName,
        'planned_duration': durationMinutes,
        'energy_level': energyLevel,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'in_progress',
      });
    } catch (e) {
      debugPrint('Error logging session start: $e');
    }
  }

  Future<void> logSessionEnd({
    required String sessionId,
    required bool success,
    required String reason,
    int? elapsedMinutes,
    int? plannedMinutes,
    int? interruptions,
    int? emergencyBreaks,
    String? lockLevel,
    int? energyLevel,
    String? taskName,
  }) async {
    try {
      final patch = <String, dynamic>{
        'ended_at': DateTime.now().toIso8601String(),
        'status': success ? 'completed' : 'failed',
        'failure_reason': reason,
      };
      if (elapsedMinutes != null) patch['elapsed_minutes'] = elapsedMinutes;
      if (plannedMinutes != null) patch['planned_duration_snapshot'] = plannedMinutes;
      if (interruptions != null) patch['interruptions'] = interruptions;
      if (emergencyBreaks != null) patch['emergency_breaks'] = emergencyBreaks;
      if (lockLevel != null) patch['lock_level'] = lockLevel;
      if (energyLevel != null) patch['energy_level_end'] = energyLevel;
      if (taskName != null) patch['task_name_final'] = taskName;

      await _supabase.from('sessions').update(patch).eq('id', sessionId);
    } catch (e) {
      debugPrint('Error logging session end: $e');
    }
  }

  Future<void> logVerification({
    required String sessionId,
    required String imageUrl,
    required bool isProductive,
  }) async {
    try {
      await _supabase.from('verifications').insert({
        'session_id': sessionId,
        'image_url': imageUrl,
        'is_productive': isProductive,
        'verified_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging verification: $e');
    }
  }
}

final sessionLoggerProvider = Provider<SessionLogger>((ref) {
  return SessionLogger(Supabase.instance.client);
});
