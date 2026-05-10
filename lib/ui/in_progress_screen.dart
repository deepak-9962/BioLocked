import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/session/session_provider.dart';
import 'theme/web_app_theme.dart';

class InProgressScreen extends ConsumerWidget {
  const InProgressScreen({super.key});

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionStateProvider);
    final taskName = ref.watch(taskNameProvider);
    final remainingSeconds = ref.watch(remainingSecondsProvider);
    final duration = ref.watch(taskDurationProvider);
    final lockLevel = ref.watch(lockLevelProvider);
    final health = ref.watch(healthProvider);
    final destructionMode = ref.watch(destructionModeProvider);
    final interruptions = ref.watch(sessionInterruptionsProvider);
    final breaksUsedToday = ref.watch(emergencyBreaksUsedTodayProvider);
    final cooldownUntil = ref.watch(emergencyBreakCooldownUntilProvider);

    final isAlarm = sessionState == SessionState.alarm;
    final isWaiting = sessionState == SessionState.waitingForFaceDown;
    final totalSeconds = duration * 60;
    final progress = totalSeconds <= 0
        ? 0.0
        : ((totalSeconds - remainingSeconds) / totalSeconds).clamp(0.0, 1.0);

    return WebAppScaffold(
      child: Container(
        color: isAlarm ? WebAppColors.red.withValues(alpha: 0.18) : null,
        child: Column(
          children: [
            WebTopBar(title: isAlarm ? 'LOCK ALERT' : 'ACTIVE SESSION'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  if (isWaiting)
                    _WaitingPanel(lockLevel: lockLevel)
                  else if (isAlarm)
                    _AlarmPanel(lockLevel: lockLevel)
                  else
                    _FocusPanel(
                      taskName: taskName,
                      remainingText: _formatTime(remainingSeconds),
                      progress: progress,
                    ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      WebMetricTile(label: 'Lock', value: lockLevel.label, icon: Icons.lock_outline),
                      WebMetricTile(
                        label: destructionMode ? 'Mode' : 'Health',
                        value: destructionMode ? 'Destroy' : '$health/3',
                        icon: destructionMode ? Icons.warning_amber : Icons.favorite_border,
                      ),
                      WebMetricTile(
                        label: 'Pickups',
                        value: '$interruptions',
                        icon: Icons.phone_android,
                      ),
                      WebMetricTile(
                        label: 'Breaks used',
                        value: '$breaksUsedToday/${lockLevel.maxEmergencyBreaksPerDay}',
                        icon: Icons.coffee,
                      ),
                    ],
                  ),
                  if (cooldownUntil != null && cooldownUntil.isAfter(DateTime.now())) ...[
                    const SizedBox(height: 14),
                    WebCard(
                      borderColor: WebAppColors.red.withValues(alpha: 0.3),
                      backgroundColor: WebAppColors.red.withValues(alpha: 0.1),
                      child: Text(
                        'Emergency break cooldown: ${cooldownUntil.difference(DateTime.now()).inMinutes + 1}m remaining',
                        style: const TextStyle(color: WebAppColors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (!isWaiting && !isAlarm)
                    Row(
                      children: [
                        if (lockLevel != SessionLockLevel.hard) ...[
                          Expanded(
                            child: WebSecondaryButton(
                              label: 'Emergency',
                              icon: Icons.coffee,
                              onPressed: () => _requestEmergencyBreak(context, ref),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: WebSecondaryButton(
                            label: 'Give up',
                            icon: Icons.close,
                            onPressed: () {
                              ref.read(sessionStateProvider.notifier).giveUpSession();
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestEmergencyBreak(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(sessionStateProvider.notifier).requestEmergencyBreak();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.allowed ? WebAppColors.green : WebAppColors.red,
      ),
    );
  }
}

class _FocusPanel extends StatelessWidget {
  final String taskName;
  final String remainingText;
  final double progress;

  const _FocusPanel({
    required this.taskName,
    required this.remainingText,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOCUSED', style: WebAppText.eyebrow),
          const SizedBox(height: 12),
          Text(
            taskName.trim().isEmpty ? 'Untitled focus block' : taskName,
            style: WebAppText.sectionTitle,
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              remainingText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 66,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: WebAppColors.border,
              valueColor: const AlwaysStoppedAnimation(WebAppColors.green),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).round()}% complete',
            style: const TextStyle(color: WebAppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  final SessionLockLevel lockLevel;

  const _WaitingPanel({required this.lockLevel});

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: const EdgeInsets.all(24),
      borderColor: WebAppColors.blue.withValues(alpha: 0.3),
      backgroundColor: WebAppColors.blue.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLACE DEVICE', style: WebAppText.eyebrow),
          const SizedBox(height: 12),
          Text('Face down to begin', style: WebAppText.title),
          const SizedBox(height: 12),
          Text(
            '${lockLevel.label} lock is armed. Put the phone face down on a flat surface to start the timer.',
            style: WebAppText.body,
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              WebChip(label: 'Flip', icon: Icons.flip),
              SizedBox(width: 8),
              WebChip(label: 'Place', icon: Icons.table_bar),
              SizedBox(width: 8),
              WebChip(label: 'Focus', icon: Icons.psychology),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlarmPanel extends StatelessWidget {
  final SessionLockLevel lockLevel;

  const _AlarmPanel({required this.lockLevel});

  @override
  Widget build(BuildContext context) {
    return WebCard(
      padding: const EdgeInsets.all(24),
      borderColor: WebAppColors.red.withValues(alpha: 0.45),
      backgroundColor: WebAppColors.red.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEVICE LIFTED',
            style: TextStyle(
              color: WebAppColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text('Put it down', style: WebAppText.title),
          const SizedBox(height: 12),
          Text(
            'You have ${lockLevel.graceSeconds} seconds of grace in ${lockLevel.label.toLowerCase()} mode before this session fails.',
            style: WebAppText.body,
          ),
        ],
      ),
    );
  }
}
