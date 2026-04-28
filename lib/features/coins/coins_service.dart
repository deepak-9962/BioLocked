import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Focus Coins — earned per completed minute, spent in the coin shop
class CoinsService {
  static const _balanceKey = 'focus_coins_balance';
  static const _totalEarnedKey = 'focus_coins_total_earned';
  static const _totalSpentKey = 'focus_coins_total_spent';

  // Earn rates
  static const int coinsPerMinute = 2;
  static const int streakBonusCoins = 10; // bonus per day of streak
  static const int perfectSessionBonus = 15; // 0 interruptions

  Future<int> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? 0;
  }

  Future<int> getTotalEarned() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalEarnedKey) ?? 0;
  }

  Future<int> getTotalSpent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalSpentKey) ?? 0;
  }

  /// Award coins after a completed session
  Future<int> awardCoins({
    required int durationMinutes,
    required int interruptions,
    required int streakDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    int earned = durationMinutes * coinsPerMinute;

    // Perfect session bonus
    if (interruptions == 0) {
      earned += perfectSessionBonus;
    }

    // Streak milestone bonuses
    if (streakDays > 0 && streakDays % 7 == 0) {
      earned += streakBonusCoins * (streakDays ~/ 7);
    }

    final current = prefs.getInt(_balanceKey) ?? 0;
    final totalEarned = prefs.getInt(_totalEarnedKey) ?? 0;

    await prefs.setInt(_balanceKey, current + earned);
    await prefs.setInt(_totalEarnedKey, totalEarned + earned);

    return earned;
  }

  /// Spend coins — returns true if successful
  Future<bool> spendCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_balanceKey) ?? 0;

    if (current < amount) return false;

    final totalSpent = prefs.getInt(_totalSpentKey) ?? 0;
    await prefs.setInt(_balanceKey, current - amount);
    await prefs.setInt(_totalSpentKey, totalSpent + amount);
    return true;
  }

  /// Reset (for testing)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, 0);
    await prefs.setInt(_totalEarnedKey, 0);
    await prefs.setInt(_totalSpentKey, 0);
  }
}

final coinsServiceProvider = Provider<CoinsService>((ref) => CoinsService());

final coinBalanceProvider = FutureProvider<int>((ref) async {
  return ref.read(coinsServiceProvider).getBalance();
});

/// Shop items
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int cost;
  final String type; // 'emergency_break', 'theme', 'bypass'

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    required this.type,
  });
}

const List<ShopItem> shopItems = [
  ShopItem(
    id: 'emergency_break_hard',
    name: 'Hard Lock Pardon',
    description: 'Get 1 emergency break for your next Hard Lock session',
    icon: '🔓',
    cost: 50,
    type: 'emergency_break',
  ),
  ShopItem(
    id: 'grace_extension',
    name: 'Grace Extension',
    description: 'Add 10 extra seconds to your grace period for 1 session',
    icon: '⏳',
    cost: 30,
    type: 'grace_extension',
  ),
  ShopItem(
    id: 'double_coins',
    name: 'Double Coins',
    description: 'Earn 2× coins from your next session',
    icon: '⚡',
    cost: 40,
    type: 'multiplier',
  ),
  ShopItem(
    id: 'streak_shield',
    name: 'Streak Shield',
    description: 'Protect your streak for 1 missed day',
    icon: '🛡️',
    cost: 100,
    type: 'streak_shield',
  ),
];
