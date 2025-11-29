import 'dart:async';
import 'package:flutter/foundation.dart';

/// Абстракция для сервиса отчётов об ошибках.
/// 
/// Позволяет легко переключаться между Firebase Crashlytics,
/// Sentry, или другими сервисами.
abstract class CrashReportingService {
  /// Инициализация сервиса
  Future<void> initialize();

  /// Записать ошибку
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// Записать лог-сообщение
  void log(String message);

  /// Установить пользовательский идентификатор
  Future<void> setUserId(String userId);

  /// Установить пользовательские данные
  Future<void> setCustomKey(String key, dynamic value);

  /// Принудительно вызвать crash (для тестирования)
  void crash();
}

/// Заглушка для разработки без Firebase.
/// 
/// Логирует все ошибки через debugPrint.
class DebugCrashReportingService implements CrashReportingService {
  static final DebugCrashReportingService _instance = 
      DebugCrashReportingService._internal();
  
  factory DebugCrashReportingService() => _instance;
  DebugCrashReportingService._internal();

  final List<ErrorRecord> _errorHistory = [];
  static const int _maxHistorySize = 100;

  @override
  Future<void> initialize() async {
    debugPrint('[CrashReporting] Debug service initialized');
  }

  @override
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    final record = ErrorRecord(
      error: error,
      stackTrace: stackTrace,
      reason: reason,
      fatal: fatal,
      timestamp: DateTime.now(),
    );

    _errorHistory.add(record);
    if (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }

    final severity = fatal ? 'FATAL' : 'ERROR';
    debugPrint('[$severity] ${reason ?? 'Unknown error'}');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  @override
  void log(String message) {
    debugPrint('[CrashReporting] $message');
  }

  @override
  Future<void> setUserId(String userId) async {
    debugPrint('[CrashReporting] User ID set: $userId');
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    debugPrint('[CrashReporting] Custom key: $key = $value');
  }

  @override
  void crash() {
    debugPrint('[CrashReporting] Test crash triggered (debug mode - no actual crash)');
  }

  /// Получить историю ошибок (для отладки)
  List<ErrorRecord> get errorHistory => List.unmodifiable(_errorHistory);

  /// Очистить историю ошибок
  void clearHistory() => _errorHistory.clear();
}

/// Запись об ошибке
class ErrorRecord {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? reason;
  final bool fatal;
  final DateTime timestamp;

  ErrorRecord({
    required this.error,
    this.stackTrace,
    this.reason,
    required this.fatal,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ErrorRecord(error: $error, reason: $reason, '
           'fatal: $fatal, timestamp: $timestamp)';
  }
}

/// Firebase Crashlytics реализация (требует подключения Firebase).
/// 
/// Для активации:
/// 1. Добавить firebase_crashlytics в pubspec.yaml
/// 2. Настроить Firebase проект
/// 3. Раскомментировать код ниже
/// 
/// ```yaml
/// # pubspec.yaml
/// dependencies:
///   firebase_core: ^2.24.2
///   firebase_crashlytics: ^3.4.8
/// ```
class FirebaseCrashReportingService implements CrashReportingService {
  // import 'package:firebase_crashlytics/firebase_crashlytics.dart';
  // 
  // late final FirebaseCrashlytics _crashlytics;
  
  @override
  Future<void> initialize() async {
    // await Firebase.initializeApp();
    // _crashlytics = FirebaseCrashlytics.instance;
    // 
    // // Включаем сбор ошибок в release режиме
    // await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    // 
    // // Перехват Flutter ошибок
    // FlutterError.onError = _crashlytics.recordFlutterFatalError;
    // 
    // // Перехват платформенных ошибок
    // PlatformDispatcher.instance.onError = (error, stack) {
    //   _crashlytics.recordError(error, stack, fatal: true);
    //   return true;
    // };
    
    debugPrint('[CrashReporting] Firebase Crashlytics would be initialized here');
    debugPrint('[CrashReporting] Currently using debug fallback');
  }

  @override
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    // await _crashlytics.recordError(
    //   error,
    //   stackTrace,
    //   reason: reason,
    //   fatal: fatal,
    // );
    
    // Fallback to debug logging
    await DebugCrashReportingService().recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  @override
  void log(String message) {
    // _crashlytics.log(message);
    DebugCrashReportingService().log(message);
  }

  @override
  Future<void> setUserId(String userId) async {
    // await _crashlytics.setUserIdentifier(userId);
    await DebugCrashReportingService().setUserId(userId);
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    // await _crashlytics.setCustomKey(key, value);
    await DebugCrashReportingService().setCustomKey(key, value);
  }

  @override
  void crash() {
    // _crashlytics.crash();
    DebugCrashReportingService().crash();
  }
}

/// Глобальный экземпляр сервиса отчётов об ошибках.
/// 
/// В production заменить на FirebaseCrashReportingService после настройки Firebase.
CrashReportingService crashReporting = DebugCrashReportingService();

/// Инициализация глобального обработчика ошибок
Future<void> initializeCrashReporting() async {
  await crashReporting.initialize();

  // Глобальный обработчик необработанных ошибок
  FlutterError.onError = (FlutterErrorDetails details) {
    crashReporting.recordError(
      details.exception,
      details.stack,
      reason: 'Flutter error: ${details.context}',
      fatal: true,
    );
    FlutterError.presentError(details);
  };
}

/// Обёртка для безопасного выполнения кода с автоматическим логированием ошибок
Future<T?> runSafe<T>(
  Future<T> Function() action, {
  String? context,
  T? fallback,
}) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    await crashReporting.recordError(
      error,
      stackTrace,
      reason: context ?? 'runSafe error',
    );
    return fallback;
  }
}
