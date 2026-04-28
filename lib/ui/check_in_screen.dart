import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../features/session/session_provider.dart';
import '../features/stats/stats_service.dart';
import '../features/coins/coins_service.dart';
import 'notification_settings_screen.dart';
import 'widgets/shared_bottom_nav_bar.dart';

// --- Custom Colors based on your HTML Design ---
class ZenColors {
  static const background = Color(0xFF141218); // surface-dim / body
  static const beigeAccent = Color(0xFFD6D3CC);
  static const border = Color(0xFF2F2F2F);
  static const textPrimary = Color(0xFFE6E0E9);
  static const textSecondary = Color(0xFF948E9C);
  static const cardBg = Color(0x3318181B); // zinc-900/20
}

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  @override
  Widget build(BuildContext context) {
    final energyLevel = ref.watch(energyLevelProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final lockLevel = ref.watch(lockLevelProvider);

    return Scaffold(
      backgroundColor: ZenColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStatusChips(statsAsync, lockLevel),
                    const SizedBox(height: 48),
                    _buildEnergyGauge(energyLevel),
                    const SizedBox(height: 48),
                    _buildPrimaryAction(),
                    const SizedBox(height: 48),
                    _buildBentoGrid(),
                    const SizedBox(height: 32),
                    _buildAestheticImage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ZenColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.spa, color: ZenColors.textPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'ZENFOCUS',
                style: const TextStyle(
                  color: ZenColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              ref.read(sessionStateProvider.notifier).setAccountSettings();
            },
            child: const Icon(Icons.settings, color: ZenColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(AsyncValue<UserStats> statsAsync, SessionLockLevel lockLevel) {
    final coinsAsync = ref.watch(coinBalanceProvider);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        statsAsync.when(
          data: (stats) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: ZenColors.cardBg,
              border: Border.all(color: ZenColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: ZenColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${stats.currentStreak} Day Streak',
                  style: const TextStyle(color: ZenColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: ZenColors.cardBg,
            border: Border.all(color: ZenColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, color: ZenColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                '${lockLevel.label} Lock',
                style: const TextStyle(color: ZenColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        // 🏆 Focus Coins chip
        coinsAsync.when(
          data: (coins) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x33D4AF37),
              border: Border.all(color: const Color(0x66D4AF37)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  '$coins coins',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildEnergyGauge(int energyLevel) {
    // Determine label based on energy level
    final String energyLabel;
    if (energyLevel >= 80) {
      energyLabel = 'Peak Focus';
    } else if (energyLevel >= 60) {
      energyLabel = 'Ready for Focus';
    } else if (energyLevel >= 40) {
      energyLabel = 'Moderate Energy';
    } else if (energyLevel >= 20) {
      energyLabel = 'Low Energy';
    } else {
      energyLabel = 'Rest Recommended';
    }

    final String energyDescription;
    if (energyLevel >= 80) {
      energyDescription = 'Your metabolic markers suggest peak cognitive readiness for deep work.';
    } else if (energyLevel >= 60) {
      energyDescription = 'Your metabolic markers suggest high cognitive readiness for deep work.';
    } else if (energyLevel >= 40) {
      energyDescription = 'You have moderate energy. A focused session is still achievable.';
    } else if (energyLevel >= 20) {
      energyDescription = 'Energy is low. Consider a shorter session or recovery mode.';
    } else {
      energyDescription = 'Your body signals rest. Consider entering recovery mode instead.';
    }

    return Column(
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gauge via CustomPaint
              SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _ZenEnergyPainter(progress: energyLevel / 100),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$energyLevel%',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: ZenColors.beigeAccent,
                    ),
                  ),
                  const Text(
                    'ENERGY LEVEL',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2.0,
                      color: ZenColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Interactive slider to set energy level
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Text('0', style: TextStyle(color: ZenColors.textSecondary, fontSize: 12)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: ZenColors.beigeAccent,
                    inactiveTrackColor: ZenColors.border,
                    thumbColor: ZenColors.beigeAccent,
                    overlayColor: ZenColors.beigeAccent.withOpacity(0.15),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: energyLevel.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (value) {
                      ref.read(energyLevelProvider.notifier).set(value.round());
                    },
                  ),
                ),
              ),
              const Text('100', style: TextStyle(color: ZenColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          energyLabel,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ZenColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          energyDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: ZenColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZenColors.beigeAccent,
          foregroundColor: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          ref.read(sessionStateProvider.notifier).setTunnelSetup();
        },
        child: const Text(
          'ENTER TUNNEL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        final sessionLogCard = GestureDetector(
          onTap: () {
            ref.read(sessionStateProvider.notifier).setHistory();
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ZenColors.cardBg,
              border: Border.all(color: ZenColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Session Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ZenColors.textPrimary)),
                    const Icon(Icons.history, color: ZenColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLogItem('Deep Work', 'Today, 09:15 AM', '90m'),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: ZenColors.border)),
                _buildLogItem('Creative Flow', 'Yesterday, 02:30 PM', '45m'),
              ],
            ),
          ),
        );

        final schedulesCard = GestureDetector(
          onTap: () {
            ref.read(sessionStateProvider.notifier).setAccountSettings();
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ZenColors.cardBg,
              border: Border.all(color: ZenColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Schedules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ZenColors.textPrimary)),
                    const Icon(Icons.event_note, color: ZenColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                _buildScheduleItem('Morning Session', '08:00 - 10:00', true),
                const SizedBox(height: 12),
                _buildScheduleItem('Evening Wind-down', '21:00 - 22:00', false),
              ],
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sessionLogCard,
              const SizedBox(height: 24),
              schedulesCard,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: sessionLogCard),
              const SizedBox(width: 24),
              Expanded(child: schedulesCard),
            ],
          );
        }
      },
    );
  }

  Widget _buildLogItem(String title, String subtitle, String duration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: ZenColors.textPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: ZenColors.textSecondary)),
          ],
        ),
        Text(duration, style: const TextStyle(fontSize: 14, color: ZenColors.textPrimary)),
      ],
    );
  }

  Widget _buildScheduleItem(String title, String time, bool active) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? const Color(0x4D27272A) : Colors.transparent, // zinc-800/30
        border: active ? Border.all(color: ZenColors.border) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 32,
            decoration: BoxDecoration(
              color: active ? ZenColors.textSecondary : const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: active ? ZenColors.textPrimary : ZenColors.textSecondary)),
              Text(time, style: TextStyle(fontSize: 12, color: active ? ZenColors.textSecondary : const Color(0xFF52525B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAestheticImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: ZenColors.border),
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCZGcVN3ddUHawueYUg9i6IVc308vIAAlRvJh--1FqVSBhcMB_sI4AIqXNBJSkNzypuwOkY50MS2l-BaGAVdPw_NECv923quIwPZ0SrX562DFoxxgVN9iPyCB_LG2CnUUsulYHABwOzXT3sX_StWi9rY06g-vW9mCGWkkbdFkmFeufY5chBXOnwUf-IiOD2yKGWJPW0LrOSQqB8xn6ibIgwPwekM2AnLcnpuxsOqmesWjjhwIvvFB54fZWE4uxghSiMMK2J4WYJTjI'
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
    );
  }

}
class _ZenEnergyPainter extends CustomPainter {
  final double progress;
  _ZenEnergyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    final bgPaint = Paint()
      ..color = ZenColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground track
    final fgPaint = Paint()
      ..color = ZenColors.beigeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


