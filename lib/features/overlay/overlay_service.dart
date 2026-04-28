import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  Future<bool> checkPermission() async {
    if (kIsWeb) return false;
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      debugPrint('[OverlayService] Permission check error: $e');
      return false;
    }
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    try {
      await FlutterOverlayWindow.requestPermission();
    } catch (e) {
      debugPrint('[OverlayService] Permission request error: $e');
    }
  }

  Future<void> showOverlay() async {
    if (kIsWeb) return;
    try {
      final isGranted = await checkPermission();
      if (!isGranted) {
        await requestPermission();
        if (!await checkPermission()) return;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilitySecret,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );
      debugPrint('[OverlayService] Showing overlay lock');
    } catch (e) {
      debugPrint('[OverlayService] Failed to show overlay: $e');
    }
  }

  Future<void> hideOverlay() async {
    if (kIsWeb) return;
    try {
      await FlutterOverlayWindow.closeOverlay();
      debugPrint('[OverlayService] Hiding overlay lock');
    } catch (e) {
      debugPrint('[OverlayService] Failed to hide overlay: $e');
    }
  }
}

final overlayServiceProvider = Provider<OverlayService>((ref) {
  return OverlayService();
});
