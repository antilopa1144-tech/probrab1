import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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
    String errorMessage = error.toString().toLowerCase();
    // Remove "Exception: " prefix to avoid false matches (e.g., "exception" contains "io")
    if (errorMessage.startsWith('exception: ')) {
      errorMessage = errorMessage.substring('exception: '.length);
    }
    
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
  /// Отправляет ошибки в Firebase Crashlytics и Analytics
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

    // Отправка в Firebase Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: context != null ? 'Error in $context' : null,
        fatal: false,
      );

      // Отправка события в Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'error_occurred',
        parameters: {
          'error_category': category.name,
          'error_type': error.runtimeType.toString(),
          'context': context ?? 'unknown',
        },
      );
    } catch (e) {
      // Игнорируем ошибки при отправке в Firebase
      if (kDebugMode) {
        debugPrint('Failed to send error to Firebase: $e');
      }
    }
  }

  /// Логировать критическую ошибку (fatal).
  static void logFatalError(
    Object error,
    StackTrace stackTrace, [
    String? context,
  ]) {
    final category = getErrorCategory(error);

    if (kDebugMode) {
      final contextStr = context != null ? '[$context]' : '';
      debugPrint('[FATAL] $contextStr [${category.name.toUpperCase()}] Error: $error');
      debugPrint('Stack trace: $stackTrace');
    }

    // Отправка в Firebase Crashlytics как fatal
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: context != null ? 'Fatal error in $context' : 'Fatal error',
        fatal: true,
      );

      // Отправка события в Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'fatal_error_occurred',
        parameters: {
          'error_category': category.name,
          'error_type': error.runtimeType.toString(),
          'context': context ?? 'unknown',
        },
      );
    } catch (e) {
      // Игнорируем ошибки при отправке в Firebase
      if (kDebugMode) {
        debugPrint('Failed to send fatal error to Firebase: $e');
      }
    }
  }
}

