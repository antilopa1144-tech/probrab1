import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../exceptions/app_exception.dart';
import '../exceptions/validation_exception.dart';
import '../exceptions/calculation_exception.dart';
import '../exceptions/storage_exception.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/export_exception.dart';
import '../services/tracker_service_web.dart'
    if (dart.library.io) '../services/tracker_service.dart';
import 'error_category.dart';

/// Глобальный обработчик ошибок приложения с UI интеграцией.
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  /// Получить категорию ошибки.
  static ErrorCategory getErrorCategory(Object error) {
    if (error is ValidationException) return ErrorCategory.validation;
    if (error is CalculationException) return ErrorCategory.calculation;
    if (error is StorageException) return ErrorCategory.storage;
    if (error is NetworkException) return ErrorCategory.network;
    if (error is ExportException) return ErrorCategory.export;
    if (error is FlutterError) return ErrorCategory.ui;

    // Проверка по строке сообщения (для необработанных исключений)
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('network') ||
        errorMessage.contains('socket') ||
        errorMessage.contains('timeout')) {
      return ErrorCategory.network;
    }
    if (errorMessage.contains('database') ||
        errorMessage.contains('isar') ||
        errorMessage.contains('sql')) {
      return ErrorCategory.storage;
    }
    if (errorMessage.contains('validation') ||
        errorMessage.contains('invalid')) {
      return ErrorCategory.validation;
    }

    return ErrorCategory.unknown;
  }

  /// Получить удобное для пользователя сообщение.
  static String getUserFriendlyMessage(Object error, [StackTrace? stackTrace]) {
    // Обработка AppException
    if (error is AppException) {
      return error.getUserMessage();
    }

    // Обработка стандартных Flutter ошибок
    if (error is FlutterError) {
      return 'Произошла ошибка интерфейса. Попробуйте перезапустить приложение.';
    }

    // Обработка по категории
    final category = getErrorCategory(error);
    return switch (category) {
      ErrorCategory.network =>
        'Проблема с сетью. Проверьте подключение к интернету.',
      ErrorCategory.storage =>
        'Ошибка базы данных. Попробуйте перезапустить приложение.',
      ErrorCategory.validation =>
        'Неверные данные. Проверьте введённые значения.',
      ErrorCategory.calculation => 'Ошибка расчёта. Проверьте входные данные.',
      ErrorCategory.export =>
        'Не удалось экспортировать данные. Попробуйте ещё раз.',
      ErrorCategory.ui =>
        'Ошибка отображения. Попробуйте перезапустить приложение.',
      ErrorCategory.unknown =>
        'Произошла неожиданная ошибка. Попробуйте ещё раз.',
    };
  }

  /// Логировать ошибку.
  static void logError(
    Object error, [
    StackTrace? stackTrace,
    String? contextMessage,
  ]) {
    final category = getErrorCategory(error);
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      final contextStr = contextMessage != null ? '[$contextMessage]' : '';
      debugPrint(
        '[$timestamp] $contextStr [${category.name.toUpperCase()}] Error: $error',
      );
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // Отправка ошибки в Firebase Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: contextMessage,
        fatal: false,
      );

      // Отправка события в Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'error_occurred',
        parameters: {
          'error_category': category.name,
          'error_type': error.runtimeType.toString(),
          'context': contextMessage ?? 'unknown',
          'timestamp': timestamp,
        },
      );

      // Дублируем в MyTracker
      TrackerService.trackError(
        category: category.name,
        type: error.runtimeType.toString(),
        context: contextMessage,
      );
    } catch (e) {
      // Игнорируем ошибки Firebase/MyTracker, если сервис недоступен
    }
  }

  /// Логировать критическую ошибку.
  static void logFatalError(
    Object error,
    StackTrace stackTrace, [
    String? contextMessage,
  ]) {
    final category = getErrorCategory(error);
    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      final contextStr = contextMessage != null ? '[$contextMessage]' : '';
      debugPrint(
        '[$timestamp] $contextStr [${category.name.toUpperCase()}] FATAL Error: $error',
      );
      debugPrint('Stack trace: $stackTrace');
    }

    // Отправка критической ошибки в Firebase Crashlytics
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: contextMessage,
        fatal: true,
      );

      // Отправка критического события в Firebase Analytics
      FirebaseAnalytics.instance.logEvent(
        name: 'fatal_error',
        parameters: {
          'error_category': category.name,
          'error_type': error.runtimeType.toString(),
          'context': contextMessage ?? 'unknown',
          'timestamp': timestamp,
        },
      );

      // Дублируем в MyTracker
      TrackerService.trackError(
        category: category.name,
        type: error.runtimeType.toString(),
        context: contextMessage,
        fatal: true,
      );
    } catch (e) {
      // Игнорируем ошибки Firebase/MyTracker, если сервис недоступен
    }
  }

  /// Показать ошибку через SnackBar.
  static void showErrorSnackBar(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? contextMessage,
    VoidCallback? onRetry,
  }) {
    logError(error, stackTrace, contextMessage);

    final message = getUserFriendlyMessage(error, stackTrace);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Повторить',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Показать ошибку через диалог.
  static Future<void> showErrorDialog(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? contextMessage,
    String? title,
    VoidCallback? onRetry,
  }) async {
    logError(error, stackTrace, contextMessage);

    final message = getUserFriendlyMessage(error, stackTrace);
    final category = getErrorCategory(error);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          _getIconForCategory(category),
          size: 48,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(title ?? _getTitleForCategory(category)),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              child: const Text('Повторить'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  /// Получить иконку для категории ошибки.
  static IconData _getIconForCategory(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.validation => Icons.warning_rounded,
      ErrorCategory.calculation => Icons.calculate_outlined,
      ErrorCategory.storage => Icons.storage_rounded,
      ErrorCategory.network => Icons.wifi_off_rounded,
      ErrorCategory.export => Icons.file_download_off_rounded,
      ErrorCategory.ui => Icons.bug_report_rounded,
      ErrorCategory.unknown => Icons.error_outline_rounded,
    };
  }

  /// Получить заголовок для категории ошибки.
  static String _getTitleForCategory(ErrorCategory category) {
    return switch (category) {
      ErrorCategory.validation => 'Ошибка ввода',
      ErrorCategory.calculation => 'Ошибка расчёта',
      ErrorCategory.storage => 'Ошибка хранилища',
      ErrorCategory.network => 'Ошибка сети',
      ErrorCategory.export => 'Ошибка экспорта',
      ErrorCategory.ui => 'Ошибка интерфейса',
      ErrorCategory.unknown => 'Ошибка',
    };
  }

  /// Обработать ошибку и показать пользователю (умное определение: SnackBar или Dialog).
  static void handle(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? contextMessage,
    VoidCallback? onRetry,
    bool useDialog = false,
  }) {
    if (useDialog || error is AppException) {
      showErrorDialog(
        context,
        error,
        stackTrace: stackTrace,
        contextMessage: contextMessage,
        onRetry: onRetry,
      );
    } else {
      showErrorSnackBar(
        context,
        error,
        stackTrace: stackTrace,
        contextMessage: contextMessage,
        onRetry: onRetry,
      );
    }
  }
}
