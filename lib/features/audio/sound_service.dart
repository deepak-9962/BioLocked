import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SoundService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _isAlarmPlaying = false;

  SoundService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5); // Slower, more authoritative
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> startAlarm() async {
    if (_isAlarmPlaying) return;
    _isAlarmPlaying = true;
    _loopAlarmTts();
  }

  Future<void> _loopAlarmTts() async {
    while (_isAlarmPlaying) {
      await _tts.speak("Put your phone down, turn it over.");
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> stopAlarm() async {
    _isAlarmPlaying = false;
    await _tts.stop();
    await _player.stop();
  }

  Future<void> playPing() async {
    // Ideally play a short beep. For now, TTS "Ping".
    // await _tts.speak("Boss wants proof.");
  }
}

final soundServiceProvider = Provider<SoundService>((ref) => SoundService());
