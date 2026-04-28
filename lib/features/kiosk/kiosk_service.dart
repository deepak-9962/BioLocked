import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

class KioskService {
  Future<void> enableKioskMode() async {
    if (kIsWeb) return;
    try {
      final mode = await getKioskMode();
      if (mode != KioskMode.enabled) {
        debugPrint('[KioskService] Starting Kiosk Mode (App Pinning / Screen Pinning)...');
        await startKioskMode();
      } else {
        debugPrint('[KioskService] Already in Kiosk Mode.');
      }
    } catch (e) {
      debugPrint('[KioskService] Error enabling Kiosk Mode: $e');
      // Kiosk mode might not be supported on this device/config — safe to ignore.
    }
  }

  Future<void> disableKioskMode() async {
    if (kIsWeb) return;
    try {
      final mode = await getKioskMode();
      if (mode != KioskMode.disabled) {
        debugPrint('[KioskService] Stopping Kiosk Mode...');
        await stopKioskMode();
      }
    } catch (e) {
      debugPrint('[KioskService] Error disabling Kiosk Mode: $e');
    }
  }

  Stream<KioskMode> get kioskModeStream {
    if (kIsWeb) return const Stream.empty();
    return watchKioskMode();
  }
}

final kioskServiceProvider = Provider<KioskService>((ref) {
  return KioskService();
});
