import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WakelockService {
  Future<void> enable() async {
    await WakelockPlus.enable();
  }

  Future<void> disable() async {
    await WakelockPlus.disable();
  }
}

final wakelockServiceProvider = Provider<WakelockService>((ref) => WakelockService());
