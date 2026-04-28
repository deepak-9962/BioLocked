import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Categories for micro-wins
enum MicroWinCategory {
  creative,  // 🧠 Writing, designing, coding, learning
  wellness,  // 💪 Exercise, walking, stretching, meditation
  admin,     // 📋 Emails, bills, scheduling, organizing
  life,      // 🏠 Cleaning, cooking, errands, laundry
}

extension MicroWinCategoryExtension on MicroWinCategory {
  String get emoji {
    switch (this) {
      case MicroWinCategory.creative: return '🧠';
      case MicroWinCategory.wellness: return '💪';
      case MicroWinCategory.admin: return '📋';
      case MicroWinCategory.life: return '🏠';
    }
  }

  String get label {
    switch (this) {
      case MicroWinCategory.creative: return 'Creative';
      case MicroWinCategory.wellness: return 'Wellness';
      case MicroWinCategory.admin: return 'Admin';
      case MicroWinCategory.life: return 'Life';
    }
  }

  String get description {
    switch (this) {
      case MicroWinCategory.creative: return 'Writing, designing, learning';
      case MicroWinCategory.wellness: return 'Exercise, health, self-care';
      case MicroWinCategory.admin: return 'Emails, organizing, tasks';
      case MicroWinCategory.life: return 'Home, errands, daily life';
    }
  }

  List<String> get quickWins {
    switch (this) {
      case MicroWinCategory.creative:
        return [
          'Wrote 100+ words',
          'Sketched an idea',
          'Read an article',
          'Watched a tutorial',
          'Brainstormed ideas',
          'Practiced a skill',
        ];
      case MicroWinCategory.wellness:
        return [
          'Short walk',
          'Stretched',
          'Drank water',
          'Healthy snack',
          'Deep breathing',
          'Meditated 5 min',
        ];
      case MicroWinCategory.admin:
        return [
          'Cleared 5 emails',
          'Made a call',
          'Paid a bill',
          'Updated calendar',
          'Organized files',
          'Replied to messages',
        ];
      case MicroWinCategory.life:
        return [
          'Tidied desk',
          'Did laundry',
          'Cooked a meal',
          'Ran an errand',
          'Fixed something',
          'Cleaned a room',
        ];
    }
  }

  // Colors for each category
  int get colorValue {
    switch (this) {
      case MicroWinCategory.creative: return 0xFF9B59B6; // Amethyst
      case MicroWinCategory.wellness: return 0xFF50C878; // Emerald
      case MicroWinCategory.admin: return 0xFF8BB8E8; // Platinum Blue
      case MicroWinCategory.life: return 0xFFD4AF37; // Burnished Gold
    }
  }
}

/// A single micro-win entry
class MicroWin {
  final String id;
  final String title;
  final MicroWinCategory category;
  final DateTime timestamp;
  final String? note;

  MicroWin({
    required this.id,
    required this.title,
    required this.category,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
  };

  factory MicroWin.fromJson(Map<String, dynamic> json) => MicroWin(
    id: json['id'],
    title: json['title'],
    category: MicroWinCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => MicroWinCategory.life,
    ),
    timestamp: DateTime.parse(json['timestamp']),
    note: json['note'],
  );
}

/// Daily micro-wins summary
class DailyMicroWins {
  final DateTime date;
  final List<MicroWin> wins;

  DailyMicroWins({
    required this.date,
    required this.wins,
  });

  int get count => wins.length;
  
  bool get protectsStreak => count >= 3;

  int get winsUntilProtected => protectsStreak ? 0 : 3 - count;

  Map<MicroWinCategory, int> get countByCategory {
    final counts = <MicroWinCategory, int>{};
    for (final win in wins) {
      counts[win.category] = (counts[win.category] ?? 0) + 1;
    }
    return counts;
  }
}

/// Service for managing micro-wins
class MicroWinsService {
  static const _storage = FlutterSecureStorage();
  static const _winsKey = 'micro_wins';

  /// Get all micro-wins
  Future<List<MicroWin>> getAllWins() async {
    final data = await _storage.read(key: _winsKey);
    if (data == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((j) => MicroWin.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get today's micro-wins
  Future<DailyMicroWins> getTodayWins() async {
    final allWins = await getAllWins();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayWins = allWins.where((win) {
      final winDate = DateTime(
        win.timestamp.year,
        win.timestamp.month,
        win.timestamp.day,
      );
      return winDate == today;
    }).toList();

    return DailyMicroWins(date: today, wins: todayWins);
  }

  /// Log a new micro-win
  Future<MicroWin> logWin({
    required String title,
    required MicroWinCategory category,
    String? note,
  }) async {
    final wins = await getAllWins();
    
    final newWin = MicroWin(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      timestamp: DateTime.now(),
      note: note,
    );
    
    wins.add(newWin);
    
    // Keep only last 200 wins
    if (wins.length > 200) {
      wins.removeRange(0, wins.length - 200);
    }
    
    await _storage.write(
      key: _winsKey,
      value: jsonEncode(wins.map((w) => w.toJson()).toList()),
    );
    
    return newWin;
  }

  /// Check if today's streak is protected by micro-wins
  Future<bool> isTodayStreakProtected() async {
    final todayWins = await getTodayWins();
    return todayWins.protectsStreak;
  }

  /// Get micro-wins count for today
  Future<int> getTodayCount() async {
    final todayWins = await getTodayWins();
    return todayWins.count;
  }

  /// Get total micro-wins count
  Future<int> getTotalCount() async {
    final wins = await getAllWins();
    return wins.length;
  }

  /// Get weekly summary (last 7 days)
  Future<List<DailyMicroWins>> getWeekSummary() async {
    final allWins = await getAllWins();
    final now = DateTime.now();
    final summary = <DailyMicroWins>[];
    
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayWins = allWins.where((win) {
        final winDate = DateTime(
          win.timestamp.year,
          win.timestamp.month,
          win.timestamp.day,
        );
        return winDate == date;
      }).toList();
      
      summary.add(DailyMicroWins(date: date, wins: dayWins));
    }
    
    return summary;
  }
}

// Providers
final microWinsServiceProvider = Provider<MicroWinsService>((ref) => MicroWinsService());

final todayMicroWinsProvider = FutureProvider<DailyMicroWins>((ref) async {
  return ref.read(microWinsServiceProvider).getTodayWins();
});

final microWinsCountProvider = FutureProvider<int>((ref) async {
  return ref.read(microWinsServiceProvider).getTodayCount();
});

final isStreakProtectedProvider = FutureProvider<bool>((ref) async {
  return ref.read(microWinsServiceProvider).isTodayStreakProtected();
});
