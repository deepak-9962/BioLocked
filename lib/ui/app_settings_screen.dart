import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/app_settings_service.dart';
import '../features/session/session_provider.dart';
import 'theme/luxury_theme.dart';
import 'widgets/shared_bottom_nav_bar.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: LuxuryColors.richBlack,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LuxuryGradients.darkBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref),
              Expanded(
                child: settingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: LuxuryColors.platinumBlue,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Error loading settings: $err',
                        style: const TextStyle(color: LuxuryColors.rubyRed)),
                  ),
                  data: (settings) => ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    children: [
                      _buildSessionDefaultsSection(ref, settings),
                      const SizedBox(height: 16),
                      _buildLockBehaviorSection(ref, settings),
                      const SizedBox(height: 16),
                      _buildEconomySection(ref, settings),
                      const SizedBox(height: 16),
                      _buildAppPersonaSection(ref, settings),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                ref.read(sessionStateProvider.notifier).setCheckIn();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LuxuryColors.cardBackground,
                border: Border.all(color: LuxuryColors.subtleBorder),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: LuxuryColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'APP SETTINGS',
            style: LuxuryTextStyles.headlineLarge.copyWith(letterSpacing: 3),
          ),
        ],
      ),
    );
  }


  // ─── Session Defaults ──────────────────────────────────────────────────────
  Widget _buildSessionDefaultsSection(WidgetRef ref, AppSettings settings) {
    return _SettingsSection(
      title: 'SESSION DEFAULTS',
      icon: Icons.tune,
      iconColor: LuxuryColors.emerald,
      children: [
        _SettingsSlider(
          title: 'Default Duration (mins)',
          value: settings.defaultDurationMinutes.toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(defaultDurationMinutes: val.toInt())),
        ),
        _SettingsDropdown<String>(
          title: 'Default Lock Level',
          value: settings.defaultLockLevel,
          items: const [
            DropdownMenuItem(value: 'soft', child: Text('Soft')),
            DropdownMenuItem(value: 'standard', child: Text('Standard')),
            DropdownMenuItem(value: 'hard', child: Text('Hard')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref
                  .read(appSettingsProvider.notifier)
                  .updateSettings((s) => s.copyWith(defaultLockLevel: val));
            }
          },
        ),
        _SettingsSwitch(
          title: 'Default Destruction Mode',
          subtitle: 'Resets progress on failure',
          value: settings.defaultDestructionMode,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(defaultDestructionMode: val)),
        ),
      ],
    );
  }

  // ─── Lock Behavior ─────────────────────────────────────────────────────────
  Widget _buildLockBehaviorSection(WidgetRef ref, AppSettings settings) {
    return _SettingsSection(
      title: 'LOCK BEHAVIOR',
      icon: Icons.lock_outline,
      iconColor: LuxuryColors.rubyRed,
      children: [
        _SettingsSlider(
          title: 'Soft Grace Period (s)',
          value: settings.softGraceSeconds.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(softGraceSeconds: val.toInt())),
        ),
        _SettingsSlider(
          title: 'Standard Grace Period (s)',
          value: settings.standardGraceSeconds.toDouble(),
          min: 5,
          max: 30,
          divisions: 5,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(standardGraceSeconds: val.toInt())),
        ),
        _SettingsSlider(
          title: 'Hard Grace Period (s)',
          value: settings.hardGraceSeconds.toDouble(),
          min: 1,
          max: 15,
          divisions: 14,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(hardGraceSeconds: val.toInt())),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(color: LuxuryColors.subtleBorder),
        ),
        _SettingsSwitch(
          title: 'Enable Grayscale',
          subtitle: 'During active sessions',
          value: settings.grayscaleOnSession,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(grayscaleOnSession: val)),
        ),
        _SettingsSwitch(
          title: 'Enable DND',
          subtitle: 'Do Not Disturb during sessions',
          value: settings.dndOnSession,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(dndOnSession: val)),
        ),
      ],
    );
  }

  // ─── Economy ───────────────────────────────────────────────────────────────
  Widget _buildEconomySection(WidgetRef ref, AppSettings settings) {
    return _SettingsSection(
      title: 'ECONOMY',
      icon: Icons.monetization_on_outlined,
      iconColor: LuxuryColors.burnishedGold,
      children: [
        _SettingsSwitch(
          title: 'Enable Coins Economy',
          value: settings.coinsEnabled,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(coinsEnabled: val)),
        ),
        if (settings.coinsEnabled) ...[
          _SettingsSlider(
            title: 'Coins per Minute',
            value: settings.coinsPerMinute.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (val) => ref
                .read(appSettingsProvider.notifier)
                .updateSettings((s) => s.copyWith(coinsPerMinute: val.toInt())),
          ),
          _SettingsSlider(
            title: 'Perfect Session Bonus',
            value: settings.perfectSessionBonus.toDouble(),
            min: 0,
            max: 50,
            divisions: 10,
            onChanged: (val) => ref
                .read(appSettingsProvider.notifier)
                .updateSettings((s) => s.copyWith(perfectSessionBonus: val.toInt())),
          ),
        ],
      ],
    );
  }

  // ─── App Persona ───────────────────────────────────────────────────────────
  Widget _buildAppPersonaSection(WidgetRef ref, AppSettings settings) {
    return _SettingsSection(
      title: 'APP PERSONA',
      icon: Icons.face,
      iconColor: LuxuryColors.amethystLight,
      children: [
        _SettingsTextField(
          title: 'App Name',
          hint: 'BIO-LOCKED',
          value: settings.appName,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(appName: val)),
        ),
        _SettingsSwitch(
          title: 'Sound Effects',
          value: settings.soundEnabled,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(soundEnabled: val)),
        ),
        _SettingsSwitch(
          title: 'Haptic Feedback',
          value: settings.hapticEnabled,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(hapticEnabled: val)),
        ),
      ],
    );
  }
}

// ─── Reusable UI Components ────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuxuryColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxuryColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: LuxuryTextStyles.labelLarge.copyWith(color: iconColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: LuxuryColors.subtleBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LuxuryTextStyles.titleLarge.copyWith(fontSize: 16)),
                if (subtitle != null)
                  Text(subtitle!, style: LuxuryTextStyles.bodyMedium),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LuxuryColors.burnishedGold,
          ),
        ],
      ),
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SettingsSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: LuxuryTextStyles.titleLarge.copyWith(fontSize: 16)),
              Text(value.toInt().toString(), style: LuxuryTextStyles.bodyMedium),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: LuxuryColors.platinumBlue,
          ),
        ],
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  final String title;
  final String hint;
  final String value;
  final bool isPassword;
  final ValueChanged<String> onChanged;

  const _SettingsTextField({
    required this.title,
    required this.hint,
    required this.value,
    this.isPassword = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LuxuryTextStyles.titleLarge.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length)),
            obscureText: isPassword,
            style: const TextStyle(color: LuxuryColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: LuxuryColors.textTertiary),
              filled: true,
              fillColor: LuxuryColors.richBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: LuxuryColors.subtleBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: LuxuryColors.subtleBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: LuxuryColors.platinumBlue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsDropdown<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SettingsDropdown({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: LuxuryTextStyles.titleLarge.copyWith(fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: LuxuryColors.richBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LuxuryColors.subtleBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                dropdownColor: LuxuryColors.cardBackground,
                style: const TextStyle(color: LuxuryColors.textPrimary),
                icon: const Icon(Icons.arrow_drop_down, color: LuxuryColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
