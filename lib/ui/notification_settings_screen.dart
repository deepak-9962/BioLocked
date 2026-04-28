import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/notifications/notification_service.dart';
import '../features/session/session_provider.dart';
import 'widgets/shared_bottom_nav_bar.dart';
import 'theme/luxury_theme.dart';

/// Settings screen for notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  List<FocusSchedule> _focusSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.getSettings();
    final schedules = await NotificationService.getFocusSchedules();
    setState(() {
      _settings = settings;
      _focusSchedules = schedules;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings != null) {
      await NotificationService.saveSettings(_settings!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxuryColors.richBlack,
      bottomNavigationBar: const SharedBottomNavBar(currentIndex: 3),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LuxuryGradients.darkBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
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
                    Text(
                      'ACCOUNT / SETTINGS',
                      style: LuxuryTextStyles.headlineLarge.copyWith(
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: LuxuryColors.platinumBlue,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Master toggle
                      _buildSettingCard(
                        icon: Icons.notifications_active,
                        iconColor: LuxuryColors.burnishedGold,
                        title: 'Enable Notifications',
                        subtitle: 'Receive reminders and motivation',
                        trailing: Switch(
                          value: _settings!.enabled,
                          activeThumbColor: LuxuryColors.burnishedGold,
                          onChanged: (value) {
                            setState(() {
                              _settings = NotificationSettings(
                                enabled: value,
                                streakReminders: _settings!.streakReminders,
                                dailyMotivation: _settings!.dailyMotivation,
                                reminderHour: _settings!.reminderHour,
                                reminderMinute: _settings!.reminderMinute,                                  cooldownMinutes: _settings!.cooldownMinutes,                              );
                            });
                            _saveSettings();
                          },
                        ),
                      ),

                      if (_settings!.enabled) ...[
                        const SizedBox(height: 16),

                        // Streak reminders
                        _buildSettingCard(
                          icon: Icons.local_fire_department,
                          iconColor: LuxuryColors.deepRose,
                          title: 'Streak Reminders',
                          subtitle: 'Get reminded to maintain your streak',
                          trailing: Switch(
                            value: _settings!.streakReminders,
                            activeThumbColor: LuxuryColors.deepRose,
                            onChanged: (value) {
                              setState(() {
                                _settings = NotificationSettings(
                                  enabled: _settings!.enabled,
                                  streakReminders: value,
                                  dailyMotivation: _settings!.dailyMotivation,
                                  reminderHour: _settings!.reminderHour,
                                  reminderMinute: _settings!.reminderMinute,                                    cooldownMinutes: _settings!.cooldownMinutes,                                );
                              });
                              _saveSettings();
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Reminder time
                        if (_settings!.streakReminders)
                          _buildSettingCard(
                            icon: Icons.access_time,
                            iconColor: LuxuryColors.platinumBlue,
                            title: 'Reminder Time',
                            subtitle: _formatTime(_settings!.reminderHour, _settings!.reminderMinute),
                            onTap: () => _showTimePicker(),
                          ),

                        if (_settings!.streakReminders)
                          const SizedBox(height: 16),

                        // Daily motivation
                        _buildSettingCard(
                          icon: Icons.wb_sunny,
                          iconColor: LuxuryColors.champagneGold,
                          title: 'Morning Motivation',
                          subtitle: 'Get inspired to start your day at 8 AM',
                          trailing: Switch(
                            value: _settings!.dailyMotivation,
                            activeThumbColor: LuxuryColors.champagneGold,
                            onChanged: (value) {
                              setState(() {
                                _settings = NotificationSettings(
                                  enabled: _settings!.enabled,
                                  streakReminders: _settings!.streakReminders,
                                  dailyMotivation: value,
                                  reminderHour: _settings!.reminderHour,
                                  reminderMinute: _settings!.reminderMinute,
                                  cooldownMinutes: _settings!.cooldownMinutes,
                                );
                              });
                              _saveSettings();
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: LuxuryColors.emerald,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'FOCUS SCHEDULES',
                              style: LuxuryTextStyles.labelLarge.copyWith(
                                color: LuxuryColors.emerald,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _showScheduleDialog,
                              icon: Icon(
                                Icons.add,
                                size: 16,
                                color: LuxuryColors.emerald,
                              ),
                              label: Text(
                                'Add',
                                style: LuxuryTextStyles.bodyMedium.copyWith(
                                  color: LuxuryColors.emerald,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_focusSchedules.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: LuxuryColors.cardBackground.withValues(alpha: 0.4),
                              border: Border.all(
                                color: LuxuryColors.subtleBorder,
                              ),
                            ),
                            child: Text(
                              'No recurring schedules yet. Add one to auto-remind your deep work blocks.',
                              style: LuxuryTextStyles.bodyMedium.copyWith(
                                color: LuxuryColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ..._focusSchedules
                              .map((schedule) => Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _buildFocusScheduleCard(schedule),
                                  )),
                      ],

                      const SizedBox(height: 24),

                      // Cooldown Duration
                      _buildSettingCard(
                        icon: Icons.timer,
                        iconColor: LuxuryColors.emerald,
                        title: 'Emergency Break Cooldown',
                        subtitle: '${_settings!.cooldownMinutes} minutes',
                        onTap: () => _showCooldownPicker(),
                      ),

                      const SizedBox(height: 32),

                      // Test notification button
                      GestureDetector(
                        onTap: () async {
                          if (kIsWeb) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Notifications are not supported on web. Run on Android/iOS to test.',
                                ),
                                backgroundColor: LuxuryColors.rubyRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          // Request permission first (required on Android 13+)
                          final granted = await NotificationService.requestPermission();
                          if (!granted) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Notification permission denied. Please enable it in device settings.',
                                ),
                                backgroundColor: LuxuryColors.rubyRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            await NotificationService.showInstantNotification(
                              title: '🔔 Test Notification',
                              body: 'Notifications are working! Keep focusing!',
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Test notification sent!'),
                                backgroundColor: LuxuryColors.emerald,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to send notification: $e'),
                                backgroundColor: LuxuryColors.rubyRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: LuxuryColors.platinumBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send,
                                color: LuxuryColors.platinumBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Send Test Notification',
                                style: LuxuryTextStyles.labelLarge.copyWith(
                                  color: LuxuryColors.platinumBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusScheduleCard(FocusSchedule schedule) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LuxuryColors.cardBackground.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: schedule.enabled
                  ? LuxuryColors.emerald.withValues(alpha: 0.3)
                  : LuxuryColors.subtleBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (schedule.enabled
                          ? LuxuryColors.emerald
                          : LuxuryColors.textSecondary)
                      .withValues(alpha: 0.16),
                ),
                child: Icon(
                  Icons.timelapse,
                  size: 18,
                  color: schedule.enabled
                      ? LuxuryColors.emerald
                      : LuxuryColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showScheduleDialog(existing: schedule),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.name,
                        style: LuxuryTextStyles.titleLarge.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(schedule.hour, schedule.minute)} • ${schedule.durationMinutes}m • ${_formatDays(schedule.days)}',
                        style: LuxuryTextStyles.bodyMedium.copyWith(
                          color: LuxuryColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Switch(
                value: schedule.enabled,
                activeThumbColor: LuxuryColors.emerald,
                onChanged: (value) async {
                  await NotificationService.saveFocusSchedule(
                    schedule.copyWith(enabled: value),
                  );
                  await _loadSettings();
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: LuxuryColors.textSecondary,
                  size: 18,
                ),
                color: LuxuryColors.cardBackground,
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showScheduleDialog(existing: schedule);
                  } else if (value == 'delete') {
                    await NotificationService.deleteFocusSchedule(schedule.id);
                    await _loadSettings();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showScheduleDialog({FocusSchedule? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final durationController = TextEditingController(
      text: (existing?.durationMinutes ?? 45).toString(),
    );
    TimeOfDay selectedTime = TimeOfDay(
      hour: existing?.hour ?? 9,
      minute: existing?.minute ?? 0,
    );
    final selectedDays = Set<int>.from(existing?.days ?? const [1, 2, 3, 4, 5]);
    bool enabled = existing?.enabled ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: LuxuryColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              existing == null ? 'ADD SCHEDULE' : 'EDIT SCHEDULE',
              style: LuxuryTextStyles.titleLarge.copyWith(letterSpacing: 2),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: LuxuryColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: LuxuryColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: LuxuryColors.subtleBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: LuxuryColors.emerald),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: LuxuryColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      labelStyle: TextStyle(color: LuxuryColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: LuxuryColors.subtleBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: LuxuryColors.emerald),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.access_time, color: LuxuryColors.platinumBlue),
                    title: Text(
                      _formatTime(selectedTime.hour, selectedTime.minute),
                      style: LuxuryTextStyles.bodyLarge,
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      child: const Text('Pick Time'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Repeat Days',
                      style: LuxuryTextStyles.bodyMedium.copyWith(
                        color: LuxuryColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      (1, 'Mon'),
                      (2, 'Tue'),
                      (3, 'Wed'),
                      (4, 'Thu'),
                      (5, 'Fri'),
                      (6, 'Sat'),
                      (7, 'Sun'),
                    ].map((entry) {
                      final day = entry.$1;
                      final label = entry.$2;
                      final isSelected = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (value) {
                          setDialogState(() {
                            if (value) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                        selectedColor: LuxuryColors.emerald.withValues(alpha: 0.25),
                        checkmarkColor: LuxuryColors.emerald,
                        side: BorderSide(color: LuxuryColors.subtleBorder),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: enabled,
                    onChanged: (value) => setDialogState(() => enabled = value),
                    activeThumbColor: LuxuryColors.emerald,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Enabled', style: LuxuryTextStyles.bodyLarge),
                  ),
                ],
              ),
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
                  final duration = int.tryParse(durationController.text) ?? 45;
                  if (selectedDays.isEmpty) return;

                  final schedule = FocusSchedule(
                    id: existing?.id ??
                        'schedule_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim().isEmpty
                        ? 'Focus Block'
                        : nameController.text.trim(),
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                    durationMinutes: duration.clamp(10, 240),
                    days: selectedDays.toList()..sort(),
                    enabled: enabled,
                  );

                  await NotificationService.saveFocusSchedule(schedule);
                  if (!mounted) return;
                  await _loadSettings();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDays(List<int> days) {
    final sorted = [...days]..sort();
    const weekdays = [1, 2, 3, 4, 5];
    if (sorted.length == weekdays.length &&
        sorted.every((day) => weekdays.contains(day))) {
      return 'Weekdays';
    }
    if (sorted.length == 7) {
      return 'Every day';
    }

    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return sorted.map((day) => labels[day] ?? '').join(', ');
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LuxuryColors.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: LuxuryColors.subtleBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: LuxuryTextStyles.titleLarge.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: LuxuryTextStyles.bodyMedium.copyWith(
                          color: LuxuryColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: LuxuryColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Future<void> _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings!.reminderHour,
        minute: _settings!.reminderMinute,
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: LuxuryColors.burnishedGold,
              surface: LuxuryColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _settings = NotificationSettings(
          enabled: _settings!.enabled,
          streakReminders: _settings!.streakReminders,
          dailyMotivation: _settings!.dailyMotivation,
          reminderHour: time.hour,
          reminderMinute: time.minute,
          cooldownMinutes: _settings!.cooldownMinutes,
        );
      });
      _saveSettings();
    }
  }

  Future<void> _showCooldownPicker() async {
    int? selectedCooldown = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: LuxuryColors.cardBackground,
          title: Text(
            'Emergency Break Cooldown',
            style: LuxuryTextStyles.titleLarge,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 12, // 5, 10, 15, ..., 60 minutes
              itemBuilder: (context, index) {
                int minutes = (index + 1) * 5;
                bool isSelected = _settings!.cooldownMinutes == minutes;
                return ListTile(
                  title: Text(
                    '$minutes minutes',
                    style: LuxuryTextStyles.bodyLarge.copyWith(
                      color: isSelected ? LuxuryColors.burnishedGold : LuxuryColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: LuxuryColors.burnishedGold)
                      : null,
                  onTap: () => Navigator.pop(context, minutes),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: LuxuryTextStyles.bodyMedium.copyWith(color: LuxuryColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );

    if (selectedCooldown != null && selectedCooldown != _settings!.cooldownMinutes) {
      setState(() {
        _settings = NotificationSettings(
          enabled: _settings!.enabled,
          streakReminders: _settings!.streakReminders,
          dailyMotivation: _settings!.dailyMotivation,
          reminderHour: _settings!.reminderHour,
          reminderMinute: _settings!.reminderMinute,
          cooldownMinutes: selectedCooldown,
        );
      });
      _saveSettings();
    }
  }
}
