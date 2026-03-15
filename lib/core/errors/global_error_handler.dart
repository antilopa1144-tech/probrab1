import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../localization/app_localizations.dart';
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
  static String getUserFriendlyMessage(
    dynamic contextOrError, [
    Object? errorOrStackTrace,
    StackTrace? stackTrace,
  ]) {
    BuildContext? context;
    late final Object error;

    if (contextOrError is BuildContext) {
      context = contextOrError;
      error = errorOrStackTrace as Object;
    } else {
      error = contextOrError as Object;
      if (errorOrStackTrace is StackTrace) {
        stackTrace = errorOrStackTrace;
      }
    }

    final translate = _getTranslator(context);

    if (error is AppException) {
      return error.getUserMessage(translate);
    }

    if (error is FlutterError) {
      return translate('error.message.ui');
    }

    final category = getErrorCategory(error);
    return switch (category) {
      ErrorCategory.network => translate('error.message.network'),
      ErrorCategory.storage => translate('error.message.storage'),
      ErrorCategory.validation => translate('error.message.validation'),
      ErrorCategory.calculation => translate('error.message.calculation'),
      ErrorCategory.export => translate('error.message.export'),
      ErrorCategory.ui => translate('error.message.ui'),
      ErrorCategory.unknown => translate('error.message.unknown'),
    };
  }


  static String Function(String key) _getTranslator(BuildContext? context) {
    if (context != null) {
      try {
        return AppLocalizations.of(context).translate;
      } catch (_) {
        // В тестах и ранних фазах инициализации локализация может быть ещё недоступна.
      }
    }
    return _getFallbackTranslation;
  }

  static String _translate(BuildContext? context, String key) {
    return _getTranslator(context)(key);
  }

  static String _getFallbackTranslation(String key) {
    switch (key) {
      case 'retry':
        return 'Повторить';
      case 'button.close':
        return 'ОК';
      case 'error.calculation':
        return 'Ошибка расчёта';
      case 'error.title.validation':
        return 'Проверьте данные';
      case 'error.title.calculation':
        return 'Ошибка расчёта';
      case 'error.title.storage':
        return 'Ошибка данных';
      case 'error.title.network':
        return 'Ошибка сети';
      case 'error.title.export':
        return 'Ошибка экспорта';
      case 'error.title.ui':
        return 'Ошибка интерфейса';
      case 'error.title.unknown':
        return 'Что-то пошло не так';
      case 'error.message.network':
        return 'Проблема с сетью. Проверьте подключение к интернету.';
      case 'error.message.storage':
        return 'Ошибка при работе с данными. Попробуйте ещё раз.';
      case 'error.message.validation':
        return 'Проверьте введённые данные.';
      case 'error.message.calculation':
        return 'Ошибка расчёта. Проверьте исходные данные.';
      case 'error.message.export':
        return 'Не удалось выполнить экспорт. Попробуйте ещё раз.';
      case 'error.message.ui':
        return 'Произошла ошибка интерфейса. Попробуйте повторить действие.';
      case 'error.message.unknown':
        return 'Произошла ошибка. Попробуйте ещё раз.';
      case 'error.message.calculation_division_by_zero':
        return 'Ошибка расчёта. Деление на ноль: {context}';
      case 'error.message.calculation_invalid_input':
        return 'Некорректные входные данные для расчёта "{calculatorId}": {reason}';
      case 'error.message.calculation_overflow':
        return 'Ошибка расчёта. Слишком большое значение: {context}';
      case 'error.message.calculation_missing_data':
        return 'Не хватает данных для расчёта: {dataType}';
      case 'error.message.export_generation_error':
        return 'Не удалось создать файл формата {format}. Попробуйте ещё раз.';
      case 'error.message.export_permission_denied':
        return 'Нет прав доступа к файлам. Проверьте разрешения приложения.';
      case 'error.message.export_insufficient_space':
        return 'Недостаточно места на устройстве.';
      case 'error.message.export_invalid_data':
        return 'Некорректные данные для экспорта: {reason}';
      case 'error.message.network_no_connection':
        return 'Проверьте подключение к интернету.';
      case 'error.message.network_timeout':
        return 'Сервер не отвечает. Попробуйте позже.';
      case 'error.message.network_server_error':
        return 'Ошибка на сервере. Попробуйте позже.';
      case 'error.message.network_bad_request':
        return 'Неверный запрос. Обратитесь в поддержку.';
      case 'error.message.network_not_found':
        return 'Запрошенные данные не найдены.';
      case 'error.message.storage_not_found':
        return 'Данные не найдены.';
      case 'error.message.storage_save_error':
        return 'Не удалось сохранить данные.';
      case 'error.message.storage_delete_error':
        return 'Не удалось удалить данные.';
      case 'error.message.storage_read_error':
        return 'Не удалось прочитать данные.';
      case 'error.message.storage_database_error':
        return 'Ошибка при работе с данными.';
      case 'error.message.validation_required_field':
        return 'Поле "{field}" обязательно для заполнения';
      case 'error.message.validation_min_value':
        return 'Значение поля "{field}" должно быть не меньше {min}';
      case 'error.message.validation_max_value':
        return 'Значение поля "{field}" должно быть не больше {max}';
      case 'error.message.validation_invalid_format':
        return 'Неверный формат поля "{field}". Ожидается: {expectedFormat}';
      case 'error.message.validation_negative_value':
        return 'Значение поля "{field}" не может быть отрицательным';
      case 'error.message.validation_area_too_large':
        return 'Площадь {area} м² кажется слишком большой. Проверьте значение.';
      case 'error.message.validation_volume_too_large':
        return 'Объём {volume} м³ кажется слишком большим. Проверьте значение.';
      case 'error.message.validation_length_width_ratio':
        return 'Длина ({length} м) значительно больше ширины ({width} м). Возможно, вы перепутали значения?';
      case 'error.message.validation_width_length_ratio':
        return 'Ширина ({width} м) значительно больше длины ({length} м). Возможно, вы перепутали значения?';
      case 'error.message.validation_thickness_too_large':
        return 'Толщина {thickness} мм кажется слишком большой. Проверьте единицы измерения.';
      case 'error.message.validation_thickness_too_small':
        return 'Толщина {thickness} мм кажется слишком маленькой. Проверьте значение.';
      case 'error.message.validation_height_too_large':
        return 'Высота {height} м кажется слишком большой для помещения. Проверьте значение.';
      case 'error.message.validation_perimeter_too_small':
        return 'Периметр ({perimeter} м) слишком мал для указанной площади ({area} м²). Проверьте значения.';
      case 'error.message.validation_paint_consumption_too_large':
        return 'Расход краски ({consumption} л/м²) кажется слишком большим. Обычно 0.1-0.2 л/м².';
      case 'error.message.validation_primer_consumption_too_large':
        return 'Расход грунтовки ({consumption} л/м²) кажется слишком большим. Обычно 0.08-0.15 л/м².';
      case 'error.message.validation_plaster_consumption_too_large':
        return 'Расход штукатурки ({consumption} кг/м²) кажется слишком большим. Проверьте толщину слоя.';
      default:
        return key;
    }
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

    final message = getUserFriendlyMessage(context, error, stackTrace);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: _translate(context, 'retry'),
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

    final message = getUserFriendlyMessage(context, error, stackTrace);
    final category = getErrorCategory(error);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          _getIconForCategory(category),
          size: 48,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(title ?? _getTitleForCategory(dialogContext, category)),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              child: Text(_translate(dialogContext, 'retry')),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_translate(dialogContext, 'button.close')),
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
  static String _getTitleForCategory(
    BuildContext context,
    ErrorCategory category,
  ) {
    final translate = _getTranslator(context);
    return switch (category) {
      ErrorCategory.validation => translate('error.title.validation'),
      ErrorCategory.calculation => translate('error.title.calculation'),
      ErrorCategory.storage => translate('error.title.storage'),
      ErrorCategory.network => translate('error.title.network'),
      ErrorCategory.export => translate('error.title.export'),
      ErrorCategory.ui => translate('error.title.ui'),
      ErrorCategory.unknown => translate('error.title.unknown'),
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
