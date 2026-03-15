import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/project_v2.dart';

class NotificationReminderCopy {
  final String channelName;
  final String channelDescription;
  final String titleToday;
  final String titleTomorrow;
  final String titleUpcoming;
  final String bodyToday;
  final String bodyTomorrow;
  final String bodyUpcomingOne;
  final String bodyUpcomingFew;
  final String bodyUpcomingMany;

  const NotificationReminderCopy({
    required this.channelName,
    required this.channelDescription,
    required this.titleToday,
    required this.titleTomorrow,
    required this.titleUpcoming,
    required this.bodyToday,
    required this.bodyTomorrow,
    required this.bodyUpcomingOne,
    required this.bodyUpcomingFew,
    required this.bodyUpcomingMany,
  });
}

/// Сервис для управления локальными уведомлениями о дедлайнах проектов.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'deadline_reminders';

  static const String _enabledKey = 'notifications_enabled';
  static const String _reminderDaysKey = 'notification_reminder_days';
  static const String _reminderHourKey = 'notification_reminder_hour';

  static bool _initialized = false;
  static String? _channelName;
  static String? _channelDescription;

  /// Инициализация сервиса уведомлений
  static Future<void> initialize({
    required String channelName,
    required String channelDescription,
  }) async {
    _channelName = channelName;
    _channelDescription = channelDescription;

    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return false;
  }

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  static Future<List<int>> getReminderDays() async {
    final prefs = await SharedPreferences.getInstance();
    final daysString = prefs.getStringList(_reminderDaysKey);
    if (daysString != null) {
      return daysString.map((s) => int.tryParse(s) ?? 1).toList();
    }
    return [1, 3, 7];
  }

  static Future<void> setReminderDays(List<int> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _reminderDaysKey,
      days.map((d) => d.toString()).toList(),
    );
  }

  static Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderHourKey) ?? 9;
  }

  static Future<void> setReminderHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, hour);
  }

  static Future<void> scheduleProjectReminders(
    ProjectV2 project, {
    required NotificationReminderCopy copy,
  }) async {
    if (!await areNotificationsEnabled()) return;
    if (project.deadline == null) return;
    if (project.status == ProjectStatus.completed ||
        project.status == ProjectStatus.cancelled) {
      return;
    }

    await initialize(
      channelName: copy.channelName,
      channelDescription: copy.channelDescription,
    );

    final reminderDays = await getReminderDays();
    final reminderHour = await getReminderHour();

    for (final days in reminderDays) {
      await _scheduleReminder(
        project: project,
        daysBefore: days,
        hour: reminderHour,
        copy: copy,
      );
    }
  }

  static Future<void> _scheduleReminder({
    required ProjectV2 project,
    required int daysBefore,
    required int hour,
    required NotificationReminderCopy copy,
  }) async {
    final deadline = project.deadline!;
    final reminderDate = deadline.subtract(Duration(days: daysBefore));
    final scheduledDate = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      0,
    );

    if (scheduledDate.isBefore(DateTime.now())) return;

    final notificationId = _generateNotificationId(project.id, daysBefore);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName ?? copy.channelName,
      channelDescription: _channelDescription ?? copy.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        _getReminderBody(copy, project.name, daysBefore),
        contentTitle: _getReminderTitle(copy, daysBefore),
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      _getReminderTitle(copy, daysBefore),
      _getReminderBody(copy, project.name, daysBefore),
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'project_${project.id}',
    );
  }

  static Future<void> cancelProjectReminders(int projectId) async {
    final reminderDays = await getReminderDays();
    for (final days in reminderDays) {
      final notificationId = _generateNotificationId(projectId, days);
      await _notifications.cancel(notificationId);
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> updateAllReminders(
    List<ProjectV2> projects, {
    required NotificationReminderCopy copy,
  }) async {
    if (!await areNotificationsEnabled()) return;

    await cancelAllNotifications();

    for (final project in projects) {
      await scheduleProjectReminders(project, copy: copy);
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize(
      channelName: _channelName ?? _channelId,
      channelDescription: _channelDescription ?? _channelId,
    );

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName ?? _channelId,
      channelDescription: _channelDescription ?? _channelId,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static int _generateNotificationId(int projectId, int daysBefore) {
    return projectId * 100 + daysBefore;
  }

  static String _getReminderTitle(NotificationReminderCopy copy, int daysBefore) {
    if (daysBefore == 0) {
      return copy.titleToday;
    } else if (daysBefore == 1) {
      return copy.titleTomorrow;
    }
    return copy.titleUpcoming;
  }

  static String _getReminderBody(
    NotificationReminderCopy copy,
    String projectName,
    int daysBefore,
  ) {
    if (daysBefore == 0) {
      return copy.bodyToday.replaceAll('{name}', projectName);
    } else if (daysBefore == 1) {
      return copy.bodyTomorrow.replaceAll('{name}', projectName);
    }

    final template = _selectUpcomingTemplate(copy, daysBefore);
    return template
        .replaceAll('{days}', daysBefore.toString())
        .replaceAll('{name}', projectName);
  }

  static String _selectUpcomingTemplate(
    NotificationReminderCopy copy,
    int daysBefore,
  ) {
    if (daysBefore % 10 == 1 && daysBefore % 100 != 11) {
      return copy.bodyUpcomingOne;
    } else if ([2, 3, 4].contains(daysBefore % 10) &&
        ![12, 13, 14].contains(daysBefore % 100)) {
      return copy.bodyUpcomingFew;
    }
    return copy.bodyUpcomingMany;
  }
}
