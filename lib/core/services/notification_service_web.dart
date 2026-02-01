// Веб-заглушка для NotificationService
// Уведомления не поддерживаются на вебе

/// Веб-заглушка для NotificationService
/// Уведомления не поддерживаются на вебе
class NotificationService {
  static Future<void> setNotificationsEnabled(bool enabled) async {
    // На вебе ничего не делаем
  }

  static Future<bool> requestPermission() async {
    // На вебе всегда возвращаем false
    return false;
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // На вебе ничего не делаем
  }

  static Future<void> cancelReminder(int id) async {
    // На вебе ничего не делаем
  }

  static Future<void> cancelAllReminders() async {
    // На вебе ничего не делаем
  }
}
