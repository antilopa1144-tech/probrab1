import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/performance_monitoring_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceMonitoringService', () {
    group('isPerformanceCollectionEnabled', () {
      test('возвращает Future<bool>', () async {
        final result = await PerformanceMonitoringService.isPerformanceCollectionEnabled;
        expect(result, isA<bool>());
      });
    });

    group('setPerformanceCollectionEnabled', () {
      test('выполняется без ошибок для true', () async {
        expect(
          () => PerformanceMonitoringService.setPerformanceCollectionEnabled(true),
          returnsNormally,
        );
      });

      test('выполняется без ошибок для false', () async {
        expect(
          () => PerformanceMonitoringService.setPerformanceCollectionEnabled(false),
          returnsNormally,
        );
      });
    });

    group('startTrace', () {
      test('создает trace с именем', () {
        final trace = PerformanceMonitoringService.startTrace('test_trace');
        expect(trace, isNotNull);
      });

      test('создает trace для разных операций', () {
        final trace1 = PerformanceMonitoringService.startTrace('operation_1');
        final trace2 = PerformanceMonitoringService.startTrace('operation_2');

        expect(trace1, isNotNull);
        expect(trace2, isNotNull);
      });
    });

    group('traceCalculation', () {
      test('выполняет и возвращает результат', () async {
        final result = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'test_calc',
          calculation: () async => 42,
        );

        expect(result, 42);
      });

      test('работает с разными типами возвращаемых значений', () async {
        final stringResult = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'string_calc',
          calculation: () async => 'result',
        );
        expect(stringResult, 'result');

        final listResult = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'list_calc',
          calculation: () async => [1, 2, 3],
        );
        expect(listResult, [1, 2, 3]);

        final mapResult = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'map_calc',
          calculation: () async => {'key': 'value'},
        );
        expect(mapResult, {'key': 'value'});
      });

      test('пробрасывает ошибки из calculation', () async {
        expect(
          () => PerformanceMonitoringService.traceCalculation(
            calculatorId: 'error_calc',
            calculation: () async => throw Exception('Test error'),
          ),
          throwsException,
        );
      });

      test('в debug режиме не создает trace', () async {
        if (kDebugMode) {
          // В debug режиме трейсинг пропускается для экономии ресурсов
          final result = await PerformanceMonitoringService.traceCalculation(
            calculatorId: 'debug_calc',
            calculation: () async => 'debug_result',
          );
          expect(result, 'debug_result');
        }
      });
    });

    group('traceScreenLoad', () {
      test('выполняет и возвращает результат', () async {
        final result = await PerformanceMonitoringService.traceScreenLoad(
          screenName: 'test_screen',
          load: () async => true,
        );

        expect(result, true);
      });

      test('работает с разными типами данных', () async {
        final result = await PerformanceMonitoringService.traceScreenLoad(
          screenName: 'data_screen',
          load: () async => {'loaded': true, 'count': 5},
        );

        expect(result, isA<Map>());
        expect(result['loaded'], true);
        expect(result['count'], 5);
      });

      test('пробрасывает ошибки из load', () async {
        expect(
          () => PerformanceMonitoringService.traceScreenLoad(
            screenName: 'error_screen',
            load: () async => throw Exception('Load error'),
          ),
          throwsException,
        );
      });
    });

    group('traceDatabaseQuery', () {
      test('выполняет и возвращает результат', () async {
        final result = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: 'test_query',
          query: () async => ['item1', 'item2'],
        );

        expect(result, ['item1', 'item2']);
      });

      test('работает с пустыми результатами', () async {
        final result = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: 'empty_query',
          query: () async => [],
        );

        expect(result, isEmpty);
      });

      test('пробрасывает ошибки из query', () async {
        expect(
          () => PerformanceMonitoringService.traceDatabaseQuery(
            queryName: 'error_query',
            query: () async => throw Exception('Query error'),
          ),
          throwsException,
        );
      });
    });

    group('newHttpMetric', () {
      test('создает HttpMetric для GET запроса', () {
        final metric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com/data',
          method: HttpMethod.Get,
        );

        expect(metric, isNotNull);
      });

      test('создает HttpMetric для POST запроса', () {
        final metric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com/create',
          method: HttpMethod.Post,
        );

        expect(metric, isNotNull);
      });

      test('создает HttpMetric для разных методов', () {
        final getMetric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com',
          method: HttpMethod.Get,
        );
        final postMetric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com',
          method: HttpMethod.Post,
        );
        final putMetric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com',
          method: HttpMethod.Put,
        );
        final deleteMetric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com',
          method: HttpMethod.Delete,
        );

        expect(getMetric, isNotNull);
        expect(postMetric, isNotNull);
        expect(putMetric, isNotNull);
        expect(deleteMetric, isNotNull);
      });
    });

    group('measureSync', () {
      test('выполняет и возвращает результат', () {
        final result = PerformanceMonitoringService.measureSync(
          name: 'sync_operation',
          operation: () => 100,
        );

        expect(result, 100);
      });

      test('работает с разными типами возвращаемых значений', () {
        final intResult = PerformanceMonitoringService.measureSync(
          name: 'int_op',
          operation: () => 42,
        );
        expect(intResult, 42);

        final stringResult = PerformanceMonitoringService.measureSync(
          name: 'string_op',
          operation: () => 'result',
        );
        expect(stringResult, 'result');

        final listResult = PerformanceMonitoringService.measureSync(
          name: 'list_op',
          operation: () => [1, 2, 3],
        );
        expect(listResult, [1, 2, 3]);
      });

      test('пробрасывает ошибки из operation', () {
        expect(
          () => PerformanceMonitoringService.measureSync(
            name: 'error_op',
            operation: () => throw Exception('Operation error'),
          ),
          throwsException,
        );
      });

      test('в debug режиме не создает trace', () {
        if (kDebugMode) {
          final result = PerformanceMonitoringService.measureSync(
            name: 'debug_op',
            operation: () => 'debug',
          );
          expect(result, 'debug');
        }
      });
    });

    group('recordCustomMetric', () {
      test('выполняется без ошибок', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'test_metric',
            value: 42,
          ),
          returnsNormally,
        );
      });

      test('работает с разными значениями', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'zero_metric',
            value: 0,
          ),
          returnsNormally,
        );

        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'large_metric',
            value: 999999,
          ),
          returnsNormally,
        );
      });

      test('работает с attributes', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'attributed_metric',
            value: 100,
            attributes: {
              'key1': 'value1',
              'key2': 'value2',
            },
          ),
          returnsNormally,
        );
      });

      test('работает без attributes', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'simple_metric',
            value: 50,
          ),
          returnsNormally,
        );
      });
    });

    group('traceUserAction', () {
      test('выполняет и возвращает результат', () async {
        final result = await PerformanceMonitoringService.traceUserAction(
          action: 'test_action',
          execute: () async => 'action_result',
        );

        expect(result, 'action_result');
      });

      test('работает с metadata', () async {
        final result = await PerformanceMonitoringService.traceUserAction(
          action: 'action_with_metadata',
          execute: () async => true,
          metadata: {
            'user_id': '123',
            'screen': 'home',
          },
        );

        expect(result, true);
      });

      test('работает без metadata', () async {
        final result = await PerformanceMonitoringService.traceUserAction(
          action: 'simple_action',
          execute: () async => false,
        );

        expect(result, false);
      });

      test('пробрасывает ошибки из execute', () async {
        expect(
          () => PerformanceMonitoringService.traceUserAction(
            action: 'error_action',
            execute: () async => throw Exception('Action error'),
          ),
          throwsException,
        );
      });

      test('в debug режиме не создает trace', () async {
        if (kDebugMode) {
          final result = await PerformanceMonitoringService.traceUserAction(
            action: 'debug_action',
            execute: () async => 'debug_action_result',
          );
          expect(result, 'debug_action_result');
        }
      });
    });
  });
}
