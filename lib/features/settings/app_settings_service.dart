import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ────────────────────────────────────────────────────────────────────────────
/// App Settings Model — all user-customisable preferences in one place.
/// Persisted to SharedPreferences so they survive restarts.
/// ────────────────────────────────────────────────────────────────────────────
class AppSettings {
  // ── Session Defaults ──────────────────────────────────────────────────────
  final int defaultDurationMinutes;
  final String defaultLockLevel; // 'soft' | 'standard' | 'hard'
  final bool defaultDestructionMode;
  final List<int> quickDurations; // the [15,25,45,60,90] chips


  // ── Lock Behaviour ────────────────────────────────────────────────────────
  final int softGraceSeconds;
  final int standardGraceSeconds;
  final int hardGraceSeconds;
  final int softMaxEmergencyBreaks;
  final int standardMaxEmergencyBreaks;

  // ── Grayscale ─────────────────────────────────────────────────────────────
  final bool grayscaleOnSession; // enable grayscale when session starts

  // ── DND ───────────────────────────────────────────────────────────────────
  final bool dndOnSession;

  // ── Coins / Rewards ───────────────────────────────────────────────────────
  final int coinsPerMinute;
  final int perfectSessionBonus;
  final int streakWeeklyBonus;

  // ── Focus Coins Economy ───────────────────────────────────────────────────
  final bool coinsEnabled;

  // ── Accountability ────────────────────────────────────────────────────────
  final bool notifyPartnerOnSuccess;
  final bool notifyPartnerOnFailure;

  // ── App Persona ───────────────────────────────────────────────────────────
  final String appName; // e.g. "BIO-LOCKED" or your name
  final bool soundEnabled;
  final bool hapticEnabled;

  // ── Spot Check Timing ─────────────────────────────────────────────────────
  final int shortSessionThresholdMinutes; // below = "short"
  final int mediumSessionThresholdMinutes; // below = "medium"
  final int longSessionSpotCheckMinutes; // when long, check at this minute

  const AppSettings({
    // Session defaults
    this.defaultDurationMinutes = 45,
    this.defaultLockLevel = 'standard',
    this.defaultDestructionMode = false,
    this.quickDurations = const [15, 25, 45, 60, 90],


    // Lock behaviour
    this.softGraceSeconds = 15,
    this.standardGraceSeconds = 10,
    this.hardGraceSeconds = 5,
    this.softMaxEmergencyBreaks = 2,
    this.standardMaxEmergencyBreaks = 1,

    // Grayscale / DND
    this.grayscaleOnSession = true,
    this.dndOnSession = true,

    // Coins
    this.coinsPerMinute = 2,
    this.perfectSessionBonus = 15,
    this.streakWeeklyBonus = 10,
    this.coinsEnabled = true,

    // Accountability
    this.notifyPartnerOnSuccess = true,
    this.notifyPartnerOnFailure = true,

    // App persona
    this.appName = 'BIO-LOCKED',
    this.soundEnabled = true,
    this.hapticEnabled = true,

    // Spot check timing
    this.shortSessionThresholdMinutes = 5,
    this.mediumSessionThresholdMinutes = 15,
    this.longSessionSpotCheckMinutes = 12,
  });

  AppSettings copyWith({
    int? defaultDurationMinutes,
    String? defaultLockLevel,
    bool? defaultDestructionMode,
    List<int>? quickDurations,

    int? softGraceSeconds,
    int? standardGraceSeconds,
    int? hardGraceSeconds,
    int? softMaxEmergencyBreaks,
    int? standardMaxEmergencyBreaks,
    bool? grayscaleOnSession,
    bool? dndOnSession,
    int? coinsPerMinute,
    int? perfectSessionBonus,
    int? streakWeeklyBonus,
    bool? coinsEnabled,
    bool? notifyPartnerOnSuccess,
    bool? notifyPartnerOnFailure,
    String? appName,
    bool? soundEnabled,
    bool? hapticEnabled,
    int? shortSessionThresholdMinutes,
    int? mediumSessionThresholdMinutes,
    int? longSessionSpotCheckMinutes,
  }) {
    return AppSettings(
      defaultDurationMinutes:
          defaultDurationMinutes ?? this.defaultDurationMinutes,
      defaultLockLevel: defaultLockLevel ?? this.defaultLockLevel,
      defaultDestructionMode:
          defaultDestructionMode ?? this.defaultDestructionMode,
      quickDurations: quickDurations ?? this.quickDurations,

      softGraceSeconds: softGraceSeconds ?? this.softGraceSeconds,
      standardGraceSeconds: standardGraceSeconds ?? this.standardGraceSeconds,
      hardGraceSeconds: hardGraceSeconds ?? this.hardGraceSeconds,
      softMaxEmergencyBreaks:
          softMaxEmergencyBreaks ?? this.softMaxEmergencyBreaks,
      standardMaxEmergencyBreaks:
          standardMaxEmergencyBreaks ?? this.standardMaxEmergencyBreaks,
      grayscaleOnSession: grayscaleOnSession ?? this.grayscaleOnSession,
      dndOnSession: dndOnSession ?? this.dndOnSession,
      coinsPerMinute: coinsPerMinute ?? this.coinsPerMinute,
      perfectSessionBonus: perfectSessionBonus ?? this.perfectSessionBonus,
      streakWeeklyBonus: streakWeeklyBonus ?? this.streakWeeklyBonus,
      coinsEnabled: coinsEnabled ?? this.coinsEnabled,
      notifyPartnerOnSuccess:
          notifyPartnerOnSuccess ?? this.notifyPartnerOnSuccess,
      notifyPartnerOnFailure:
          notifyPartnerOnFailure ?? this.notifyPartnerOnFailure,
      appName: appName ?? this.appName,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      shortSessionThresholdMinutes:
          shortSessionThresholdMinutes ?? this.shortSessionThresholdMinutes,
      mediumSessionThresholdMinutes:
          mediumSessionThresholdMinutes ?? this.mediumSessionThresholdMinutes,
      longSessionSpotCheckMinutes:
          longSessionSpotCheckMinutes ?? this.longSessionSpotCheckMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultDurationMinutes': defaultDurationMinutes,
        'defaultLockLevel': defaultLockLevel,
        'defaultDestructionMode': defaultDestructionMode,
        'quickDurations': quickDurations,

        'softGraceSeconds': softGraceSeconds,
        'standardGraceSeconds': standardGraceSeconds,
        'hardGraceSeconds': hardGraceSeconds,
        'softMaxEmergencyBreaks': softMaxEmergencyBreaks,
        'standardMaxEmergencyBreaks': standardMaxEmergencyBreaks,
        'grayscaleOnSession': grayscaleOnSession,
        'dndOnSession': dndOnSession,
        'coinsPerMinute': coinsPerMinute,
        'perfectSessionBonus': perfectSessionBonus,
        'streakWeeklyBonus': streakWeeklyBonus,
        'coinsEnabled': coinsEnabled,
        'notifyPartnerOnSuccess': notifyPartnerOnSuccess,
        'notifyPartnerOnFailure': notifyPartnerOnFailure,
        'appName': appName,
        'soundEnabled': soundEnabled,
        'hapticEnabled': hapticEnabled,
        'shortSessionThresholdMinutes': shortSessionThresholdMinutes,
        'mediumSessionThresholdMinutes': mediumSessionThresholdMinutes,
        'longSessionSpotCheckMinutes': longSessionSpotCheckMinutes,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        defaultDurationMinutes: json['defaultDurationMinutes'] ?? 45,
        defaultLockLevel: json['defaultLockLevel'] ?? 'standard',
        defaultDestructionMode: json['defaultDestructionMode'] ?? false,
        quickDurations: (json['quickDurations'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [15, 25, 45, 60, 90],

        softGraceSeconds: json['softGraceSeconds'] ?? 15,
        standardGraceSeconds: json['standardGraceSeconds'] ?? 10,
        hardGraceSeconds: json['hardGraceSeconds'] ?? 5,
        softMaxEmergencyBreaks: json['softMaxEmergencyBreaks'] ?? 2,
        standardMaxEmergencyBreaks: json['standardMaxEmergencyBreaks'] ?? 1,
        grayscaleOnSession: json['grayscaleOnSession'] ?? true,
        dndOnSession: json['dndOnSession'] ?? true,
        coinsPerMinute: json['coinsPerMinute'] ?? 2,
        perfectSessionBonus: json['perfectSessionBonus'] ?? 15,
        streakWeeklyBonus: json['streakWeeklyBonus'] ?? 10,
        coinsEnabled: json['coinsEnabled'] ?? true,
        notifyPartnerOnSuccess: json['notifyPartnerOnSuccess'] ?? true,
        notifyPartnerOnFailure: json['notifyPartnerOnFailure'] ?? true,
        appName: json['appName'] ?? 'BIO-LOCKED',
        soundEnabled: json['soundEnabled'] ?? true,
        hapticEnabled: json['hapticEnabled'] ?? true,
        shortSessionThresholdMinutes:
            json['shortSessionThresholdMinutes'] ?? 5,
        mediumSessionThresholdMinutes:
            json['mediumSessionThresholdMinutes'] ?? 15,
        longSessionSpotCheckMinutes: json['longSessionSpotCheckMinutes'] ?? 12,
      );
}

/// ────────────────────────────────────────────────────────────────────────────
/// AppSettingsService — load / save to SharedPreferences
/// ────────────────────────────────────────────────────────────────────────────
class AppSettingsService {
  static const _key = 'app_settings_v1';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// ────────────────────────────────────────────────────────────────────────────
/// Riverpod — AppSettingsNotifier
/// ────────────────────────────────────────────────────────────────────────────
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  final _service = AppSettingsService();

  @override
  Future<AppSettings> build() => _service.load();

  Future<void> updateSettings(AppSettings Function(AppSettings) updater) async {
    final current = await future;
    final updated = updater(current);
    state = AsyncData(updated);
    await _service.save(updated);
  }

  Future<void> reset() async {
    await _service.reset();
    state = const AsyncData(AppSettings());
  }
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
