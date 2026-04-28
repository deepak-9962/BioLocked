import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../features/session/session_provider.dart';
import '../features/presets/preset_service.dart';
import '../features/dnd/dnd_service.dart';
import '../features/overlay/overlay_service.dart';
import 'commitment_contract_dialog.dart';
import 'theme/luxury_theme.dart';

class TunnelSetupScreen extends ConsumerStatefulWidget {
  const TunnelSetupScreen({super.key});

  @override
  ConsumerState<TunnelSetupScreen> createState() => _TunnelSetupScreenState();
}

class _TunnelSetupScreenState extends ConsumerState<TunnelSetupScreen>
    with SingleTickerProviderStateMixin {
  final _taskController = TextEditingController();
  final _customMinutesController = TextEditingController();
  bool _isCustomMode = false;
  bool _showPresets = true;
  late AnimationController _glowController;

  final List<int> _quickDurations = [15, 25, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _customMinutesController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = ref.watch(taskDurationProvider);
    final destructionMode = ref.watch(destructionModeProvider);
    final lockLevel = ref.watch(lockLevelProvider);
    final cooldownUntil = ref.watch(emergencyBreakCooldownUntilProvider);
    final now = DateTime.now();
    final isCooldownActive = cooldownUntil != null && cooldownUntil.isAfter(now);
    final cooldownMinutes = isCooldownActive
        ? cooldownUntil.difference(now).inMinutes + 1
        : 0;

    return Scaffold(
      backgroundColor: LuxuryColors.richBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LuxuryGradients.darkBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                
                // Header
                Row(
                  children: [
                    // Back button
                    GestureDetector(
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
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LuxuryColors.platinumBlue.withValues(alpha: 0.1),
                        border: Border.all(
                          color: LuxuryColors.platinumBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.track_changes,
                        color: LuxuryColors.platinumBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THE TUNNEL',
                            style: LuxuryTextStyles.headlineLarge.copyWith(
                              letterSpacing: 4,
                            ),
                          ),
                          Text(
                            'Configure your deep work session',
                            style: LuxuryTextStyles.bodyMedium.copyWith(
                              color: LuxuryColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Quick Start Presets
                _buildPresetsSection(),
                
                const SizedBox(height: 24),
                
                // Task Input Card
                _buildFrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.task_alt,
                            color: LuxuryColors.platinumBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'YOUR MISSION',
                            style: LuxuryTextStyles.labelLarge.copyWith(
                              color: LuxuryColors.platinumBlue,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: LuxuryColors.richBlack.withValues(alpha: 0.5),
                          border: Border.all(
                            color: LuxuryColors.platinumBlue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _taskController,
                          style: LuxuryTextStyles.titleLarge.copyWith(
                            color: LuxuryColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Enter one focused task',
                            hintStyle: LuxuryTextStyles.bodyLarge.copyWith(
                              color: LuxuryColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                          onChanged: (value) {
                            ref.read(taskNameProvider.notifier).set(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Duration Card
                _buildFrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: LuxuryColors.burnishedGold,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'DURATION',
                            style: LuxuryTextStyles.labelLarge.copyWith(
                              color: LuxuryColors.burnishedGold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      if (_isCustomMode) ...[
                        // Custom input
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: LuxuryColors.richBlack.withValues(alpha: 0.5),
                                  border: Border.all(
                                    color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: TextField(
                                  controller: _customMinutesController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: LuxuryTextStyles.displayLarge.copyWith(
                                    color: LuxuryColors.burnishedGold,
                                    fontSize: 40,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: LuxuryTextStyles.displayLarge.copyWith(
                                      color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
                                      fontSize: 40,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (value) {
                                    final minutes = int.tryParse(value) ?? 0;
                                    if (minutes > 0 && minutes <= 480) {
                                      ref.read(taskDurationProvider.notifier).set(minutes);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'min',
                                style: LuxuryTextStyles.titleLarge.copyWith(
                                  color: LuxuryColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCustomMode = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: LuxuryColors.textSecondary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Use Presets',
                                style: LuxuryTextStyles.bodyMedium.copyWith(
                                  color: LuxuryColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Quick pick buttons
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: _quickDurations.map((mins) {
                            final isSelected = duration == mins;
                            return GestureDetector(
                              onTap: () {
                                ref.read(taskDurationProvider.notifier).set(mins);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isSelected
                                      ? LuxuryGradients.goldShimmer
                                      : null,
                                  color: isSelected
                                      ? null
                                      : LuxuryColors.cardBackground,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : LuxuryColors.burnishedGold.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: LuxuryColors.burnishedGold.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            spreadRadius: -2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  '$mins',
                                  style: LuxuryTextStyles.titleLarge.copyWith(
                                    color: isSelected
                                        ? LuxuryColors.richBlack
                                        : LuxuryColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Custom button
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCustomMode = true;
                                _customMinutesController.text = duration.toString();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: LuxuryColors.burnishedGold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: LuxuryColors.burnishedGold,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CUSTOM',
                                    style: LuxuryTextStyles.labelLarge.copyWith(
                                      color: LuxuryColors.burnishedGold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Lock level card
                _buildFrostedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: LuxuryColors.emerald,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'LOCK LEVEL',
                            style: LuxuryTextStyles.labelLarge.copyWith(
                              color: LuxuryColors.emerald,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: SessionLockLevel.values
                            .map((level) => _buildLockLevelChip(level, lockLevel))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        lockLevel == SessionLockLevel.soft
                            ? 'Soft: 15s grace, 2 emergency breaks/day'
                            : lockLevel == SessionLockLevel.standard
                                ? 'Standard: 10s grace, 1 emergency break/day'
                                : 'Hard: 5s grace, no emergency break',
                        style: LuxuryTextStyles.bodyMedium.copyWith(
                          color: LuxuryColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Destruction Mode Card
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: destructionMode
                            ? [
                                BoxShadow(
                                  color: LuxuryColors.rubyRed.withValues(
                                    alpha: 0.2 + 0.15 * _glowController.value,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: -5,
                                ),
                              ]
                            : null,
                      ),
                      child: _buildFrostedCard(
                        borderColor: destructionMode
                            ? LuxuryColors.rubyRed.withValues(alpha: 0.5)
                            : null,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: destructionMode
                                        ? LuxuryColors.rubyRed.withValues(alpha: 0.2)
                                        : LuxuryColors.textSecondary.withValues(alpha: 0.1),
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: destructionMode
                                        ? LuxuryColors.rubyRed
                                        : LuxuryColors.textSecondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DESTRUCTION MODE',
                                        style: LuxuryTextStyles.labelLarge.copyWith(
                                          color: destructionMode
                                              ? LuxuryColors.rubyRed
                                              : LuxuryColors.textSecondary,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fail and your progress resets completely',
                                        style: LuxuryTextStyles.bodyMedium.copyWith(
                                          color: LuxuryColors.textSecondary.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: destructionMode,
                                  activeTrackColor: LuxuryColors.rubyRed,
                                  activeThumbColor: Colors.white,
                                  inactiveTrackColor: LuxuryColors.cardBackground,
                                  inactiveThumbColor: LuxuryColors.textSecondary,
                                  onChanged: (value) {
                                    ref.read(destructionModeProvider.notifier).set(value);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),

                if (isCooldownActive)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: LuxuryColors.rubyRed.withValues(alpha: 0.12),
                      border: Border.all(
                        color: LuxuryColors.rubyRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_bottom,
                          color: LuxuryColors.rubyRed,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Emergency break cooldown active: $cooldownMinutes min remaining',
                            style: LuxuryTextStyles.bodyMedium.copyWith(
                              color: LuxuryColors.rubyRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Enter Tunnel Button
                GestureDetector(
                  onTap: () async {
                    if (_taskController.text.isEmpty) return;

                    final lockLevel = ref.read(lockLevelProvider);

                    // 🔑 Commitment Contract for Hard Lock
                    if (lockLevel == SessionLockLevel.hard) {
                      final committed = await showCommitmentContract(
                        context,
                        taskName: _taskController.text,
                        durationMinutes: ref.read(taskDurationProvider),
                      );
                      if (!committed) return;
                    }

                    // 🔕 Request DND permission if not granted (first time)
                    final dndService = ref.read(dndServiceProvider);
                    final hasPermission = await dndService.isPermissionGranted();
                    if (!hasPermission) {
                      await dndService.requestPermission();
                    }

                    // 🛑 Request Overlay permission for Hard/Standard Lock
                    if (lockLevel == SessionLockLevel.hard || lockLevel == SessionLockLevel.standard) {
                      final overlayService = ref.read(overlayServiceProvider);
                      if (!await overlayService.checkPermission()) {
                        await overlayService.requestPermission();
                      }
                    }

                    if (!context.mounted) return;
                    ref.read(sessionStateProvider.notifier).setWaitingForFaceDown();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: _taskController.text.isNotEmpty
                          ? LuxuryGradients.platinumGold
                          : LinearGradient(
                              colors: [
                                LuxuryColors.textSecondary.withValues(alpha: 0.3),
                                LuxuryColors.textSecondary.withValues(alpha: 0.2),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _taskController.text.isNotEmpty
                          ? [
                              BoxShadow(
                                color: LuxuryColors.burnishedGold.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: _taskController.text.isNotEmpty
                              ? LuxuryColors.richBlack
                              : LuxuryColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ENTER TUNNEL',
                          style: LuxuryTextStyles.labelLarge.copyWith(
                            color: _taskController.text.isNotEmpty
                                ? LuxuryColors.richBlack
                                : LuxuryColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedCard({required Widget child, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LuxuryGradients.frostedGlass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? LuxuryColors.platinumBlue.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    final presetsAsync = ref.watch(presetsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with toggle
        GestureDetector(
          onTap: () => setState(() => _showPresets = !_showPresets),
          child: Row(
            children: [
              Icon(
                Icons.bolt,
                color: LuxuryColors.emerald,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'QUICK START',
                style: LuxuryTextStyles.labelLarge.copyWith(
                  color: LuxuryColors.emerald,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Icon(
                _showPresets ? Icons.expand_less : Icons.expand_more,
                color: LuxuryColors.textSecondary,
              ),
            ],
          ),
        ),

        if (_showPresets) ...[
          const SizedBox(height: 16),
          presetsAsync.when(
            data: (presets) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...presets.map((preset) => _buildPresetCard(preset)),
                  _buildSavePresetCard(),
                ],
              ),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: LuxuryColors.emerald),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetCard(SessionPreset preset) {
    return GestureDetector(
      onTap: () {
        final presetLevel = SessionLockLevel.values.firstWhere(
          (level) => level.keyName == preset.lockLevel,
          orElse: () => SessionLockLevel.standard,
        );

        // Apply preset
        _taskController.text = preset.taskName;
        ref.read(taskNameProvider.notifier).set(preset.taskName);
        ref.read(taskDurationProvider.notifier).set(preset.durationMinutes);
        ref.read(destructionModeProvider.notifier).set(preset.destructionMode);
        ref.read(lockLevelProvider.notifier).set(presetLevel);
        setState(() {});
      },
      onLongPress: () => _showPresetOptions(preset),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LuxuryColors.emerald.withValues(alpha: 0.15),
              LuxuryColors.emerald.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: LuxuryColors.emerald.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preset.icon,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              preset.name,
              style: LuxuryTextStyles.labelLarge.copyWith(
                color: LuxuryColors.textPrimary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${preset.durationMinutes} min',
              style: TextStyle(
                color: LuxuryColors.emerald,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
              const SizedBox(height: 4),
              Text(
                preset.lockLevel.toUpperCase(),
                style: LuxuryTextStyles.bodyMedium.copyWith(
                  color: LuxuryColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavePresetCard() {
    return GestureDetector(
      onTap: () => _showSavePresetDialog(),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: LuxuryColors.platinumBlue.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LuxuryColors.platinumBlue.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.add,
                color: LuxuryColors.platinumBlue,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save\nPreset',
              style: TextStyle(
                color: LuxuryColors.platinumBlue,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetOptions(SessionPreset preset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: LuxuryColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preset.name,
              style: LuxuryTextStyles.titleLarge,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.delete, color: LuxuryColors.rubyRed),
              title: const Text('Delete Preset'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(presetServiceProvider).deletePreset(preset.id);
                ref.invalidate(presetsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSavePresetDialog() {
    final nameController = TextEditingController();
    String selectedIcon = '⚡';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: LuxuryColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'SAVE PRESET',
            style: LuxuryTextStyles.titleLarge.copyWith(
              letterSpacing: 2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Preset name',
                  hintStyle: TextStyle(color: LuxuryColors.textTertiary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: LuxuryColors.subtleBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: LuxuryColors.subtleBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: LuxuryColors.emerald),
                  ),
                ),
                style: const TextStyle(color: LuxuryColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Icon',
                style: LuxuryTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presetIcons.map((icon) {
                  final isSelected = icon == selectedIcon;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSelected
                          ? LuxuryColors.emerald.withValues(alpha: 0.3)
                            : LuxuryColors.elevatedSurface,
                        border: Border.all(
                          color: isSelected
                              ? LuxuryColors.emerald
                              : LuxuryColors.subtleBorder,
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: LuxuryColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LuxuryColors.emerald,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final presetName = nameController.text.trim();
                if (presetName.isEmpty) {
                  // Show error — preset name is required
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a preset name.'),
                      backgroundColor: LuxuryColors.rubyRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }
                // Use the task field text if filled, otherwise default to preset name
                final taskName = _taskController.text.trim().isNotEmpty
                    ? _taskController.text.trim()
                    : presetName;
                final preset = ref.read(presetServiceProvider).createPreset(
                  name: presetName,
                  taskName: taskName,
                  durationMinutes: ref.read(taskDurationProvider),
                  destructionMode: ref.read(destructionModeProvider),
                  lockLevel: ref.read(lockLevelProvider).keyName,
                  icon: selectedIcon,
                );
                await ref.read(presetServiceProvider).savePreset(preset);
                ref.invalidate(presetsProvider);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preset "$presetName" saved!'),
                    backgroundColor: LuxuryColors.emerald,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLockLevelChip(
    SessionLockLevel level,
    SessionLockLevel selected,
  ) {
    final isSelected = level == selected;

    return GestureDetector(
      onTap: () {
        ref.read(lockLevelProvider.notifier).set(level);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected ? LuxuryGradients.emeraldGlow : null,
          color: isSelected ? null : LuxuryColors.cardBackground,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : LuxuryColors.emerald.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          level.label.toUpperCase(),
          style: LuxuryTextStyles.labelLarge.copyWith(
            color: isSelected ? Colors.white : LuxuryColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
