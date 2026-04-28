import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../features/session/session_provider.dart';
import 'theme/luxury_theme.dart';
import 'widgets/shared_bottom_nav_bar.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryColors.richBlack,
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 2),
      body: Stack(
        children: [
          // Animated wave background
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _WavePainter(
                  animationValue: _waveController.value,
                ),
              );
            },
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  LuxuryColors.richBlack.withValues(alpha: 0.3),
                  LuxuryColors.richBlack.withValues(alpha: 0.9),
                  LuxuryColors.richBlack,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Content — wrapped in SingleChildScrollView so it scrolls on small screens
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Top bar with back button
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
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
                              color: LuxuryColors.platinumBlue.withValues(alpha: 0.1),
                              border: Border.all(
                                color: LuxuryColors.platinumBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: LuxuryColors.platinumBlue,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48), // replaces top Spacer

                  // Recovery icon
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxuryColors.platinumBlue.withValues(alpha: 0.1),
                      border: Border.all(
                        color: LuxuryColors.platinumBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.spa,
                      size: 56,
                      color: LuxuryColors.platinumBlue,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'RECOVERY MODE',
                    style: LuxuryTextStyles.headlineLarge.copyWith(
                      color: LuxuryColors.platinumBlue,
                      letterSpacing: 6,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Your energy is low. Take it easy.\nNo strict locks. Just gentle recovery.',
                    textAlign: TextAlign.center,
                    style: LuxuryTextStyles.bodyLarge.copyWith(
                      color: LuxuryColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Suggested actions header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: LuxuryColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GENTLE ACTIVITIES',
                        style: LuxuryTextStyles.labelLarge.copyWith(
                          color: LuxuryColors.textSecondary.withValues(alpha: 0.7),
                          letterSpacing: 3,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: LuxuryColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Activity cards
                  _buildActivityCard(
                    context,
                    title: 'Breathing Exercise',
                    subtitle: 'Calm your mind with deep breaths',
                    icon: Icons.air,
                    color: LuxuryColors.platinumBlue,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    context,
                    title: 'Light Reading',
                    subtitle: 'Enjoy a book or article',
                    icon: Icons.menu_book,
                    color: LuxuryColors.amethyst,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    context,
                    title: 'Gentle Sketching',
                    subtitle: 'Express yourself creatively',
                    icon: Icons.brush,
                    color: LuxuryColors.burnishedGold,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    context,
                    title: 'Take a Walk',
                    subtitle: 'Move your body, clear your head',
                    icon: Icons.directions_walk,
                    color: LuxuryColors.emerald,
                  ),

                  const SizedBox(height: 40), // replaces bottom Spacer

                  // Exit button
                  GestureDetector(
                    onTap: () {
                      ref.read(sessionStateProvider.notifier).setCheckIn();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: LuxuryColors.platinumBlue.withValues(alpha: 0.5),
                        ),
                        color: LuxuryColors.cardBackground.withValues(alpha: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: LuxuryColors.platinumBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'FEELING BETTER? CHECK IN',
                            style: LuxuryTextStyles.labelLarge.copyWith(
                              color: LuxuryColors.platinumBlue,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Starting $title...',
              style: TextStyle(color: LuxuryColors.textPrimary),
            ),
            backgroundColor: LuxuryColors.cardBackground,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: LuxuryTextStyles.titleLarge.copyWith(
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: LuxuryTextStyles.bodyMedium.copyWith(
                          color: LuxuryColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;

  _WavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw multiple wave layers
    for (int i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = LuxuryColors.platinumBlue.withValues(alpha: 0.05 - (i * 0.015))
        ..style = PaintingStyle.fill;

      final path = Path();
      final waveHeight = 40.0 + (i * 20);
      final speed = 1.0 + (i * 0.3);
      final phase = animationValue * 2 * math.pi * speed;

      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.4 +
            math.sin((x / size.width * 2 * math.pi) + phase) * waveHeight +
            math.sin((x / size.width * 4 * math.pi) + phase * 0.7) *
                (waveHeight * 0.5);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
