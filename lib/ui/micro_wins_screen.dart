import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../features/micro_wins/micro_wins_service.dart';
import '../features/session/session_provider.dart';
import '../features/audio/sound_service.dart';
import 'theme/bio_theme.dart';

class MicroWinsScreen extends ConsumerStatefulWidget {
  const MicroWinsScreen({super.key});

  @override
  ConsumerState<MicroWinsScreen> createState() => _MicroWinsScreenState();
}

class _MicroWinsScreenState extends ConsumerState<MicroWinsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  MicroWinCategory? _selectedCategory;
  final TextEditingController _customWinController = TextEditingController();
  bool _showConfetti = false;
  final List<_ConfettiPiece> _confettiPieces = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Generate confetti pieces
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _confettiPieces.add(_ConfettiPiece(
        x: random.nextDouble(),
        delay: random.nextDouble(),
        speed: 0.3 + random.nextDouble() * 0.5,
        size: 4 + random.nextDouble() * 8,
        color: [
          BioColors.primaryFixed,
          BioColors.blue400,
          BioColors.green500,
          BioColors.purple500,
        ][random.nextInt(4)],
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    _customWinController.dispose();
    super.dispose();
  }

  Future<void> _logMicroWin(String title, MicroWinCategory category) async {
    HapticFeedback.mediumImpact();
    
    final service = ref.read(microWinsServiceProvider);
    await service.logWin(title: title, category: category);
    
    // Refresh the provider
    ref.invalidate(todayMicroWinsProvider);
    
    // Check if streak is now protected
    final todayWins = await service.getTodayWins();
    
    if (todayWins.protectsStreak && !_showConfetti) {
      setState(() => _showConfetti = true);
      _confettiController.repeat();
      ref.read(soundServiceProvider).speak("Streak protected! Great job!");
      
      // Stop confetti after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _confettiController.stop();
          setState(() => _showConfetti = false);
        }
      });
    } else {
      ref.read(soundServiceProvider).speak("Win logged!");
    }

    // Reset selection
    setState(() => _selectedCategory = null);
    _customWinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final todayWinsAsync = ref.watch(todayMicroWinsProvider);

    return Scaffold(
      backgroundColor: BioColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BioColors.background,
                  Color(0xFF0D0E12),
                ],
              ),
            ),
          ),

          // Confetti animation
          if (_showConfetti)
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
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Header with back button and progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(sessionStateProvider.notifier).setCheckIn();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: BioColors.cardBg,
                            border: Border.all(
                              color: BioColors.blue400.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: BioColors.blue400,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Progress indicator
                      todayWinsAsync.when(
                        data: (wins) => _buildProgressBadge(wins),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Title section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 0.9 + (_pulseController.value * 0.1),
                                child: const Text(
                                  '⚡',
                                  style: TextStyle(fontSize: 32),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                BioColors.primaryFixed,
                                BioColors.blue400,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'MICRO-WINS',
                              style: BioTextStyles.headlineLg.copyWith(
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Low energy? Log quick wins to protect your streak!',
                        textAlign: TextAlign.center,
                        style: BioTextStyles.bodyMd.copyWith(
                          color: BioColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Streak protection status
                todayWinsAsync.when(
                  data: (wins) => _buildStreakStatus(wins),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Category or quick wins
                Expanded(
                  child: _selectedCategory == null
                      ? _buildCategoryGrid()
                      : _buildQuickWinsList(_selectedCategory!),
                ),

                // Today's wins list
                todayWinsAsync.when(
                  data: (wins) => wins.count > 0
                      ? _buildTodayWinsList(wins)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(DailyMicroWins wins) {
    final isProtected = wins.protectsStreak;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isProtected
                ? LinearGradient(
                    colors: [BioColors.green500, BioColors.green500.withValues(alpha: 0.7)],
                  )
                : LinearGradient(
                    colors: [
                      BioColors.surfaceContainerHigh.withValues(alpha: 0.5),
                      BioColors.surfaceContainerHigh.withValues(alpha: 0.3),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isProtected
                  ? BioColors.green500.withValues(alpha: 0.5)
                  : BioColors.blue400.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isProtected ? Icons.shield : Icons.shield_outlined,
                color: isProtected ? Colors.white : BioColors.blue400,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${wins.count}/3',
                style: BioTextStyles.labelCaps.copyWith(
                  color: isProtected ? Colors.white : BioColors.blue400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakStatus(DailyMicroWins wins) {
    final isProtected = wins.protectsStreak;
    final remaining = wins.winsUntilProtected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isProtected
                  ? LinearGradient(
                      colors: [
                        BioColors.green500.withValues(alpha: 0.2),
                        BioColors.green500.withValues(alpha: 0.1),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        BioColors.surfaceContainerHigh.withValues(alpha: 0.5),
                        BioColors.surfaceContainerHigh.withValues(alpha: 0.3),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isProtected
                    ? BioColors.green500.withValues(alpha: 0.5)
                    : BioColors.primaryFixed.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isProtected
                        ? BioColors.green500.withValues(alpha: 0.2)
                        : BioColors.primaryFixed.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    isProtected ? Icons.verified : Icons.local_fire_department,
                    color: isProtected
                        ? BioColors.green500
                        : BioColors.primaryFixed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isProtected
                            ? '🎉 STREAK PROTECTED!'
                            : '🔥 $remaining more to protect streak',
                        style: BioTextStyles.headlineLg.copyWith(
                          color: isProtected
                              ? BioColors.green500
                              : BioColors.primaryFixed,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isProtected
                            ? 'Great job! You kept your momentum going.'
                            : 'Log $remaining quick win${remaining > 1 ? 's' : ''} to save your streak',
                        style: BioTextStyles.bodyMd.copyWith(
                          color: BioColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHOOSE CATEGORY',
            style: BioTextStyles.labelCaps.copyWith(
              color: BioColors.onSurfaceVariant,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: MicroWinCategory.values.map((category) {
                return _buildCategoryCard(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(MicroWinCategory category) {
    final color = Color(category.colorValue);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedCategory = category);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  category.label.toUpperCase(),
                  style: BioTextStyles.labelCaps.copyWith(
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  textAlign: TextAlign.center,
                  style: BioTextStyles.bodyMd.copyWith(
                    color: BioColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickWinsList(MicroWinCategory category) {
    final color = Color(category.colorValue);
    final quickWins = category.quickWins;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to categories
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: BioTextStyles.bodyMd.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                category.label.toUpperCase(),
                style: BioTextStyles.labelCaps.copyWith(
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick wins grid
          Expanded(
            child: ListView(
              children: [
                // Pre-defined quick wins
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: quickWins.map((win) {
                    return GestureDetector(
                      onTap: () => _logMicroWin(win, category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.15),
                              color.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              win,
                              style: BioTextStyles.bodyMd.copyWith(
                                color: BioColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Custom win input
                Text(
                  'OR LOG CUSTOM WIN',
                  style: BioTextStyles.labelCaps.copyWith(
                    color: BioColors.onSurfaceVariant,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: BioColors.cardBg,
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _customWinController,
                          style: BioTextStyles.bodyLg.copyWith(
                            color: BioColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'What did you accomplish?',
                            hintStyle: BioTextStyles.bodyMd.copyWith(
                              color: BioColors.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _logMicroWin(value.trim(), category);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (_customWinController.text.trim().isNotEmpty) {
                          _logMicroWin(_customWinController.text.trim(), category);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: BioColors.background,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWinsList(DailyMicroWins wins) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S WINS (${wins.count})',
            style: BioTextStyles.labelCaps.copyWith(
              color: BioColors.onSurfaceVariant,
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wins.wins.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final win = wins.wins[index];
                final color = Color(win.category.colorValue);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(win.category.emoji),
                      const SizedBox(width: 8),
                      Text(
                        win.title,
                        style: BioTextStyles.bodyMd.copyWith(
                          color: BioColors.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;

  _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> confetti;
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
