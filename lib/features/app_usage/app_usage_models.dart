enum AppCategory {
  study('study'),
  neutral('neutral'),
  distracting('distracting');

  final String key;
  const AppCategory(this.key);

  static AppCategory fromKey(String? key) {
    return AppCategory.values.firstWhere(
      (value) => value.key == key,
      orElse: () => AppCategory.neutral,
    );
  }
}

class AppUsageEntry {
  final String packageName;
  final String appLabel;
  final int minutes;
  final int hour;
  final DateTime day;

  const AppUsageEntry({
    required this.packageName,
    required this.appLabel,
    required this.minutes,
    required this.hour,
    required this.day,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appLabel': appLabel,
    'minutes': minutes,
    'hour': hour,
    'day': day.toIso8601String(),
  };

  factory AppUsageEntry.fromJson(Map<String, dynamic> json) => AppUsageEntry(
    packageName: (json['packageName'] as String?) ?? '',
    appLabel: (json['appLabel'] as String?) ?? '',
    minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    hour: (json['hour'] as num?)?.toInt() ?? 0,
    day: DateTime.tryParse((json['day'] as String?) ?? '') ?? DateTime.now(),
  );
}

class TopAppUsage {
  final String packageName;
  final String appLabel;
  final int minutes;
  final AppCategory category;

  const TopAppUsage({
    required this.packageName,
    required this.appLabel,
    required this.minutes,
    required this.category,
  });
}

class HourlyUsageBucket {
  final int hour;
  final int totalMinutes;
  final int distractingMinutes;
  final int studyTaggedMinutes;
  final int focusMinutes;

  const HourlyUsageBucket({
    required this.hour,
    required this.totalMinutes,
    required this.distractingMinutes,
    required this.studyTaggedMinutes,
    this.focusMinutes = 0,
  });
}
