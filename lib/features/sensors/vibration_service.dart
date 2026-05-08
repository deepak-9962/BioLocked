import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VibrationService {
  /// Single short vibration to confirm device placement
  Future<void> confirmationVibrate() async {
    await HapticFeedback.heavyImpact();
  }

  /// Strong vibration pattern for alarm
  Future<void> alarmVibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Bursts so users notice completion while the phone is face-down.
  Future<void> sessionCompleteCelebrate() async {
    for (var i = 0; i < 6; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 110));
    }
  }
}

final vibrationServiceProvider = Provider<VibrationService>((ref) => VibrationService());
