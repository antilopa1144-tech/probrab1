import 'package:flutter/foundation.dart';

/// Категории ошибок для аналитики и мониторинга.
enum ErrorCategory {
  network,
  database,
  parsing,
  fileSystem,
  validation,
  unknown,
}

/// Централизованная обработка ошибок приложения.
class ErrorHandler {
  /// Получить категорию ошибки для аналитики.
  static ErrorCategory getErrorCategory(Object error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('network') || 
        errorMessage.contains('socket') || 
        errorMessage.contains('timeout')) {
      return ErrorCategory.network;
    }
    
    if (errorMessage.contains('isar') || 
        errorMessage.contains('database') || 
        errorMessage.contains('sql')) {
      return ErrorCategory.database;
    }
    
    if (errorMessage.contains('json') || 
        errorMessage.contains('parse') || 
        errorMessage.contains('decode')) {
      return ErrorCategory.parsing;
    }
    
    if (errorMessage.contains('file') || 
        errorMessage.contains('permission') || 
        errorMessage.contains('io')) {
      return ErrorCategory.fileSystem;
    }
    
    if (errorMessage.contains('validation') || 
        errorMessage.contains('invalid') || 
        errorMessage.contains('format')) {
      return ErrorCategory.validation;
    }
    
    return ErrorCategory.unknown;
  }

  /// Получить понятное сообщение для пользователя из ошибки.
  static String getUserFriendlyMessage(Object error, [StackTrace? stackTrace]) {
    final category = getErrorCategory(error);
    
    switch (category) {
      case ErrorCategory.network:
        return 'Проблема с сетью. Проверьте подключение к интернету.';
      case ErrorCategory.database:
        return 'Ошибка базы данных. Попробуйте перезапустить приложение.';
      case ErrorCategory.parsing:
        return 'Ошибка чтения данных. Возможно, файл повреждён.';
      case ErrorCategory.fileSystem:
        return 'Нет доступа к файлам. Проверьте разрешения приложения.';
      case ErrorCategory.validation:
        return 'Неверные данные. Проверьте введённые значения.';
      case ErrorCategory.unknown:
        return 'Произошла ошибка. Попробуйте ещё раз.';
    }
  }

  /// Логировать ошибку с категоризацией.
  /// 
  /// В production можно расширить для отправки в:
  /// - Firebase Crashlytics
  /// - Sentry
  /// - Custom analytics
  static void logError(
    Object error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final category = getErrorCategory(error);
    final timestamp = DateTime.now().toIso8601String();
    
    // Логирование в debug режиме
    if (kDebugMode) {
      final contextStr = context != null ? '[$context]' : '';
      debugPrint('[$timestamp] $contextStr [${category.name.toUpperCase()}] Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    // TODO: В production добавить отправку в аналитику
    // Пример для Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   reason: 'Error in $context',
    //   fatal: false,
    // );
    //
    // Пример для Sentry:
    // Sentry.captureException(
    //   error,
    //   stackTrace: stackTrace,
    //   hint: Hint.withMap({'context': context ?? 'unknown'}),
    // );
  }

  /// Логировать критическую ошибку (fatal).
  static void logFatalError(
    Object error,
    StackTrace stackTrace, [
    String? context,
  ]) {
    logError(error, stackTrace, context);
    
    // TODO: В production пометить как fatal для аналитики
    // FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   reason: 'Fatal error in $context',
    //   fatal: true,
    // );
  }
}

