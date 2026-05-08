import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../features/session/session_provider.dart';
import '../features/session/session_completion.dart';
import '../features/audio/sound_service.dart';
import '../features/level/level_service.dart';
import 'theme/luxury_theme.dart';
import 'share_card_dialog.dart';
import 'level_badge.dart';

class FinishedScreen extends ConsumerStatefulWidget {
  const FinishedScreen({super.key});

  @override
  ConsumerState<FinishedScreen> createState() => _FinishedScreenState();
}

class _FinishedScreenState extends ConsumerState<FinishedScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  bool _hasSpokenAnnouncement = false;
  bool _hasShownLevelUp = false;
  final List<_Confetti> _confettiPieces = [];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Generate confetti
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _confettiPieces.add(_Confetti(
        x: random.nextDouble(),
        delay: random.nextDouble(),
        speed: 0.3 + random.nextDouble() * 0.5,
        size: 4 + random.nextDouble() * 8,
        color: [
          LuxuryColors.burnishedGold,
          LuxuryColors.platinumBlue,
          LuxuryColors.emerald,
          LuxuryColors.champagneGold,
        ][random.nextInt(4)],
      ));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _speakAnnouncements(List<String> announcements) {
    if (_hasSpokenAnnouncement) return;
    _hasSpokenAnnouncement = true;

    final soundService = ref.read(soundServiceProvider);
    for (final announcement in announcements) {
      soundService.speak(announcement);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskName = ref.watch(taskNameProvider);
    final completionAsync = ref.watch(completedSessionFeedbackProvider);

    return Scaffold(
      backgroundColor: LuxuryColors.richBlack,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  LuxuryColors.emerald.withValues(alpha: 0.2),
                  LuxuryColors.richBlack,
                ],
              ),
            ),
          ),

          // Confetti animation
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  confetti: _confettiPieces,
                  animationValue: _confettiController.value,
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: completionAsync.when(
              data: (data) {
                if (data == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: LuxuryColors.platinumBlue,
                      strokeWidth: 2,
                    ),
                  );
                }
                // Speak achievements
                if (data.announcements.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _speakAnnouncements(data.announcements);
                  });
                }

                // Show level up dialog
                if (data.levelResult != null && data.levelResult!.didLevelUp && !_hasShownLevelUp) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_hasShownLevelUp) {
                      _hasShownLevelUp = true;
                      LevelUpDialog.show(context, data.levelResult!);
                    }
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // XP Earned Badge
                      if (data.levelResult != null)
                        _buildXpEarnedBadge(data.levelResult!),

                      const SizedBox(height: 24),

                      // Success badge
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LuxuryGradients.emeraldGlow,
                            boxShadow: [
                              BoxShadow(
                                color: LuxuryColors.emerald.withValues(alpha: 0.5),
                                blurRadius: 50,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            LuxuryColors.emerald,
                            LuxuryColors.platinumBlue,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'COMPLETE',
                          style: LuxuryTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: LuxuryColors.cardBackground,
                          border: Border.all(
                            color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          taskName.toUpperCase(),
                          style: LuxuryTextStyles.labelLarge.copyWith(
                            color: LuxuryColors.burnishedGold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Completion message
                      _buildFrostedCard(
                        child: Text(
                          data.completionMessage,
                          textAlign: TextAlign.center,
                          style: LuxuryTextStyles.bodyLarge.copyWith(
                            color: LuxuryColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),

                      // Achievements
                      if (data.newAchievements.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        ...data.announcements.asMap().entries.map((entry) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(
                                  milliseconds: (600 + (entry.key * 300)).toInt(),
                                ),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildAchievementCard(entry.value),
                          );
                        }),
                      ],

                      const SizedBox(height: 32),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.local_fire_department,
                              value: '${data.stats.currentStreak}',
                              label: 'Day Streak',
                              color: LuxuryColors.burnishedGold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.access_time,
                              value: '${data.stats.totalMinutes ~/ 60}h',
                              label: 'Total Focus',
                              color: LuxuryColors.platinumBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.check_circle,
                              value: '${data.stats.totalSessions}',
                              label: 'Sessions',
                              color: LuxuryColors.emerald,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Share Achievement Button
                      GestureDetector(
                        onTap: () {
                          ShareCardDialog.show(
                            context,
                            taskName: taskName,
                            durationMinutes: ref.read(taskDurationProvider),
                            stats: data.stats,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                LuxuryColors.burnishedGold.withValues(alpha: 0.15),
                                LuxuryColors.platinumBlue.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: LuxuryColors.burnishedGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.share_rounded,
                                color: LuxuryColors.burnishedGold,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Share Achievement',
                                style: LuxuryTextStyles.labelLarge.copyWith(
                                  color: LuxuryColors.burnishedGold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Demo mode upgrade prompt
                      if (ref.watch(demoModeProvider)) ...[
                        GestureDetector(
                          onTap: () {
                            ref.read(demoModeProvider.notifier).disable();
                            ref.read(sessionStateProvider.notifier).setSetup();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  LuxuryColors.platinumBlue.withValues(alpha: 0.2),
                                  LuxuryColors.burnishedGold.withValues(alpha: 0.1),
                                ],
                              ),
                              border: Border.all(
                                color: LuxuryColors.platinumBlue.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: LuxuryColors.platinumBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enable Full Checkpoints',
                                        style: LuxuryTextStyles.titleLarge.copyWith(
                                          color: LuxuryColors.platinumBlue,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Turn off demo mode for full checkpoint enforcement',
                                        style: LuxuryTextStyles.bodyMedium.copyWith(
                                          color: LuxuryColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: LuxuryColors.platinumBlue.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // New Session Button
                      GestureDetector(
                        onTap: () {
                          ref.read(sessionStateProvider.notifier).setCheckIn();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LuxuryGradients.emeraldGlow,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: LuxuryColors.emerald.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'NEW SESSION',
                                style: LuxuryTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: LuxuryColors.emerald,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Processing your achievement...',
                      style: LuxuryTextStyles.bodyMedium.copyWith(
                        color: LuxuryColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              error: (e, _) => _buildSimpleFinished(context, taskName),
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {
                    ref.read(sessionStateProvider.notifier).setCheckIn();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxuryColors.cardBackground,
                      border: Border.all(
                        color: LuxuryColors.subtleBorder,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: LuxuryColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LuxuryGradients.frostedGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAchievementCard(String announcement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LuxuryColors.burnishedGold.withValues(alpha: 0.25),
                  LuxuryColors.burnishedGold.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: LuxuryColors.burnishedGold.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LuxuryColors.burnishedGold.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: LuxuryColors.burnishedGold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    announcement,
                    style: LuxuryTextStyles.bodyLarge.copyWith(
                      color: LuxuryColors.champagneGold,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: LuxuryTextStyles.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: LuxuryTextStyles.bodyMedium.copyWith(
                  color: LuxuryColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpEarnedBadge(LevelUpResult result) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              LuxuryColors.burnishedGold.withValues(alpha: 0.2),
              LuxuryColors.burnishedGold.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: LuxuryColors.burnishedGold.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: LuxuryColors.burnishedGold.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LuxuryColors.burnishedGold.withValues(alpha: 0.2),
              ),
              child: Text(
                'LV${result.newLevel}',
                style: TextStyle(
                  color: LuxuryColors.burnishedGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${result.xpEarned} XP',
                  style: LuxuryTextStyles.titleLarge.copyWith(
                    color: LuxuryColors.burnishedGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 100,
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: LuxuryColors.cardBackground,
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: result.progress,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LuxuryGradients.goldShimmer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (result.didLevelUp) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: LuxuryColors.emerald.withValues(alpha: 0.2),
                ),
                child: Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    color: LuxuryColors.emerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleFinished(BuildContext context, String taskName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LuxuryGradients.emeraldGlow,
              boxShadow: [
                BoxShadow(
                  color: LuxuryColors.emerald.withValues(alpha: 0.5),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'SESSION COMPLETE',
            style: LuxuryTextStyles.headlineLarge.copyWith(
              color: LuxuryColors.emerald,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            taskName.toUpperCase(),
            style: LuxuryTextStyles.bodyLarge.copyWith(
              color: LuxuryColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 64),
          GestureDetector(
            onTap: () {
              ref.read(sessionStateProvider.notifier).setCheckIn();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                gradient: LuxuryGradients.emeraldGlow,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: LuxuryColors.emerald.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                'NEW SESSION',
                style: LuxuryTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;

  _Confetti({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double animationValue;

  _ConfettiPainter({required this.confetti, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final adjustedAnim = (animationValue + piece.delay) % 1.0;
      final y = adjustedAnim * size.height * (1 + piece.speed);

      if (y < size.height) {
        final paint = Paint()
          ..color = piece.color.withValues(alpha: 1 - adjustedAnim)
          ..style = PaintingStyle.fill;

        final x = piece.x * size.width +
            math.sin(adjustedAnim * math.pi * 4) * 30;

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(adjustedAnim * math.pi * 2);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.6,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
