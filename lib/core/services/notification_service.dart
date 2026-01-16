import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../domain/models/project_v2.dart';

/// Сервис для управления локальными уведомлениями о дедлайнах проектов.
///
/// Функции:
/// - Напоминания о приближающихся дедлайнах (за 1, 3, 7 дней)
/// - Уведомления о просроченных дедлайнах
/// - Настраиваемое время уведомлений
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'deadline_reminders';
  static const String _channelName = 'Напоминания о дедлайнах';
  static const String _channelDescription =
      'Уведомления о приближающихся и просроченных дедлайнах проектов';

  static const String _enabledKey = 'notifications_enabled';
  static const String _reminderDaysKey = 'notification_reminder_days';
  static const String _reminderHourKey = 'notification_reminder_hour';

  static bool _initialized = false;

  /// Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    if (_initialized) return;

    // Инициализация часовых поясов
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

  /// Обработчик нажатия на уведомление
  static void _onNotificationTapped(NotificationResponse response) {
    // Здесь можно добавить навигацию к проекту по payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Запросить разрешение на уведомления
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

  /// Проверить, включены ли уведомления
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Включить/выключить уведомления
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// Получить список дней для напоминаний (по умолчанию: 1, 3, 7)
  static Future<List<int>> getReminderDays() async {
    final prefs = await SharedPreferences.getInstance();
    final daysString = prefs.getStringList(_reminderDaysKey);
    if (daysString != null) {
      return daysString.map((s) => int.tryParse(s) ?? 1).toList();
    }
    return [1, 3, 7]; // По умолчанию
  }

  /// Установить дни для напоминаний
  static Future<void> setReminderDays(List<int> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _reminderDaysKey,
      days.map((d) => d.toString()).toList(),
    );
  }

  /// Получить час для напоминаний (по умолчанию: 9:00)
  static Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderHourKey) ?? 9;
  }

  /// Установить час для напоминаний
  static Future<void> setReminderHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, hour);
  }

  /// Запланировать напоминания для проекта
  static Future<void> scheduleProjectReminders(ProjectV2 project) async {
    if (!await areNotificationsEnabled()) return;
    if (project.deadline == null) return;
    if (project.status == ProjectStatus.completed ||
        project.status == ProjectStatus.cancelled) {
      return;
    }

    await initialize();

    final reminderDays = await getReminderDays();
    final reminderHour = await getReminderHour();

    for (final days in reminderDays) {
      await _scheduleReminder(
        project: project,
        daysBefore: days,
        hour: reminderHour,
      );
    }
  }

  /// Запланировать конкретное напоминание
  static Future<void> _scheduleReminder({
    required ProjectV2 project,
    required int daysBefore,
    required int hour,
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

    // Не планируем уведомления в прошлом
    if (scheduledDate.isBefore(DateTime.now())) return;

    final notificationId = _generateNotificationId(project.id, daysBefore);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        _getReminderBody(project.name, daysBefore),
        contentTitle: _getReminderTitle(daysBefore),
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
      _getReminderTitle(daysBefore),
      _getReminderBody(project.name, daysBefore),
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'project_${project.id}',
    );
  }

  /// Отменить все напоминания для проекта
  static Future<void> cancelProjectReminders(int projectId) async {
    final reminderDays = await getReminderDays();
    for (final days in reminderDays) {
      final notificationId = _generateNotificationId(projectId, days);
      await _notifications.cancel(notificationId);
    }
  }

  /// Отменить все уведомления
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Обновить напоминания для всех проектов
  static Future<void> updateAllReminders(List<ProjectV2> projects) async {
    if (!await areNotificationsEnabled()) return;

    await cancelAllNotifications();

    for (final project in projects) {
      await scheduleProjectReminders(project);
    }
  }

  /// Показать мгновенное уведомление
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
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

  static String _getReminderTitle(int daysBefore) {
    if (daysBefore == 0) {
      return 'Дедлайн сегодня!';
    } else if (daysBefore == 1) {
      return 'Дедлайн завтра!';
    } else {
      return 'Напоминание о дедлайне';
    }
  }

  static String _getReminderBody(String projectName, int daysBefore) {
    if (daysBefore == 0) {
      return 'Сегодня дедлайн проекта "$projectName"';
    } else if (daysBefore == 1) {
      return 'Завтра дедлайн проекта "$projectName"';
    } else {
      return 'Через $daysBefore ${_getDaysWord(daysBefore)} дедлайн проекта "$projectName"';
    }
  }

  static String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }
}
