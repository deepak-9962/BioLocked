import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionLogger {
  final SupabaseClient _supabase;

  SessionLogger(this._supabase);

  Future<void> logSessionStart({
    required String userId,
    required String taskName,
    required int durationMinutes,
    required int energyLevel,
  }) async {
    try {
      await _supabase.from('sessions').insert({
        'user_id': userId,
        'task_name': taskName,
        'planned_duration': durationMinutes,
        'energy_level': energyLevel,
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
  }) async {
    try {
      await _supabase.from('sessions').update({
        'ended_at': DateTime.now().toIso8601String(),
        'status': success ? 'completed' : 'failed',
        'failure_reason': reason,
      }).eq('id', sessionId);
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
