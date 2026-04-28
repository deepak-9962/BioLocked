import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _isFaceDownController = StreamController<bool>.broadcast();

  Stream<bool> get isFaceDownStream => _isFaceDownController.stream;

  void startListening() {
    _subscription = accelerometerEventStream().listen((event) {
      // Z-axis < -9.0 implies face down (assuming standard gravity ~9.8)
      // Also check X and Y to ensure it's relatively flat
      final isFaceDown = event.z < -8.0 && event.x.abs() < 2.0 && event.y.abs() < 2.0;
      _isFaceDownController.add(isFaceDown);
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _isFaceDownController.close();
  }
}

final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorService();
  ref.onDispose(() => service.dispose());
  return service;
});
