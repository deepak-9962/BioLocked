import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dnd/dnd_service.dart';
import '../features/overlay/overlay_service.dart';
import '../features/presets/preset_service.dart';
import '../features/session/session_provider.dart';
import 'commitment_contract_dialog.dart';
import 'theme/web_app_theme.dart';

class TunnelSetupScreen extends ConsumerStatefulWidget {
  const TunnelSetupScreen({super.key});

  @override
  ConsumerState<TunnelSetupScreen> createState() => _TunnelSetupScreenState();
}

class _TunnelSetupScreenState extends ConsumerState<TunnelSetupScreen> {
  final _taskController = TextEditingController();
  final _customMinutesController = TextEditingController();
  bool _customDuration = false;

  @override
  void dispose() {
    _taskController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = ref.watch(taskDurationProvider);
    final lockLevel = ref.watch(lockLevelProvider);
    final destructionMode = ref.watch(destructionModeProvider);
    final presetsAsync = ref.watch(presetsProvider);
    final cooldownUntil = ref.watch(emergencyBreakCooldownUntilProvider);
    final isCooldownActive =
        cooldownUntil != null && cooldownUntil.isAfter(DateTime.now());

    return WebAppScaffold(
      child: Column(
        children: [
          WebTopBar(
            title: 'THE TUNNEL',
            onBack: () => ref.read(sessionStateProvider.notifier).setCheckIn(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                const Text('CONFIGURE SESSION', style: WebAppText.eyebrow),
                const SizedBox(height: 14),
                const Text('One task. Full focus.', style: WebAppText.title),
                const SizedBox(height: 12),
                const Text(
                  'Choose what you are locking for, how long, and how strict the Android enforcement should be.',
                  style: WebAppText.body,
                ),
                const SizedBox(height: 24),
                presetsAsync.when(
                  data: _buildPresets,
                  loading: () => const SizedBox(
                    height: 72,
                    child: Center(child: CircularProgressIndicator(color: WebAppColors.blue)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 18),
                WebCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mission', style: WebAppText.sectionTitle),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _taskController,
                        style: const TextStyle(color: WebAppColors.text),
                        decoration: _inputDecoration('Enter one focused task'),
                        onChanged: (value) {
                          ref.read(taskNameProvider.notifier).set(value);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                WebCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duration', style: WebAppText.sectionTitle),
                          Text(
                            '$duration min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_customDuration)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customMinutesController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                style: const TextStyle(color: WebAppColors.text),
                                decoration: _inputDecoration('Minutes'),
                                onChanged: (value) {
                                  final minutes = int.tryParse(value) ?? 0;
                                  if (minutes > 0 && minutes <= 480) {
                                    ref.read(taskDurationProvider.notifier).set(minutes);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            WebChip(
                              label: 'Presets',
                              icon: Icons.grid_view,
                              onTap: () => setState(() => _customDuration = false),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final minutes in const [15, 25, 45, 60, 90])
                              WebChip(
                                label: '${minutes}m',
                                selected: duration == minutes,
                                onTap: () => ref.read(taskDurationProvider.notifier).set(minutes),
                              ),
                            WebChip(
                              label: 'Custom',
                              icon: Icons.edit,
                              color: WebAppColors.blue,
                              onTap: () {
                                _customMinutesController.text = duration.toString();
                                setState(() => _customDuration = true);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                WebCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lock level', style: WebAppText.sectionTitle),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final level in SessionLockLevel.values)
                            WebChip(
                              label: level.label,
                              icon: Icons.lock_outline,
                              color: _lockColor(level),
                              selected: lockLevel == level,
                              onTap: () => ref.read(lockLevelProvider.notifier).set(level),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(_lockDescription(lockLevel), style: WebAppText.body),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        value: destructionMode,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: WebAppColors.red,
                        title: const Text('Destruction mode', style: TextStyle(color: Colors.white)),
                        subtitle: const Text(
                          'Any failure ends the session immediately.',
                          style: TextStyle(color: WebAppColors.textMuted),
                        ),
                        onChanged: (value) {
                          ref.read(destructionModeProvider.notifier).set(value);
                        },
                      ),
                    ],
                  ),
                ),
                if (isCooldownActive) ...[
                  const SizedBox(height: 14),
                  WebCard(
                    backgroundColor: WebAppColors.red.withValues(alpha: 0.1),
                    borderColor: WebAppColors.red.withValues(alpha: 0.3),
                    child: const Text(
                      'Emergency break cooldown is active. Starting is blocked until it expires.',
                      style: TextStyle(color: WebAppColors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                WebPrimaryButton(
                  label: 'Start locked session',
                  icon: Icons.bolt,
                  onPressed: _taskController.text.trim().isEmpty || isCooldownActive
                      ? null
                      : _startSession,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(List<SessionPreset> presets) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final preset = presets[index];
          return GestureDetector(
            onTap: () => _applyPreset(preset),
            child: SizedBox(
              width: 148,
              child: WebCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preset.icon, style: const TextStyle(fontSize: 22)),
                    const Spacer(),
                    Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${preset.durationMinutes}m · ${preset.lockLevel}',
                      style: const TextStyle(color: WebAppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: WebAppColors.textFaint),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: WebAppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: WebAppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: WebAppColors.blue),
      ),
    );
  }

  void _applyPreset(SessionPreset preset) {
    final level = SessionLockLevel.values.firstWhere(
      (item) => item.keyName == preset.lockLevel,
      orElse: () => SessionLockLevel.standard,
    );

    _taskController.text = preset.taskName;
    ref.read(taskNameProvider.notifier).set(preset.taskName);
    ref.read(taskDurationProvider.notifier).set(preset.durationMinutes);
    ref.read(destructionModeProvider.notifier).set(preset.destructionMode);
    ref.read(lockLevelProvider.notifier).set(level);
    setState(() {});
  }

  Future<void> _startSession() async {
    final lockLevel = ref.read(lockLevelProvider);

    if (lockLevel == SessionLockLevel.hard) {
      final committed = await showCommitmentContract(
        context,
        taskName: _taskController.text.trim(),
        durationMinutes: ref.read(taskDurationProvider),
      );
      if (!committed) return;
    }

    final dndService = ref.read(dndServiceProvider);
    if (!await dndService.isPermissionGranted()) {
      await dndService.requestPermission();
    }

    if (lockLevel == SessionLockLevel.hard ||
        lockLevel == SessionLockLevel.standard) {
      final overlayService = ref.read(overlayServiceProvider);
      if (!await overlayService.checkPermission()) {
        await overlayService.requestPermission();
      }
    }

    if (!mounted) return;
    ref.read(sessionStateProvider.notifier).setWaitingForFaceDown();
  }

  Color _lockColor(SessionLockLevel level) {
    switch (level) {
      case SessionLockLevel.soft:
        return WebAppColors.blue;
      case SessionLockLevel.standard:
        return WebAppColors.gold;
      case SessionLockLevel.hard:
        return WebAppColors.red;
    }
  }

  String _lockDescription(SessionLockLevel level) {
    switch (level) {
      case SessionLockLevel.soft:
        return 'Flexible mode. Longer grace period and up to two emergency breaks.';
      case SessionLockLevel.standard:
        return 'Balanced mode. Overlay and kiosk enforcement with one emergency break.';
      case SessionLockLevel.hard:
        return 'Strict mode. Short grace period, no emergency breaks, commitment required.';
    }
  }
}
