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
}

final vibrationServiceProvider = Provider<VibrationService>((ref) => VibrationService());
