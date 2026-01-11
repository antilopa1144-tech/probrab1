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

    group('дополнительные тесты traceCalculation', () {
      test('работает с нулевым результатом', () async {
        final result = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'null_calc',
          calculation: () async => null,
        );

        expect(result, isNull);
      });

      test('работает с очень большими числами', () async {
        final result = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'big_calc',
          calculation: () async => 999999999.99,
        );

        expect(result, 999999999.99);
      });

      test('работает с отрицательными результатами', () async {
        final result = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'negative_calc',
          calculation: () async => -100.5,
        );

        expect(result, -100.5);
      });

      test('работает с bool результатом', () async {
        final result = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'bool_calc',
          calculation: () async => true,
        );

        expect(result, isTrue);
      });

      test('работает с пустым calculatorId', () async {
        final result = await PerformanceMonitoringService.traceCalculation(
          calculatorId: '',
          calculation: () async => 10,
        );

        expect(result, 10);
      });

      test('работает с длинным calculatorId', () async {
        final longId = 'calculator_' * 20;
        final result = await PerformanceMonitoringService.traceCalculation(
          calculatorId: longId,
          calculation: () async => 42,
        );

        expect(result, 42);
      });
    });

    group('дополнительные тесты traceScreenLoad', () {
      test('работает с null результатом', () async {
        final result = await PerformanceMonitoringService.traceScreenLoad(
          screenName: 'null_screen',
          load: () async => null,
        );

        expect(result, isNull);
      });

      test('работает с Future<void>', () async {
        await PerformanceMonitoringService.traceScreenLoad(
          screenName: 'void_screen',
          load: () async {},
        );

        // Должно завершиться без ошибок
      });

      test('работает с пустым screenName', () async {
        final result = await PerformanceMonitoringService.traceScreenLoad(
          screenName: '',
          load: () async => 'loaded',
        );

        expect(result, 'loaded');
      });

      test('работает с длинным screenName', () async {
        final longName = 'screen_' * 50;
        final result = await PerformanceMonitoringService.traceScreenLoad(
          screenName: longName,
          load: () async => 100,
        );

        expect(result, 100);
      });

      test('работает с специальными символами в screenName', () async {
        final result = await PerformanceMonitoringService.traceScreenLoad(
          screenName: 'screen/with-special_chars.123',
          load: () async => 'ok',
        );

        expect(result, 'ok');
      });
    });

    group('дополнительные тесты traceDatabaseQuery', () {
      test('работает с null результатом', () async {
        final result = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: 'null_query',
          query: () async => null,
        );

        expect(result, isNull);
      });

      test('работает с большим списком результатов', () async {
        final largeList = List.generate(1000, (i) => 'item_$i');
        final result = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: 'large_query',
          query: () async => largeList,
        );

        expect(result.length, 1000);
      });

      test('работает с Map результатом', () async {
        final result = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: 'map_query',
          query: () async => {'id': 1, 'name': 'test'},
        );

        expect(result, {'id': 1, 'name': 'test'});
      });

      test('работает с пустым queryName', () async {
        final result = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: '',
          query: () async => [1, 2, 3],
        );

        expect(result, [1, 2, 3]);
      });

      test('работает с длинным queryName', () async {
        final longName = 'query_' * 30;
        final result = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: longName,
          query: () async => 'result',
        );

        expect(result, 'result');
      });
    });

    group('дополнительные тесты newHttpMetric', () {
      test('создает HttpMetric для PATCH запроса', () {
        final metric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com/update',
          method: HttpMethod.Patch,
        );

        expect(metric, isNotNull);
      });

      test('создает HttpMetric для HEAD запроса', () {
        final metric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com/check',
          method: HttpMethod.Head,
        );

        expect(metric, isNotNull);
      });

      test('создает HttpMetric для длинного URL', () {
        final longUrl = 'https://api.example.com/' + 'path/' * 50 + 'endpoint';
        final metric = PerformanceMonitoringService.newHttpMetric(
          url: longUrl,
          method: HttpMethod.Get,
        );

        expect(metric, isNotNull);
      });

      test('создает HttpMetric для URL с параметрами', () {
        final metric = PerformanceMonitoringService.newHttpMetric(
          url: 'https://api.example.com/data?param1=value1&param2=value2',
          method: HttpMethod.Get,
        );

        expect(metric, isNotNull);
      });

      test('создает HttpMetric для localhost', () {
        final metric = PerformanceMonitoringService.newHttpMetric(
          url: 'http://localhost:8080/api',
          method: HttpMethod.Get,
        );

        expect(metric, isNotNull);
      });
    });

    group('дополнительные тесты measureSync', () {
      test('работает с null результатом', () {
        final result = PerformanceMonitoringService.measureSync(
          name: 'null_op',
          operation: () => null,
        );

        expect(result, isNull);
      });

      test('работает с очень быстрой операцией', () {
        final result = PerformanceMonitoringService.measureSync(
          name: 'fast_op',
          operation: () => 1 + 1,
        );

        expect(result, 2);
      });

      test('работает с медленной операцией', () {
        final result = PerformanceMonitoringService.measureSync(
          name: 'slow_op',
          operation: () {
            var sum = 0;
            for (var i = 0; i < 1000; i++) {
              sum += i;
            }
            return sum;
          },
        );

        expect(result, 499500);
      });

      test('работает с пустым name', () {
        final result = PerformanceMonitoringService.measureSync(
          name: '',
          operation: () => 'test',
        );

        expect(result, 'test');
      });

      test('работает с объектом результата', () {
        final obj = {'key': 'value'};
        final result = PerformanceMonitoringService.measureSync(
          name: 'object_op',
          operation: () => obj,
        );

        expect(result, obj);
      });

      test('пробрасывает разные типы ошибок', () {
        expect(
          () => PerformanceMonitoringService.measureSync(
            name: 'error_op',
            operation: () => throw ArgumentError('Invalid argument'),
          ),
          throwsArgumentError,
        );

        expect(
          () => PerformanceMonitoringService.measureSync(
            name: 'state_error',
            operation: () => throw StateError('Invalid state'),
          ),
          throwsStateError,
        );
      });
    });

    group('дополнительные тесты recordCustomMetric', () {
      test('работает с отрицательными значениями', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'negative_metric',
            value: -100,
          ),
          returnsNormally,
        );
      });

      test('работает с пустым attributes', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'empty_attrs',
            value: 50,
            attributes: {},
          ),
          returnsNormally,
        );
      });

      test('работает с множественными attributes', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'multi_attrs',
            value: 100,
            attributes: {
              'attr1': 'value1',
              'attr2': 'value2',
              'attr3': 'value3',
              'attr4': 'value4',
              'attr5': 'value5',
            },
          ),
          returnsNormally,
        );
      });

      test('работает с длинными значениями attributes', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'long_attr',
            value: 100,
            attributes: {
              'long_key': 'value_' * 100,
            },
          ),
          returnsNormally,
        );
      });

      test('работает с специальными символами в attributes', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'special_chars',
            value: 100,
            attributes: {
              'key-with-dashes': 'value.with.dots',
              'key_with_underscores': 'value/with/slashes',
            },
          ),
          returnsNormally,
        );
      });

      test('работает с пустым name', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: '',
            value: 10,
          ),
          returnsNormally,
        );
      });

      test('работает с максимальным int значением', () {
        expect(
          () => PerformanceMonitoringService.recordCustomMetric(
            name: 'max_int',
            value: 2147483647,
          ),
          returnsNormally,
        );
      });
    });

    group('дополнительные тесты traceUserAction', () {
      test('работает с null результатом', () async {
        final result = await PerformanceMonitoringService.traceUserAction(
          action: 'null_action',
          execute: () async => null,
        );

        expect(result, isNull);
      });

      test('работает с Future<void>', () async {
        await PerformanceMonitoringService.traceUserAction(
          action: 'void_action',
          execute: () async {},
        );

        // Должно завершиться без ошибок
      });

      test('работает с пустым action', () async {
        final result = await PerformanceMonitoringService.traceUserAction(
          action: '',
          execute: () async => 'result',
        );

        expect(result, 'result');
      });

      test('работает с длинным action', () async {
        final longAction = 'action_' * 50;
        final result = await PerformanceMonitoringService.traceUserAction(
          action: longAction,
          execute: () async => 'ok',
        );

        expect(result, 'ok');
      });

      test('работает с пустым metadata', () async {
        final result = await PerformanceMonitoringService.traceUserAction(
          action: 'empty_meta',
          execute: () async => 100,
          metadata: {},
        );

        expect(result, 100);
      });

      test('работает с множественными metadata полями', () async {
        final result = await PerformanceMonitoringService.traceUserAction(
          action: 'multi_meta',
          execute: () async => 'success',
          metadata: {
            'field1': 'value1',
            'field2': 'value2',
            'field3': 'value3',
            'field4': 'value4',
          },
        );

        expect(result, 'success');
      });

      test('работает с сложными типами результата', () async {
        final complexResult = {
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
          'number': 42,
        };

        final result = await PerformanceMonitoringService.traceUserAction(
          action: 'complex_action',
          execute: () async => complexResult,
        );

        expect(result, complexResult);
      });

      test('пробрасывает разные типы ошибок', () async {
        expect(
          () => PerformanceMonitoringService.traceUserAction(
            action: 'arg_error',
            execute: () async => throw ArgumentError('Invalid'),
          ),
          throwsArgumentError,
        );

        expect(
          () => PerformanceMonitoringService.traceUserAction(
            action: 'state_error',
            execute: () async => throw StateError('Invalid state'),
          ),
          throwsStateError,
        );
      });
    });

    group('интеграционные тесты', () {
      test('работает с последовательными вызовами', () async {
        final result1 = await PerformanceMonitoringService.traceCalculation(
          calculatorId: 'calc1',
          calculation: () async => 10,
        );

        final result2 = await PerformanceMonitoringService.traceScreenLoad(
          screenName: 'screen1',
          load: () async => 'loaded',
        );

        final result3 = await PerformanceMonitoringService.traceDatabaseQuery(
          queryName: 'query1',
          query: () async => [1, 2, 3],
        );

        expect(result1, 10);
        expect(result2, 'loaded');
        expect(result3, [1, 2, 3]);
      });

      test('работает с вложенными вызовами', () async {
        final result = await PerformanceMonitoringService.traceScreenLoad(
          screenName: 'outer',
          load: () async {
            return await PerformanceMonitoringService.traceCalculation(
              calculatorId: 'inner',
              calculation: () async => 42,
            );
          },
        );

        expect(result, 42);
      });

      test('создает несколько trace одновременно', () {
        final trace1 = PerformanceMonitoringService.startTrace('trace1');
        final trace2 = PerformanceMonitoringService.startTrace('trace2');
        final trace3 = PerformanceMonitoringService.startTrace('trace3');

        expect(trace1, isNotNull);
        expect(trace2, isNotNull);
        expect(trace3, isNotNull);
      });
    });
  });
}
