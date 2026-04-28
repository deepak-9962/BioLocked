import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Listens for SCREEN_ON events during an active session.
/// Each screen-on event while the device should be face-down is
/// logged as a "stealth distraction" — quieter than a full alarm,
/// but tracked and visible in the distraction heatmap.
class ScreenStateService {
  static const _channel = EventChannel('com.biolocked.screen_state/events');

  StreamSubscription<dynamic>? _subscription;
  final _screenOnController = StreamController<DateTime>.broadcast();

  Stream<DateTime> get screenOnEvents => _screenOnController.stream;
  int _screenOnCount = 0;
  int get screenOnCount => _screenOnCount;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Start listening for screen state events
  void startListening() {
    if (!_isSupported) return;

    _screenOnCount = 0;
    _subscription?.cancel();

    try {
      _subscription = _channel.receiveBroadcastStream().listen(
        (event) {
          if (event == 'SCREEN_ON') {
            _screenOnCount++;
            _screenOnController.add(DateTime.now());
            debugPrint('[ScreenState] Screen-on detected (#$_screenOnCount)');
          }
        },
        onError: (e) {
          debugPrint('[ScreenState] Stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('[ScreenState] startListening error: $e');
    }
  }

  /// Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('[ScreenState] Stopped — total screen-ons: $_screenOnCount');
  }

  void reset() {
    _screenOnCount = 0;
  }

  void dispose() {
    _subscription?.cancel();
    _screenOnController.close();
  }
}

final screenStateServiceProvider =
    Provider<ScreenStateService>((ref) {
  final service = ScreenStateService();
  ref.onDispose(service.dispose);
  return service;
});
