import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/level/level_service.dart';
import 'theme/bio_theme.dart';

/// Widget to display user level, XP, and progress
class LevelBadge extends ConsumerWidget {
  final bool compact;

  const LevelBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelDataAsync = ref.watch(userLevelProvider);

    return levelDataAsync.when(
      data: (data) => compact 
          ? _buildCompactBadge(data) 
          : _buildFullBadge(data),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCompactBadge(UserLevelData data) {
    final progress = LevelSystem.levelProgress(data.totalXp);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            BioColors.primaryFixed.withValues(alpha: 0.2),
            BioColors.primaryFixed.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: BioColors.primaryFixed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level number
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BioColors.primaryFixed,
            ),
            child: Text(
              '${data.currentLevel}',
              style: const TextStyle(
                color: BioColors.onPrimaryFixed,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Progress bar
          SizedBox(
            width: 60,
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: BioColors.cardBg,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: BioColors.primaryFixed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${data.totalXp} XP',
            style: const TextStyle(
              color: BioColors.primaryFixed,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge(UserLevelData data) {
    final progress = LevelSystem.levelProgress(data.totalXp);
    final xpForNext = LevelSystem.xpForLevel(data.currentLevel + 1);
    final currentLevelXp = data.totalXp - LevelSystem.totalXpForLevel(data.currentLevel);
    final nextTitleLevel = LevelTitles.getNextTitleLevel(data.currentLevel);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                BioColors.primaryFixed.withValues(alpha: 0.15),
                BioColors.primaryFixed.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: BioColors.primaryFixed.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Level and title row
              Row(
                children: [
                  // Level circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BioColors.primaryFixed,
                      boxShadow: [
                        BoxShadow(
                          color: BioColors.primaryFixed.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'LV',
                            style: TextStyle(
                              color: BioColors.onPrimaryFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${data.currentLevel}',
                            style: const TextStyle(
                              color: BioColors.onPrimaryFixed,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and XP
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: BioTextStyles.headlineLg.copyWith(
                            color: BioColors.primaryFixed,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.totalXp} Total XP',
                          style: BioTextStyles.bodyMd.copyWith(
                            color: BioColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${data.currentLevel + 1}',
                        style: const TextStyle(
                          color: BioColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$currentLevelXp / $xpForNext XP',
                        style: const TextStyle(
                          color: BioColors.primaryFixed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: BioColors.cardBg,
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: BioColors.primaryFixed,
                            boxShadow: [
                              BoxShadow(
                                color: BioColors.primaryFixed.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Next title unlock
              if (nextTitleLevel != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: BioColors.purple500.withValues(alpha: 0.15),
                    border: Border.all(
                      color: BioColors.purple500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: BioColors.purple500,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next title at Level $nextTitleLevel: ${LevelTitles.titles[nextTitleLevel]}',
                          style: const TextStyle(
                            color: BioColors.purple500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Level up celebration dialog
class LevelUpDialog extends StatelessWidget {
  final LevelUpResult result;

  const LevelUpDialog({super.key, required this.result});

  static Future<void> show(BuildContext context, LevelUpResult result) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LevelUpDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BioColors.primaryFixed.withValues(alpha: 0.2),
                  BioColors.cardBg.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: BioColors.primaryFixed.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Level up icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BioColors.primaryFixed,
                    boxShadow: [
                      BoxShadow(
                        color: BioColors.primaryFixed.withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: BioColors.onPrimaryFixed,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'LEVEL UP!',
                  style: BioTextStyles.headlineXl.copyWith(
                    color: BioColors.primaryFixed,
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Level ${result.previousLevel} → ${result.newLevel}',
                  style: BioTextStyles.headlineLg.copyWith(
                    color: BioColors.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),

                if (result.newTitle != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          BioColors.purple500.withValues(alpha: 0.3),
                          BioColors.purple500.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: BioColors.purple500.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'NEW TITLE UNLOCKED',
                          style: TextStyle(
                            color: BioColors.purple500,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.newTitle!,
                          style: BioTextStyles.headlineLg.copyWith(
                            color: BioColors.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Text(
                  '+${result.xpEarned} XP',
                  style: BioTextStyles.headlineLg.copyWith(
                    color: BioColors.green500,
                  ),
                ),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    decoration: BoxDecoration(
                      color: BioColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AWESOME!',
                      style: BioTextStyles.labelCaps.copyWith(
                        color: BioColors.onPrimaryFixed,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
