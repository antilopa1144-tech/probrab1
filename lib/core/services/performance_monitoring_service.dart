import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Сервис для мониторинга производительности приложения через Firebase Performance
class PerformanceMonitoringService {
  static FirebasePerformance? _performance;

  /// Безопасное получение инстанса Firebase Performance
  static FirebasePerformance? get _safePerformance {
    try {
      _performance ??= FirebasePerformance.instance;
      return _performance;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase Performance unavailable: $e');
      }
      return null;
    }
  }

  /// Включен ли мониторинг производительности
  static Future<bool> get isPerformanceCollectionEnabled async {
    try {
      return await _safePerformance?.isPerformanceCollectionEnabled() ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Включить/выключить сбор метрик производительности
  static Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    try {
      await _safePerformance?.setPerformanceCollectionEnabled(enabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to set performance collection: $e');
      }
    }
  }

  /// Создать кастомную метрику для отслеживания
  ///
  /// Пример использования:
  /// ```dart
  /// final trace = PerformanceMonitoringService.startTrace('calculate_plaster');
  /// // ... выполнение операции ...
  /// await trace.stop();
  /// ```
  static Trace? startTrace(String traceName) {
    try {
      return _safePerformance?.newTrace(traceName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to start trace: $e');
      }
      return null;
    }
  }

  /// Отследить выполнение калькулятора
  ///
  /// Автоматически создаёт trace и останавливает его после завершения
  static Future<T> traceCalculation<T>({
    required String calculatorId,
    required Future<T> Function() calculation,
  }) async {
    if (kDebugMode) {
      // В debug режиме не отслеживаем для экономии ресурсов
      return calculation();
    }

    final trace = startTrace('calculator_$calculatorId');
    if (trace == null) return calculation();

    trace.putAttribute('calculator_id', calculatorId);

    try {
      await trace.start();
      final result = await calculation();
      return result;
    } catch (e) {
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Отследить загрузку экрана
  ///
  /// ```dart
  /// await PerformanceMonitoringService.traceScreenLoad(
  ///   screenName: 'calculator_screen',
  ///   load: () async {
  ///     // Загрузка данных
  ///   },
  /// );
  /// ```
  static Future<T> traceScreenLoad<T>({
    required String screenName,
    required Future<T> Function() load,
  }) async {
    if (kDebugMode) {
      return load();
    }

    final trace = startTrace('screen_load_$screenName');
    if (trace == null) return load();

    trace.putAttribute('screen', screenName);

    try {
      await trace.start();
      final result = await load();
      return result;
    } catch (e) {
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Отследить загрузку данных из базы
  static Future<T> traceDatabaseQuery<T>({
    required String queryName,
    required Future<T> Function() query,
  }) async {
    if (kDebugMode) {
      return query();
    }

    final trace = startTrace('db_query_$queryName');
    if (trace == null) return query();

    trace.putAttribute('query_name', queryName);

    try {
      await trace.start();
      final result = await query();
      return result;
    } catch (e) {
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// Отследить сетевой запрос (для будущего API)
  ///
  /// ```dart
  /// final metric = PerformanceMonitoringService.newHttpMetric(
  ///   url: 'https://api.example.com/prices',
  ///   method: HttpMethod.Get,
  /// );
  ///
  /// await metric.start();
  /// // ... выполнение запроса ...
  /// metric.responseCode = 200;
  /// metric.responsePayloadSize = 1024;
  /// await metric.stop();
  /// ```
  static HttpMetric? newHttpMetric({
    required String url,
    required HttpMethod method,
  }) {
    try {
      return _safePerformance?.newHttpMetric(url, method);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to create HTTP metric: $e');
      }
      return null;
    }
  }

  /// Отследить время выполнения синхронной операции
  ///
  /// ```dart
  /// final result = PerformanceMonitoringService.measureSync(
  ///   name: 'heavy_computation',
  ///   operation: () {
  ///     // Тяжёлые вычисления
  ///     return result;
  ///   },
  /// );
  /// ```
  static T measureSync<T>({
    required String name,
    required T Function() operation,
  }) {
    if (kDebugMode) {
      return operation();
    }

    final trace = startTrace(name);
    if (trace == null) return operation();

    trace.start();

    try {
      final result = operation();
      return result;
    } catch (e) {
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      trace.stop();
    }
  }

  /// Кастомная метрика для отслеживания специфичных событий
  ///
  /// ```dart
  /// PerformanceMonitoringService.recordCustomMetric(
  ///   name: 'calculators_opened',
  ///   value: 42,
  /// );
  /// ```
  static void recordCustomMetric({
    required String name,
    required int value,
    Map<String, String>? attributes,
  }) {
    if (kDebugMode) return;

    final trace = startTrace('custom_$name');
    if (trace == null) return;

    trace.setMetric(name, value);

    if (attributes != null) {
      attributes.forEach((key, value) {
        trace.putAttribute(key, value);
      });
    }

    trace.start();
    trace.stop();
  }

  /// Отследить пользовательское действие
  ///
  /// ```dart
  /// await PerformanceMonitoringService.traceUserAction(
  ///   action: 'add_to_favorites',
  ///   execute: () async {
  ///     await favoritesService.add(calculatorId);
  ///   },
  ///   metadata: {'calculator_id': calculatorId},
  /// );
  /// ```
  static Future<T> traceUserAction<T>({
    required String action,
    required Future<T> Function() execute,
    Map<String, String>? metadata,
  }) async {
    if (kDebugMode) {
      return execute();
    }

    final trace = startTrace('user_action_$action');
    if (trace == null) return execute();

    trace.putAttribute('action', action);

    if (metadata != null) {
      metadata.forEach((key, value) {
        trace.putAttribute(key, value);
      });
    }

    try {
      await trace.start();
      final result = await execute();
      return result;
    } catch (e) {
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
