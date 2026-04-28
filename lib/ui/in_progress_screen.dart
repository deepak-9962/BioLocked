import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../features/session/session_provider.dart';
import 'theme/luxury_theme.dart';

class InProgressScreen extends ConsumerStatefulWidget {
  const InProgressScreen({super.key});

  @override
  ConsumerState<InProgressScreen> createState() => _InProgressScreenState();
}

class _InProgressScreenState extends ConsumerState<InProgressScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _alarmController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _alarmPulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _alarmController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _alarmPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _alarmController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _alarmController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final taskName = ref.watch(taskNameProvider);
    final sessionState = ref.watch(sessionStateProvider);
    final remainingSeconds = ref.watch(remainingSecondsProvider);
    final health = ref.watch(healthProvider);
    final destructionMode = ref.watch(destructionModeProvider);
    final lockLevel = ref.watch(lockLevelProvider);
    final breaksUsedToday = ref.watch(emergencyBreaksUsedTodayProvider);
    final cooldownUntil = ref.watch(emergencyBreakCooldownUntilProvider);
    final duration = ref.watch(taskDurationProvider);
    final isAlarm = sessionState == SessionState.alarm;
    final isWaiting = sessionState == SessionState.waitingForFaceDown;

    final totalSeconds = duration * 60;
    final progress = totalSeconds > 0 ? (totalSeconds - remainingSeconds) / totalSeconds : 0.0;

    return Scaffold(
      backgroundColor: isAlarm ? LuxuryColors.rubyRed : LuxuryColors.richBlack,
      body: AnimatedBuilder(
        animation: isAlarm ? _alarmPulseAnimation : _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: isAlarm
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        LuxuryColors.rubyRed,
                        Color.lerp(
                          LuxuryColors.rubyRed,
                          Colors.red.shade900,
                          _alarmPulseAnimation.value,
                        )!,
                      ],
                    )
                  : LuxuryGradients.darkBackground,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar with health or status
                  _buildTopBar(
                    health: health,
                    destructionMode: destructionMode,
                    isWaiting: isWaiting,
                    isAlarm: isAlarm,
                    lockLevel: lockLevel,
                    breaksUsedToday: breaksUsedToday,
                    cooldownUntil: cooldownUntil,
                  ),

                  Expanded(
                    child: Center(
                      child: isWaiting
                          ? _buildWaitingState()
                          : isAlarm
                              ? _buildAlarmState()
                              : _buildInProgressState(
                                  taskName: taskName,
                                  remainingSeconds: remainingSeconds,
                                  progress: progress,
                                ),
                    ),
                  ),

                  // Bottom action
                  if (!isAlarm && !isWaiting)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (lockLevel != SessionLockLevel.hard)
                            GestureDetector(
                              onTap: () async {
                                final result = await ref
                                    .read(sessionStateProvider.notifier)
                                    .requestEmergencyBreak();
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result.message),
                                    backgroundColor: result.allowed
                                        ? LuxuryColors.emerald
                                        : LuxuryColors.rubyRed,
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        LuxuryColors.burnishedGold.withValues(alpha: 0.3),
                                  ),
                                  color: LuxuryColors.burnishedGold.withValues(alpha: 0.08),
                                ),
                                child: Text(
                                  'EMERGENCY BREAK',
                                  style: LuxuryTextStyles.bodyMedium.copyWith(
                                    color: LuxuryColors.burnishedGold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: () {
                              ref.read(sessionStateProvider.notifier).giveUpSession();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      LuxuryColors.textSecondary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                'GIVE UP',
                                style: LuxuryTextStyles.bodyMedium.copyWith(
                                  color:
                                      LuxuryColors.textSecondary.withValues(alpha: 0.3),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar({
    required int health,
    required bool destructionMode,
    required bool isWaiting,
    required bool isAlarm,
    required SessionLockLevel lockLevel,
    required int breaksUsedToday,
    required DateTime? cooldownUntil,
  }) {
    if (isWaiting || isAlarm) return const SizedBox(height: 16);

    final now = DateTime.now();
    final maxBreaks = lockLevel.maxEmergencyBreaksPerDay;
    final remainingBreaks = math.max(0, maxBreaks - breaksUsedToday);
    final isCoolingDown = cooldownUntil != null && cooldownUntil.isAfter(now);
    final cooldownMinutes = isCoolingDown
        ? cooldownUntil.difference(now).inMinutes + 1
        : 0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!destructionMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: LuxuryColors.cardBackground,
                    border: Border.all(
                      color: LuxuryColors.deepRose.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HEALTH',
                        style: LuxuryTextStyles.labelLarge.copyWith(
                          color: LuxuryColors.textSecondary,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ...List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.favorite,
                            color: index < health
                                ? LuxuryColors.deepRose
                                : LuxuryColors.cardBackground,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: LuxuryColors.rubyRed.withValues(alpha: 0.15),
                    border: Border.all(
                      color: LuxuryColors.rubyRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: LuxuryColors.rubyRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DESTRUCTION MODE',
                        style: LuxuryTextStyles.labelLarge.copyWith(
                          color: LuxuryColors.rubyRed,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildMetaChip(
                icon: Icons.lock_outline,
                text: '${lockLevel.label} lock',
                color: LuxuryColors.emerald,
              ),
              _buildMetaChip(
                icon: Icons.coffee,
                text: maxBreaks == 0
                    ? 'Breaks disabled'
                    : 'Breaks left $remainingBreaks/$maxBreaks',
                color: maxBreaks == 0
                    ? LuxuryColors.textSecondary
                    : LuxuryColors.burnishedGold,
              ),
              if (isCoolingDown)
                _buildMetaChip(
                  icon: Icons.hourglass_bottom,
                  text: 'Cooldown ${cooldownMinutes}m',
                  color: LuxuryColors.rubyRed,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: LuxuryTextStyles.bodyMedium.copyWith(
              color: color,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated phone icon with ripples
            Stack(
              alignment: Alignment.center,
              children: [
                // Ripple effects
                ...List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      final delay = index * 0.3;
                      final animValue = (_rotateController.value + delay) % 1.0;
                      return Container(
                        width: 120 + (animValue * 80),
                        height: 120 + (animValue * 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: LuxuryColors.platinumBlue.withValues(
                              alpha: (1 - animValue) * 0.3,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  );
                }),
                // Phone icon
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LuxuryGradients.platinumGold,
                      boxShadow: [
                        BoxShadow(
                          color: LuxuryColors.platinumBlue.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.screen_lock_portrait,
                      size: 48,
                      color: LuxuryColors.richBlack,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            Text(
              'PLACE DEVICE',
              style: LuxuryTextStyles.headlineLarge.copyWith(
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'face down on a flat surface',
              style: LuxuryTextStyles.bodyLarge.copyWith(
                color: LuxuryColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Instruction steps
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: LuxuryColors.cardBackground.withValues(alpha: 0.5),
                border: Border.all(
                  color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStep(1, 'Flip', Icons.flip),
                  _buildStep(2, 'Place', Icons.table_bar),
                  _buildStep(3, 'Focus', Icons.psychology),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep(int number, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LuxuryColors.platinumBlue.withValues(alpha: 0.1),
          ),
          child: Icon(
            icon,
            color: LuxuryColors.platinumBlue,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: LuxuryTextStyles.bodyMedium.copyWith(
            color: LuxuryColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmState() {
    return AnimatedBuilder(
      animation: _alarmPulseAnimation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Warning icon with pulse
            Transform.scale(
              scale: 1.0 + (_alarmPulseAnimation.value * 0.15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: 0.3 * _alarmPulseAnimation.value,
                      ),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 40),

            Text(
              'PUT IT DOWN!',
              style: LuxuryTextStyles.displayLarge.copyWith(
                color: Colors.white,
                fontSize: 36,
                letterSpacing: 4,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Text(
                '10 seconds to comply',
                style: LuxuryTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInProgressState({
    required String taskName,
    required int remainingSeconds,
    required double progress,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Task name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: LuxuryColors.cardBackground,
            border: Border.all(
              color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            taskName.toUpperCase(),
            style: LuxuryTextStyles.labelLarge.copyWith(
              color: LuxuryColors.burnishedGold,
              letterSpacing: 3,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Large circular timer
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LuxuryColors.emerald.withValues(alpha: 0.2),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // Progress ring
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(260, 260),
                    painter: _TimerRingPainter(
                      progress: progress,
                      rotationValue: _rotateController.value,
                    ),
                  );
                },
              ),

              // Time display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(remainingSeconds),
                    style: LuxuryTextStyles.displayLarge.copyWith(
                      fontSize: 64,
                      letterSpacing: 8,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: LuxuryColors.emerald,
                                boxShadow: [
                                  BoxShadow(
                                    color: LuxuryColors.emerald.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'FOCUSED',
                              style: LuxuryTextStyles.labelLarge.copyWith(
                                color: LuxuryColors.emerald,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Progress percentage
        Text(
          '${(progress * 100).toInt()}% Complete',
          style: LuxuryTextStyles.bodyMedium.copyWith(
            color: LuxuryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final double rotationValue;

  _TimerRingPainter({
    required this.progress,
    required this.rotationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 8.0;

    // Background track
    final trackPaint = Paint()
      ..color = LuxuryColors.cardBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = LuxuryGradients.emeraldGlow.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Glow dot at progress end
    if (progress > 0) {
      final endAngle = startAngle + sweepAngle;
      final glowX = center.dx + radius * math.cos(endAngle);
      final glowY = center.dy + radius * math.sin(endAngle);

      final glowPaint = Paint()
        ..color = LuxuryColors.emerald.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawCircle(Offset(glowX, glowY), 10, glowPaint);

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(glowX, glowY), 5, dotPaint);
    }

    // Subtle animated particles
    final particlePaint = Paint()
      ..color = LuxuryColors.emerald.withValues(alpha: 0.3);

    for (int i = 0; i < 6; i++) {
      final angle = (rotationValue * 2 * math.pi) + (i * math.pi / 3);
      final particleRadius = radius + 20;
      final x = center.dx + particleRadius * math.cos(angle);
      final y = center.dy + particleRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rotationValue != rotationValue;
  }
}
