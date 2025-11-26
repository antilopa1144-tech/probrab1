import 'package:flutter/foundation.dart';

/// Централизованная обработка ошибок приложения.
class ErrorHandler {
  /// Получить понятное сообщение для пользователя из ошибки.
  static String getUserFriendlyMessage(Object error, [StackTrace? stackTrace]) {
    final errorMessage = error.toString().toLowerCase();
    
    // Ошибки загрузки данных
    if (errorMessage.contains('network') || errorMessage.contains('socket')) {
      return 'Проблема с сетью. Проверьте подключение к интернету.';
    }
    
    if (errorMessage.contains('timeout')) {
      return 'Превышено время ожидания. Попробуйте позже.';
    }
    
    // Ошибки базы данных
    if (errorMessage.contains('isar') || errorMessage.contains('database')) {
      return 'Ошибка базы данных. Попробуйте перезапустить приложение.';
    }
    
    // Ошибки парсинга
    if (errorMessage.contains('json') || errorMessage.contains('parse')) {
      return 'Ошибка чтения данных. Возможно, файл повреждён.';
    }
    
    // Ошибки файловой системы
    if (errorMessage.contains('file') || errorMessage.contains('permission')) {
      return 'Нет доступа к файлам. Проверьте разрешения приложения.';
    }
    
    // Ошибки валидации
    if (errorMessage.contains('validation') || errorMessage.contains('invalid')) {
      return 'Неверные данные. Проверьте введённые значения.';
    }
    
    // Общая ошибка
    return 'Произошла ошибка. Попробуйте ещё раз.';
  }

  /// Логировать ошибку (можно расширить для отправки в систему аналитики).
  static void logError(Object error, [StackTrace? stackTrace, String? context]) {
    // В production можно отправлять в Firebase Crashlytics, Sentry и т.д.
    if (context != null) {
      debugPrint('[$context] Error: $error');
    } else {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}

