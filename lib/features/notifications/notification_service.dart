import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:convert';

/// Notification service for streak reminders and daily check-ins
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage();
  static const _settingsKey = 'notification_settings';
  static const _focusSchedulesKey = 'focus_schedules';
  static const _focusScheduleNotificationStartId = 1000;
  static const _focusScheduleNotificationEndId = 1300;
  static bool _initialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    tz_data.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  static Future<bool> requestPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    
    return true;
  }

  /// Get notification settings
  static Future<NotificationSettings> getSettings() async {
    final data = await _storage.read(key: _settingsKey);
    if (data == null) return NotificationSettings();
    try {
      return NotificationSettings.fromJson(jsonDecode(data));
    } catch (e) {
      return NotificationSettings();
    }
  }

  /// Save notification settings
  static Future<void> saveSettings(NotificationSettings settings) async {
    await _storage.write(
      key: _settingsKey,
      value: jsonEncode(settings.toJson()),
    );
    
    // Update scheduled notifications
    if (settings.enabled) {
      await scheduleStreakReminder(settings);
      await scheduleDailyMotivation(settings);
      final schedules = await getFocusSchedules();
      await _rescheduleFocusSchedules(schedules);
    } else {
      await cancelAllNotifications();
    }
  }

  /// Get recurring focus schedules
  static Future<List<FocusSchedule>> getFocusSchedules() async {
    final data = await _storage.read(key: _focusSchedulesKey);
    if (data == null) {
      return [];
    }

    try {
      final raw = jsonDecode(data) as List<dynamic>;
      return raw
          .map((item) => FocusSchedule.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save all focus schedules and refresh scheduled notifications
  static Future<void> saveFocusSchedules(List<FocusSchedule> schedules) async {
    await _storage.write(
      key: _focusSchedulesKey,
      value: jsonEncode(schedules.map((schedule) => schedule.toJson()).toList()),
    );

    final settings = await getSettings();
    if (settings.enabled) {
      await _rescheduleFocusSchedules(schedules);
    }
  }

  /// Add or update a single focus schedule
  static Future<void> saveFocusSchedule(FocusSchedule schedule) async {
    final schedules = await getFocusSchedules();
    final index = schedules.indexWhere((item) => item.id == schedule.id);

    if (index >= 0) {
      schedules[index] = schedule;
    } else {
      schedules.add(schedule);
    }

    await saveFocusSchedules(schedules);
  }

  /// Delete a focus schedule by id
  static Future<void> deleteFocusSchedule(String id) async {
    final schedules = await getFocusSchedules();
    schedules.removeWhere((schedule) => schedule.id == id);
    await saveFocusSchedules(schedules);
  }

  static Future<void> _rescheduleFocusSchedules(
    List<FocusSchedule> schedules,
  ) async {
    for (int id = _focusScheduleNotificationStartId;
        id < _focusScheduleNotificationEndId;
        id++) {
      await _notifications.cancel(id);
    }

    int notificationId = _focusScheduleNotificationStartId;
    for (final schedule in schedules.where((item) => item.enabled)) {
      for (final day in schedule.days) {
        if (notificationId >= _focusScheduleNotificationEndId) return;

        final scheduledDateTime = _nextDateTimeForWeekday(
          day,
          schedule.hour,
          schedule.minute,
        );

        await _notifications.zonedSchedule(
          notificationId,
          '⏰ ${schedule.name}',
          'Scheduled tunnel: ${schedule.durationMinutes} minutes. Start now.',
          tz.TZDateTime.from(scheduledDateTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'focus_schedule',
              'Focus Schedules',
              channelDescription: 'Recurring deep work schedule reminders',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: Color(0xFF50C878),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'focus_schedule:${schedule.id}:$day',
        );

        notificationId++;
      }
    }
  }

  static DateTime _nextDateTimeForWeekday(
    int weekday,
    int hour,
    int minute,
  ) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);

    int dayOffset = weekday - now.weekday;
    if (dayOffset < 0 || (dayOffset == 0 && !target.isAfter(now))) {
      dayOffset += 7;
    }

    target = target.add(Duration(days: dayOffset));
    return target;
  }

  /// Schedule streak reminder notification
  static Future<void> scheduleStreakReminder(NotificationSettings settings) async {
    if (!settings.enabled || !settings.streakReminders) return;
    
    await _notifications.cancel(1); // Cancel existing streak reminder
    
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      settings.reminderHour,
      settings.reminderMinute,
    );
    
    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    await _notifications.zonedSchedule(
      1,
      '🔥 Protect Your Streak!',
      'You haven\'t focused today. Just 15 minutes keeps your streak alive!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder',
          'Streak Reminders',
          channelDescription: 'Daily reminders to maintain your focus streak',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD4AF37),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'streak_reminder',
    );
  }

  /// Schedule daily motivation notification
  static Future<void> scheduleDailyMotivation(NotificationSettings settings) async {
    if (!settings.enabled || !settings.dailyMotivation) return;
    
    await _notifications.cancel(2); // Cancel existing motivation
    
    final now = DateTime.now();
    var morningTime = DateTime(now.year, now.month, now.day, 8, 0);
    
    if (morningTime.isBefore(now)) {
      morningTime = morningTime.add(const Duration(days: 1));
    }
    
    final motivations = [
      ('🚀 Ready to Focus?', 'Your best work happens in the tunnel. Start a session now!'),
      ('💪 Level Up Today', 'Every minute of deep work builds your focus muscle.'),
      ('⚡ Time to Lock In', 'The world can wait. Your goals can\'t.'),
      ('🎯 One Task. Full Focus.', 'Enter the tunnel and make today count.'),
      ('🧠 Deep Work Awaits', 'Your phone locked = your potential unlocked.'),
    ];
    
    final random = DateTime.now().millisecond % motivations.length;
    final motivation = motivations[random];
    
    await _notifications.zonedSchedule(
      2,
      motivation.$1,
      motivation.$2,
      tz.TZDateTime.from(morningTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_motivation',
          'Daily Motivation',
          channelDescription: 'Morning motivation to start your focus day',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF7EC8E3),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_motivation',
    );
  }

  /// Show instant notification (for achievements, etc)
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
          'Instant Notifications',
          channelDescription: 'Instant notifications for achievements and updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF50C878),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

/// Notification & App settings model
class NotificationSettings {
  bool enabled;
  bool streakReminders;
  bool dailyMotivation;
  int reminderHour;
  int reminderMinute;
  int cooldownMinutes;

  NotificationSettings({
    this.enabled = true,
    this.streakReminders = true,
    this.dailyMotivation = true,
    this.reminderHour = 20, // 8 PM default
    this.reminderMinute = 0,
    this.cooldownMinutes = 20, // 20 minutes default cooldown
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'streakReminders': streakReminders,
    'dailyMotivation': dailyMotivation,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'cooldownMinutes': cooldownMinutes,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => NotificationSettings(
    enabled: json['enabled'] ?? true,
    streakReminders: json['streakReminders'] ?? true,
    dailyMotivation: json['dailyMotivation'] ?? true,
    reminderHour: json['reminderHour'] ?? 20,
    reminderMinute: json['reminderMinute'] ?? 0,
    cooldownMinutes: json['cooldownMinutes'] ?? 20,
  );
}

class FocusSchedule {
  final String id;
  final String name;
  final int hour;
  final int minute;
  final int durationMinutes;
  final List<int> days;
  final bool enabled;

  FocusSchedule({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.durationMinutes,
    required this.days,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hour': hour,
    'minute': minute,
    'durationMinutes': durationMinutes,
    'days': days,
    'enabled': enabled,
  };

  factory FocusSchedule.fromJson(Map<String, dynamic> json) => FocusSchedule(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Focus Block',
    hour: json['hour'] ?? 9,
    minute: json['minute'] ?? 0,
    durationMinutes: json['durationMinutes'] ?? 45,
    days: List<int>.from(json['days'] ?? const [1, 2, 3, 4, 5]),
    enabled: json['enabled'] ?? true,
  );

  FocusSchedule copyWith({
    String? id,
    String? name,
    int? hour,
    int? minute,
    int? durationMinutes,
    List<int>? days,
    bool? enabled,
  }) {
    return FocusSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
    );
  }
}

final notificationSettingsProvider = FutureProvider<NotificationSettings>((ref) async {
  return NotificationService.getSettings();
});

final focusSchedulesProvider = FutureProvider<List<FocusSchedule>>((ref) async {
  return NotificationService.getFocusSchedules();
});
