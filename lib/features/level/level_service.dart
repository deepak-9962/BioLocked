import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User level and XP system for gamification
class LevelSystem {
  /// XP required per level (increases progressively)
  static int xpForLevel(int level) {
    if (level <= 0) return 0;
    return (100 * level * (1 + level * 0.1)).toInt();
  }

  /// Get total XP required to reach a level
  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  /// Calculate level from total XP
  static int levelFromXp(int totalXp) {
    int level = 0;
    int xpRequired = 0;
    while (xpRequired + xpForLevel(level + 1) <= totalXp) {
      level++;
      xpRequired += xpForLevel(level);
    }
    return level;
  }

  /// Get XP progress within current level (0.0 to 1.0)
  static double levelProgress(int totalXp) {
    final currentLevel = levelFromXp(totalXp);
    final xpForCurrentLevel = totalXpForLevel(currentLevel);
    final xpToNextLevel = xpForLevel(currentLevel + 1);
    final currentLevelXp = totalXp - xpForCurrentLevel;
    return currentLevelXp / xpToNextLevel;
  }

  /// Calculate XP earned from a session
  static int calculateSessionXp({
    required int durationMinutes,
    required bool wasSuccessful,
    required bool destructionMode,
    required int energyLevel,
  }) {
    // Base XP: 1 XP per minute
    int xp = durationMinutes;
    
    // Bonus for successful completion
    if (wasSuccessful) {
      xp = (xp * 1.5).toInt();
    }
    
    // Destruction mode bonus
    if (destructionMode && wasSuccessful) {
      xp = (xp * 2).toInt();
    }
    
    // Low energy bonus (harder to focus when tired)
    if (energyLevel < 40) {
      xp = (xp * 1.25).toInt();
    }
    
    // Long session bonus (focus stamina)
    if (durationMinutes >= 60) {
      xp += 20;
    } else if (durationMinutes >= 90) {
      xp += 50;
    }
    
    return xp;
  }
}

/// User level data model
class UserLevelData {
  int totalXp;
  int currentLevel;
  String title;
  int sessionsAtLevel;
  DateTime? lastLevelUp;
  List<String> unlockedTitles;

  UserLevelData({
    this.totalXp = 0,
    this.currentLevel = 1,
    this.title = 'Novice Focuser',
    this.sessionsAtLevel = 0,
    this.lastLevelUp,
    List<String>? unlockedTitles,
  }) : unlockedTitles = unlockedTitles ?? ['Novice Focuser'];

  Map<String, dynamic> toJson() => {
    'totalXp': totalXp,
    'currentLevel': currentLevel,
    'title': title,
    'sessionsAtLevel': sessionsAtLevel,
    'lastLevelUp': lastLevelUp?.toIso8601String(),
    'unlockedTitles': unlockedTitles,
  };

  factory UserLevelData.fromJson(Map<String, dynamic> json) => UserLevelData(
    totalXp: json['totalXp'] ?? 0,
    currentLevel: json['currentLevel'] ?? 1,
    title: json['title'] ?? 'Novice Focuser',
    sessionsAtLevel: json['sessionsAtLevel'] ?? 0,
    lastLevelUp: json['lastLevelUp'] != null 
        ? DateTime.parse(json['lastLevelUp']) 
        : null,
    unlockedTitles: List<String>.from(json['unlockedTitles'] ?? ['Novice Focuser']),
  );

  UserLevelData copyWith({
    int? totalXp,
    int? currentLevel,
    String? title,
    int? sessionsAtLevel,
    DateTime? lastLevelUp,
    List<String>? unlockedTitles,
  }) => UserLevelData(
    totalXp: totalXp ?? this.totalXp,
    currentLevel: currentLevel ?? this.currentLevel,
    title: title ?? this.title,
    sessionsAtLevel: sessionsAtLevel ?? this.sessionsAtLevel,
    lastLevelUp: lastLevelUp ?? this.lastLevelUp,
    unlockedTitles: unlockedTitles ?? this.unlockedTitles,
  );
}

/// Level titles and their unlock levels
class LevelTitles {
  static const Map<int, String> titles = {
    1: 'Novice Focuser',
    3: 'Apprentice Mind',
    5: 'Focus Initiate',
    8: 'Tunnel Walker',
    12: 'Deep Worker',
    15: 'Focus Warrior',
    20: 'Mind Master',
    25: 'Zen Architect',
    30: 'Flow State Sensei',
    40: 'Grand Focus Master',
    50: 'Legendary Deep Worker',
    75: 'Mythic Concentrator',
    100: 'Transcendent Focus God',
  };

  static String getTitleForLevel(int level) {
    String title = 'Novice Focuser';
    for (final entry in titles.entries) {
      if (level >= entry.key) {
        title = entry.value;
      }
    }
    return title;
  }

  static List<String> getUnlockedTitles(int level) {
    return titles.entries
        .where((e) => e.key <= level)
        .map((e) => e.value)
        .toList();
  }

  static int? getNextTitleLevel(int currentLevel) {
    for (final level in titles.keys) {
      if (level > currentLevel) return level;
    }
    return null;
  }
}

/// Level service for managing XP and levels
class LevelService {
  static const _storage = FlutterSecureStorage();
  static const _levelKey = 'user_level_data';
  static const _progressTable = 'user_progress';

  /// Get current level data
  Future<UserLevelData> getLevelData() async {
    final data = await _storage.read(key: _levelKey);
    if (data != null) {
      try {
        return UserLevelData.fromJson(jsonDecode(data));
      } catch (e) {
        debugPrint('[LevelService] Failed to decode local level data: $e');
      }
    }

    final remote = await _loadRemoteLevelData();
    if (remote != null) {
      await _storage.write(
        key: _levelKey,
        value: jsonEncode(remote.toJson()),
      );
      return remote;
    }
    return UserLevelData();
  }

  /// Save level data
  Future<void> saveLevelData(UserLevelData data) async {
    await _storage.write(
      key: _levelKey,
      value: jsonEncode(data.toJson()),
    );
    await _syncLevelToRemote(data);
  }

  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (e) {
      debugPrint('[LevelService] Supabase not available: $e');
      return null;
    }
  }

  Future<UserLevelData?> _loadRemoteLevelData() async {
    final userId = _currentUserId();
    if (userId == null) return null;
    try {
      final rows = await Supabase.instance.client
          .from(_progressTable)
          .select('level_json')
          .eq('user_id', userId)
          .limit(1);
      if (rows.isEmpty) return null;
      final row = Map<String, dynamic>.from(rows.first as Map);
      final rawLevel = row['level_json'];
      if (rawLevel is! Map) return null;
      return UserLevelData.fromJson(Map<String, dynamic>.from(rawLevel));
    } catch (e) {
      debugPrint('[LevelService] Remote level fetch failed: $e');
      return null;
    }
  }

  Future<void> _syncLevelToRemote(UserLevelData data) async {
    final userId = _currentUserId();
    if (userId == null) return;
    try {
      await Supabase.instance.client.from(_progressTable).upsert(
        {
          'user_id': userId,
          'level_json': data.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('[LevelService] Remote level sync failed: $e');
    }
  }

  /// Add XP and check for level up
  Future<LevelUpResult> addXp({
    required int durationMinutes,
    required bool wasSuccessful,
    required bool destructionMode,
    required int energyLevel,
  }) async {
    final levelData = await getLevelData();
    
    final xpEarned = LevelSystem.calculateSessionXp(
      durationMinutes: durationMinutes,
      wasSuccessful: wasSuccessful,
      destructionMode: destructionMode,
      energyLevel: energyLevel,
    );
    
    final newTotalXp = levelData.totalXp + xpEarned;
    final newLevel = LevelSystem.levelFromXp(newTotalXp);
    final didLevelUp = newLevel > levelData.currentLevel;
    
    String? newTitle;
    if (didLevelUp) {
      newTitle = LevelTitles.getTitleForLevel(newLevel);
    }
    
    final updatedData = levelData.copyWith(
      totalXp: newTotalXp,
      currentLevel: newLevel,
      title: newTitle ?? levelData.title,
      sessionsAtLevel: didLevelUp ? 0 : levelData.sessionsAtLevel + 1,
      lastLevelUp: didLevelUp ? DateTime.now() : levelData.lastLevelUp,
      unlockedTitles: LevelTitles.getUnlockedTitles(newLevel),
    );
    
    await saveLevelData(updatedData);
    
    return LevelUpResult(
      xpEarned: xpEarned,
      totalXp: newTotalXp,
      previousLevel: levelData.currentLevel,
      newLevel: newLevel,
      didLevelUp: didLevelUp,
      newTitle: didLevelUp ? newTitle : null,
      progress: LevelSystem.levelProgress(newTotalXp),
    );
  }
}

/// Result of adding XP
class LevelUpResult {
  final int xpEarned;
  final int totalXp;
  final int previousLevel;
  final int newLevel;
  final bool didLevelUp;
  final String? newTitle;
  final double progress;

  LevelUpResult({
    required this.xpEarned,
    required this.totalXp,
    required this.previousLevel,
    required this.newLevel,
    required this.didLevelUp,
    this.newTitle,
    required this.progress,
  });
}

final levelServiceProvider = Provider<LevelService>((ref) => LevelService());

final userLevelProvider = FutureProvider<UserLevelData>((ref) async {
  return ref.read(levelServiceProvider).getLevelData();
});
