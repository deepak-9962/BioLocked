import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

/// Do Not Disturb service — enables Priority-Only DND during sessions.
/// Only calls are allowed through; all other notifications are silenced.
/// Gracefully no-ops on iOS and web.
class DndService {
  bool _wasInDndBeforeSession = false;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  final DoNotDisturbPlugin _dndPlugin = DoNotDisturbPlugin();

  /// Check if DND permission is granted
  Future<bool> isPermissionGranted() async {
    if (!_isSupported) return false;
    try {
      return await _dndPlugin.isNotificationPolicyAccessGranted();
    } catch (e) {
      debugPrint('[DndService] isPermissionGranted: $e');
      return false;
    }
  }

  /// Open DND permission settings page
  Future<void> requestPermission() async {
    if (!_isSupported) return;
    try {
      await _dndPlugin.openNotificationPolicyAccessSettings();
    } catch (e) {
      debugPrint('[DndService] requestPermission: $e');
    }
  }

  /// Enable Priority-Only DND (calls allowed, everything else silenced)
  Future<bool> enableFocusDnd() async {
    if (!_isSupported) return false;

    try {
      final hasPermission = await isPermissionGranted();
      if (!hasPermission) return false;

      // Save whether DND was already active before session
      final currentFilter = await _dndPlugin.getDNDStatus();
      _wasInDndBeforeSession =
          currentFilter != InterruptionFilter.all &&
          currentFilter != InterruptionFilter.unknown;

      // Set Priority-Only interruption filter
      await _dndPlugin.setInterruptionFilter(InterruptionFilter.priority);

      debugPrint('[DndService] ✅ Priority DND enabled — calls only');
      return true;
    } catch (e) {
      debugPrint('[DndService] enableFocusDnd error: $e');
      return false;
    }
  }

  /// Restore to All notifications (unless DND was already active)
  Future<void> disableFocusDnd() async {
    if (!_isSupported) return;

    try {
      final hasPermission = await isPermissionGranted();
      if (!hasPermission) return;

      if (!_wasInDndBeforeSession) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      }

      debugPrint('[DndService] ✅ DND restored to normal');
    } catch (e) {
      debugPrint('[DndService] disableFocusDnd error: $e');
    }
  }
}

final dndServiceProvider = Provider<DndService>((ref) => DndService());
