import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  final _isFaceDownController = StreamController<bool>.broadcast();
  final _motionController = StreamController<void>.broadcast();

  DateTime? _lastMotionEmit;

  Stream<bool> get isFaceDownStream => _isFaceDownController.stream;

  /// Bursts while the device is lifted, rotated, or jostled (debounced).
  Stream<void> get motionDuringSessionStream => _motionController.stream;

  void startListening() {
    _subscription = accelerometerEventStream().listen((event) {
      // Z-axis < -9.0 implies face down (assuming standard gravity ~9.8)
      // Also check X and Y to ensure it's relatively flat
      final isFaceDown = event.z < -8.0 && event.x.abs() < 2.0 && event.y.abs() < 2.0;
      _isFaceDownController.add(isFaceDown);
    });

    _userAccelSubscription = userAccelerometerEventStream().listen((event) {
      final mag = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _emitMotionIfNeeded(mag > 2.0);
    });

    _gyroSubscription = gyroscopeEventStream().listen((event) {
      final mag = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _emitMotionIfNeeded(mag > 0.45);
    });
  }

  void _emitMotionIfNeeded(bool significant) {
    if (!significant) return;
    final now = DateTime.now();
    if (_lastMotionEmit != null &&
        now.difference(_lastMotionEmit!) < const Duration(milliseconds: 600)) {
      return;
    }
    _lastMotionEmit = now;
    _motionController.add(null);
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _userAccelSubscription?.cancel();
    _userAccelSubscription = null;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }

  void dispose() {
    stopListening();
    _isFaceDownController.close();
    _motionController.close();
  }
}

final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorService();
  ref.onDispose(() => service.dispose());
  return service;
});
