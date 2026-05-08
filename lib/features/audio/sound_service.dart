import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class SoundService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _isAlarmPlaying = false;
  DateTime? _lastPutPhoneDownSpeech;

  static const putPhoneDownPhrase = 'Put your phone down, turn it over.';

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
      await _tts.speak(putPhoneDownPhrase);
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Immediate reminder when motion is detected (throttled so sensors don’t spam TTS).
  Future<void> speakPutPhoneDownReminder({
    Duration minInterval = const Duration(seconds: 2),
  }) async {
    final now = DateTime.now();
    if (_lastPutPhoneDownSpeech != null &&
        now.difference(_lastPutPhoneDownSpeech!) < minInterval) {
      return;
    }
    _lastPutPhoneDownSpeech = now;
    await _tts.stop();
    await _tts.speak(putPhoneDownPhrase);
  }

  Future<void> stopAlarm() async {
    _isAlarmPlaying = false;
    _lastPutPhoneDownSpeech = null;
    await _tts.stop();
    await _player.stop();
  }

  Future<void> playPing() async {
    // Ideally play a short beep. For now, TTS "Ping".
    // await _tts.speak("Boss wants proof.");
  }

  /// Short celebratory chime (works face-down; uses media volume).
  Future<void> playSessionCompleteFanfare() async {
    await _player.stop();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/session_complete_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(_buildSessionCompleteWav());
    try {
      await _player.play(DeviceFileSource(file.path), volume: 1);
      await _player.onPlayerComplete.first.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      await _player.stop();
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}

Uint8List _buildSessionCompleteWav() {
  const sampleRate = 24000;
  final pcm = BytesBuilder();

  void appendTone(double hz, double seconds, double amplitude) {
    final n = (sampleRate * seconds).round();
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final sample =
          (amplitude * 32767 * math.sin(2 * math.pi * hz * t)).round().clamp(
                -32767,
                32767,
              );
      pcm.addByte(sample & 0xff);
      pcm.addByte((sample >> 8) & 0xff);
    }
  }

  void appendSilence(double seconds) {
    final bytes = (sampleRate * seconds).round() * 2;
    pcm.add(List.filled(bytes, 0));
  }

  appendTone(523.25, 0.14, 0.35);
  appendSilence(0.04);
  appendTone(659.25, 0.14, 0.35);
  appendSilence(0.04);
  appendTone(783.99, 0.18, 0.40);
  appendSilence(0.06);
  appendTone(1046.5, 0.34, 0.38);

  final pcmBytes = pcm.toBytes();
  final dataSize = pcmBytes.length;
  final riffChunkSize = 36 + dataSize;

  final header = BytesBuilder();
  header.add('RIFF'.codeUnits);
  _appendLe32(header, riffChunkSize);
  header.add('WAVE'.codeUnits);
  header.add('fmt '.codeUnits);
  _appendLe32(header, 16);
  _appendLe16(header, 1);
  _appendLe16(header, 1);
  _appendLe32(header, sampleRate);
  _appendLe32(header, sampleRate * 2);
  _appendLe16(header, 2);
  _appendLe16(header, 16);
  header.add('data'.codeUnits);
  _appendLe32(header, dataSize);
  header.add(pcmBytes);
  return Uint8List.fromList(header.toBytes());
}

void _appendLe32(BytesBuilder b, int v) {
  b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
}

void _appendLe16(BytesBuilder b, int v) {
  b.add([v & 0xff, (v >> 8) & 0xff]);
}

final soundServiceProvider = Provider<SoundService>((ref) => SoundService());
