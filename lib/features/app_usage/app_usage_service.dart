import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'app_usage_models.dart';

class AppUsageService {
  static const _channel = MethodChannel('com.biolocked.app_usage/methods');
  static const _storage = FlutterSecureStorage();
  static const _historyKey = 'app_usage_history_v1';
  static const _retentionDays = 60;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isUsageAccessGranted() async {
    if (!_isAndroid) return false;
    final result = await _channel.invokeMethod<bool>('isUsageAccessGranted');
    return result ?? false;
  }

  Future<bool> isSupportedAndGranted() async {
    if (!_isAndroid) return false;
    return isUsageAccessGranted();
  }

  Future<void> requestUsagePermissionFlow() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('openUsageAccessSettings');
  }

  Future<List<AppUsageEntry>> refreshUsageWindow({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_isAndroid) return [];
    final granted = await isUsageAccessGranted();
    if (!granted) {
      throw StateError('Usage Access permission not granted');
    }

    final raw = await _channel.invokeMethod<List<dynamic>>(
      'getUsageByHour',
      {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      },
    );

    final entries = (raw ?? const [])
        .whereType<Map>()
        .map((row) => _entryFromPlatformMap(row.cast<dynamic, dynamic>()))
        .toList();

    await _mergeIntoCache(entries);
    return entries;
  }

  Future<List<AppUsageEntry>> getCachedUsageWindow({int days = 7}) async {
    final all = await _getHistory();
    if (all.isEmpty) return [];
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return all.where((e) {
      final at = DateTime(
        e.day.year,
        e.day.month,
        e.day.day,
        e.hour,
      );
      return !at.isBefore(start) && at.isBefore(end);
    }).toList();
  }

  Future<List<TopAppUsage>> getTopApps({
    int days = 7,
    Map<String, String> categoryOverrides = const {},
    int limit = 5,
  }) async {
    final entries = await getCachedUsageWindow(days: days);
    final byPackage = <String, _TopAgg>{};
    for (final item in entries) {
      final current = byPackage[item.packageName] ??
          _TopAgg(packageName: item.packageName, appLabel: item.appLabel);
      byPackage[item.packageName] = current.copyWith(
        minutes: current.minutes + item.minutes,
        appLabel: item.appLabel.isNotEmpty ? item.appLabel : current.appLabel,
      );
    }

    final sorted = byPackage.values.toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    return sorted.take(limit).map((item) {
      final category = AppCategory.fromKey(categoryOverrides[item.packageName]);
      return TopAppUsage(
        packageName: item.packageName,
        appLabel: item.appLabel,
        minutes: item.minutes,
        category: category,
      );
    }).toList();
  }

  Future<void> clearUsageHistory() async {
    await _storage.delete(key: _historyKey);
  }

  Future<File> exportUsageCsvFile() async {
    final rows = await _getHistory();
    final buffer = StringBuffer()
      ..writeln('packageName,appLabel,minutes,hour,day');
    for (final r in rows) {
      buffer.writeln(
        '${_csvEscape(r.packageName)},${_csvEscape(r.appLabel)},${r.minutes},${r.hour},${r.day.toIso8601String()}',
      );
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}\\bio_locked_usage_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  AppUsageEntry _entryFromPlatformMap(Map<dynamic, dynamic> row) {
    final dayStartMs = (row['dayStartMs'] as num?)?.toInt() ?? 0;
    final hour = (row['hour'] as num?)?.toInt() ?? 0;
    final day = dayStartMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(dayStartMs)
        : DateTime.now();
    return AppUsageEntry(
      packageName: (row['packageName'] as String?) ?? '',
      appLabel: (row['appLabel'] as String?) ?? '',
      minutes: (row['minutes'] as num?)?.toInt() ?? 0,
      hour: hour,
      day: DateTime(day.year, day.month, day.day),
    );
  }

  Future<void> _mergeIntoCache(List<AppUsageEntry> entries) async {
    final existing = await _getHistory();
    final map = <String, AppUsageEntry>{};
    for (final item in [...existing, ...entries]) {
      final key =
          '${item.day.year}-${item.day.month}-${item.day.day}|${item.hour}|${item.packageName}';
      map[key] = item;
    }
    final now = DateTime.now();
    final floor = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: _retentionDays));
    final bounded = map.values.where((item) {
      final at = DateTime(item.day.year, item.day.month, item.day.day, item.hour);
      return !at.isBefore(floor);
    }).toList()
      ..sort((a, b) {
        final aDate = DateTime(a.day.year, a.day.month, a.day.day, a.hour);
        final bDate = DateTime(b.day.year, b.day.month, b.day.day, b.hour);
        return aDate.compareTo(bDate);
      });

    await _storage.write(
      key: _historyKey,
      value: jsonEncode(bounded.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<AppUsageEntry>> _getHistory() async {
    final raw = await _storage.read(key: _historyKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((item) => AppUsageEntry.fromJson(item.cast<String, dynamic>()))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class _TopAgg {
  final String packageName;
  final String appLabel;
  final int minutes;

  const _TopAgg({
    required this.packageName,
    required this.appLabel,
    this.minutes = 0,
  });

  _TopAgg copyWith({
    String? appLabel,
    int? minutes,
  }) {
    return _TopAgg(
      packageName: packageName,
      appLabel: appLabel ?? this.appLabel,
      minutes: minutes ?? this.minutes,
    );
  }
}

final appUsageServiceProvider = Provider<AppUsageService>((ref) {
  return AppUsageService();
});
