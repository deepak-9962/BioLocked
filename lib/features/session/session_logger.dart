import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionLogger {
  final SupabaseClient _supabase;

  SessionLogger(this._supabase);

  Future<void> logSessionStart({
    required String sessionId,
    required String userId,
    required String taskName,
    required int durationMinutes,
    required int energyLevel,
    required int interruptions,
    required int emergencyBreaks,
    required String lockLevel,
  }) async {
    try {
      await _supabase.from('sessions').insert({
        'id': sessionId,
        'user_id': userId,
        'task_name': taskName,
        'planned_duration': durationMinutes,
        'duration_minutes': 0,
        'energy_level': energyLevel,
        'interruptions': interruptions,
        'emergency_breaks': emergencyBreaks,
        'lock_level': lockLevel,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'in_progress',
      });
    } catch (e) {
      // Fail silently or log to local storage for retry
      debugPrint('Error logging session start: $e');
    }
  }

  Future<void> logSessionEnd({
    required String sessionId,
    required bool success,
    required String reason,
    int? durationMinutes,
    int? interruptions,
    int? emergencyBreaks,
  }) async {
    try {
      final endedAt = DateTime.now().toIso8601String();
      final payload = <String, dynamic>{
        'ended_at': DateTime.now().toIso8601String(),
        'status': success ? 'completed' : 'failed',
        'failure_reason': reason,
      };

      if (success) {
        payload['completed_at'] = endedAt;
      }
      if (durationMinutes != null) {
        payload['duration_minutes'] = durationMinutes;
      }
      if (interruptions != null) {
        payload['interruptions'] = interruptions;
      }
      if (emergencyBreaks != null) {
        payload['emergency_breaks'] = emergencyBreaks;
      }

      await _supabase.from('sessions').update(payload).eq('id', sessionId);
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
