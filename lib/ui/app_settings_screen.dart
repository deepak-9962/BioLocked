import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/settings/app_settings_service.dart';
import '../features/session/session_provider.dart';
import 'theme/bio_theme.dart';
import 'widgets/shared_bottom_nav_bar.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: BioColors.background,
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 3),
      body: SafeArea(
        child: Column(
          children: [
            // ── TopAppBar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BioSpacing.marginMain,
                vertical: 16,
              ),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BioColors.surfaceContainerHigh,
                        border: Border.all(color: BioColors.outlineVariant),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: BioColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'APP SETTINGS',
                        style: BioTextStyles.headlineLg.copyWith(
                          letterSpacing: 6.4,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Spacer for centering
                ],
              ),
            ),
            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: settingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BioColors.primaryFixed),
                ),
                error: (err, _) => Center(
                  child: Text('Error: $err', style: const TextStyle(color: BioColors.error)),
                ),
                data: (settings) => ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BioSpacing.marginMain,
                    vertical: 16,
                  ),
                  children: [
                    _buildSessionDefaultsSection(ref, settings),
                    const SizedBox(height: BioSpacing.stackGap),
                    _buildLockBehaviorSection(ref, settings),
                    const SizedBox(height: BioSpacing.stackGap),
                    _buildEconomySection(ref, settings),
                    const SizedBox(height: BioSpacing.stackGap),
                    _buildAppPersonaSection(ref, settings),
                    const SizedBox(height: BioSpacing.stackGap),
                    _buildAccountSection(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Session Defaults ──────────────────────────────────────────────────────

  Widget _buildSessionDefaultsSection(WidgetRef ref, AppSettings settings) {
    return _SettingsSection(
      title: 'SESSION DEFAULTS',
      icon: Icons.tune,
      iconColor: BioColors.primaryFixed,
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
        const _SettingsDivider(),
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
        const _SettingsDivider(),
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
      iconColor: BioColors.error,
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
        const _SettingsDivider(),
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
        const _SettingsDivider(),
        // Hard Grace Period - display only (as in the HTML)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Opacity(
            opacity: 0.5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hard Grace Period (s)',
                  style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurface),
                ),
                Text(
                  '${settings.hardGraceSeconds}',
                  style: BioTextStyles.statDisplay.copyWith(
                    fontSize: 24,
                    color: BioColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Economy ───────────────────────────────────────────────────────────────

  Widget _buildEconomySection(WidgetRef ref, AppSettings settings) {
    return _SettingsSection(
      title: 'ECONOMY',
      icon: Icons.monetization_on_outlined,
      iconColor: BioColors.primaryFixed,
      children: [
        _SettingsSwitch(
          title: 'Enable Coins Economy',
          value: settings.coinsEnabled,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(coinsEnabled: val)),
        ),
        if (settings.coinsEnabled) ...[
          const _SettingsDivider(),
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
          const _SettingsDivider(),
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
      iconColor: BioColors.primaryFixed,
      children: [
        _SettingsTextField(
          title: 'App Name',
          hint: 'BIO-LOCKED',
          value: settings.appName,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(appName: val)),
        ),
        const _SettingsDivider(),
        _SettingsSwitch(
          title: 'Sound Effects',
          value: settings.soundEnabled,
          onChanged: (val) => ref
              .read(appSettingsProvider.notifier)
              .updateSettings((s) => s.copyWith(soundEnabled: val)),
        ),
        const _SettingsDivider(),
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

  Widget _buildAccountSection(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Signed in';

    return _SettingsSection(
      title: 'ACCOUNT',
      icon: Icons.person_outline,
      iconColor: BioColors.blue400,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                email,
                style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
              },
              child: Text(
                'Sign out',
                style: BioTextStyles.bodyMd.copyWith(color: BioColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Reusable UI Components ────────────────────────────────────────────────

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: BioColors.cardBorder, height: 24);
  }
}

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
        color: BioColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BioColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(BioSpacing.gutterCard),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: BioColors.cardBorder)),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: BioTextStyles.labelCaps.copyWith(
                    color: iconColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(BioSpacing.gutterCard),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurface),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: BioTextStyles.bodyMd.copyWith(
                      fontSize: 14,
                      color: BioColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 56,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurface),
            ),
            Text(
              value.toInt().toString(),
              style: BioTextStyles.statDisplay.copyWith(
                fontSize: 24,
                color: BioColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            activeTrackColor: BioColors.primaryFixed,
            inactiveTrackColor: BioColors.cardBorder,
            thumbColor: BioColors.primaryFixed,
            overlayColor: BioColors.primaryFixed.withValues(alpha: 0.12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  final String title;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _SettingsTextField({
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurface),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length)),
            style: const TextStyle(color: BioColors.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: BioColors.onSurfaceVariant.withValues(alpha: 0.5)),
              filled: true,
              fillColor: BioColors.innerBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: BioColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: BioColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: BioColors.primaryFixed),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurface),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: BioColors.innerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BioColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                dropdownColor: BioColors.innerBg,
                style: BioTextStyles.bodyMd.copyWith(color: BioColors.onSurface),
                icon: const Icon(Icons.arrow_drop_down, color: BioColors.onSurfaceVariant, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
