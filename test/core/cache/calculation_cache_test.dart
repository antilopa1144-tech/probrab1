import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/cache/calculation_cache.dart';

void main() {
  group('CalculationCache', () {
    late CalculationCache cache;

    setUp(() {
      cache = CalculationCache();
      cache.clear();
    });

    test('stores and retrieves values correctly', () {
      final inputs = {'area': 20.0, 'height': 2.5};
      final result = {'tilesNeeded': 100.0, 'glueNeeded': 80.0};

      cache.set('test_calculator', inputs, result);
      final cached = cache.get('test_calculator', inputs);

      expect(cached, isNotNull);
      expect(cached!['tilesNeeded'], equals(100.0));
      expect(cached['glueNeeded'], equals(80.0));
    });

    test('returns null for missing entries', () {
      final inputs = {'area': 20.0};
      final cached = cache.get('nonexistent_calculator', inputs);

      expect(cached, isNull);
    });

    test('differentiates by calculator id', () {
      final inputs = {'area': 20.0};
      final result1 = {'tilesNeeded': 100.0};
      final result2 = {'packsNeeded': 10.0};

      cache.set('calculator_1', inputs, result1);
      cache.set('calculator_2', inputs, result2);

      final cached1 = cache.get('calculator_1', inputs);
      final cached2 = cache.get('calculator_2', inputs);

      expect(cached1!['tilesNeeded'], equals(100.0));
      expect(cached2!['packsNeeded'], equals(10.0));
    });

    test('differentiates by inputs', () {
      const calculatorId = 'tile_calc';
      final inputs1 = {'area': 20.0};
      final inputs2 = {'area': 30.0};
      final result1 = {'tilesNeeded': 100.0};
      final result2 = {'tilesNeeded': 150.0};

      cache.set(calculatorId, inputs1, result1);
      cache.set(calculatorId, inputs2, result2);

      final cached1 = cache.get(calculatorId, inputs1);
      final cached2 = cache.get(calculatorId, inputs2);

      expect(cached1!['tilesNeeded'], equals(100.0));
      expect(cached2!['tilesNeeded'], equals(150.0));
    });

    test('clears cache for specific calculator', () {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      cache.set('calculator_1', inputs, result);
      cache.set('calculator_2', inputs, result);

      cache.clearForCalculator('calculator_1');

      expect(cache.get('calculator_1', inputs), isNull);
      expect(cache.get('calculator_2', inputs), isNotNull);
    });

    test('clears all cache', () {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      cache.set('calculator_1', inputs, result);
      cache.set('calculator_2', inputs, result);

      cache.clear();

      expect(cache.get('calculator_1', inputs), isNull);
      expect(cache.get('calculator_2', inputs), isNull);
    });

    test('returns correct stats', () {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      cache.set('calc_1', inputs, result);
      cache.set('calc_2', inputs, result);
      cache.set('calc_3', inputs, result);

      final stats = cache.getStats();

      expect(stats.totalEntries, equals(3));
      expect(stats.validEntries, equals(3));
      expect(stats.expiredEntries, equals(0));
    });

    test('handles input order correctly', () {
      final inputs1 = {'area': 20.0, 'height': 2.5};
      final inputs2 = {'height': 2.5, 'area': 20.0}; // разный порядок
      final result = {'tilesNeeded': 100.0};

      cache.set('test_calc', inputs1, result);
      
      // Должен найти, т.к. ключи сортируются
      final cached = cache.get('test_calc', inputs2);
      expect(cached, isNotNull);
    });

    test('handles complex inputs', () {
      final inputs = {
        'area': 123.456,
        'thickness': 50.0,
        'layers': 2.0,
        'windowsArea': 4.5,
        'doorsArea': 2.1,
      };
      final result = {'materialNeeded': 500.0, 'cost': 25000.0};

      cache.set('complex_calc', inputs, result);
      final cached = cache.get('complex_calc', inputs);

      expect(cached, isNotNull);
      expect(cached!['materialNeeded'], equals(500.0));
      expect(cached['cost'], equals(25000.0));
    });

    test('returns copy of cached values, not reference', () {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      cache.set('test_calc', inputs, result);
      final cached = cache.get('test_calc', inputs);

      // Модифицируем полученный результат
      cached!['tilesNeeded'] = 999.0;

      // Проверяем, что оригинал в кэше не изменился
      final cachedAgain = cache.get('test_calc', inputs);
      expect(cachedAgain!['tilesNeeded'], equals(100.0));
    });

    test('evicts oldest entry when cache exceeds max size', () {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      // Заполняем кэш до максимума (50 записей)
      for (int i = 0; i < 50; i++) {
        cache.set('calculator_$i', inputs, result);
      }

      final stats = cache.getStats();
      expect(stats.totalEntries, equals(50));

      // Добавляем ещё одну запись - должна удалиться самая старая
      cache.set('calculator_new', inputs, result);

      final statsAfter = cache.getStats();
      expect(statsAfter.totalEntries, equals(50)); // Размер не увеличился

      // Проверяем, что первая запись удалена
      expect(cache.get('calculator_0', inputs), isNull);

      // Но новая запись есть
      expect(cache.get('calculator_new', inputs), isNotNull);
    });

    test('handles empty cache when evicting', () {
      // Вызываем cleanupExpired на пустом кэше - не должно упасть
      expect(() => cache.cleanupExpired(), returnsNormally);

      final stats = cache.getStats();
      expect(stats.totalEntries, equals(0));
    });

    test('cleanupExpired removes only expired entries', () async {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      // Добавляем записи
      cache.set('calc_1', inputs, result);
      cache.set('calc_2', inputs, result);
      cache.set('calc_3', inputs, result);

      // Проверяем, что все записи валидны
      var stats = cache.getStats();
      expect(stats.validEntries, equals(3));
      expect(stats.expiredEntries, equals(0));

      // Вызываем cleanup - ничего не должно удалиться
      cache.cleanupExpired();

      stats = cache.getStats();
      expect(stats.totalEntries, equals(3));
    });

    test('getStats calculates utilization percent correctly', () {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      // Добавляем 10 записей (20% от максимума 50)
      for (int i = 0; i < 10; i++) {
        cache.set('calc_$i', inputs, result);
      }

      final stats = cache.getStats();
      expect(stats.utilizationPercent, equals(20.0));
      expect(stats.maxSize, equals(50));
    });

    test('getStats toString returns formatted string', () {
      final inputs = {'area': 20.0};
      final result = {'tilesNeeded': 100.0};

      cache.set('calc_1', inputs, result);
      cache.set('calc_2', inputs, result);

      final stats = cache.getStats();
      final statsString = stats.toString();

      expect(statsString, contains('CacheStats'));
      expect(statsString, contains('total: 2'));
      expect(statsString, contains('valid: 2'));
      expect(statsString, contains('expired: 0'));
      expect(statsString, contains('maxSize: 50'));
      expect(statsString, contains('utilization:'));
    });

    test('singleton pattern returns same instance', () {
      final cache1 = CalculationCache();
      final cache2 = CalculationCache();

      expect(identical(cache1, cache2), isTrue);
    });

    test('cache key generation is deterministic', () {
      final inputs1 = {'a': 1.0, 'b': 2.0, 'c': 3.0};
      final inputs2 = {'c': 3.0, 'a': 1.0, 'b': 2.0}; // Другой порядок
      final result = {'output': 100.0};

      cache.set('test', inputs1, result);

      // Должны получить тот же результат с другим порядком ключей
      final cached = cache.get('test', inputs2);
      expect(cached, isNotNull);
      expect(cached!['output'], equals(100.0));
    });

    test('clearForCalculator removes only matching calculator entries', () {
      final inputs = {'area': 20.0};
      final result = {'value': 100.0};

      // Создаём записи для разных калькуляторов
      cache.set('tile_calc', inputs, result);
      cache.set('tile_calculator', inputs, result);
      cache.set('brick_calc', inputs, result);

      // Удаляем только те, что начинаются с 'tile_calc'
      cache.clearForCalculator('tile_calc');

      // tile_calc должен быть удалён
      expect(cache.get('tile_calc', inputs), isNull);

      // tile_calculator НЕ должен быть удалён (не точное совпадение префикса)
      expect(cache.get('tile_calculator', inputs), isNotNull);

      // brick_calc должен остаться
      expect(cache.get('brick_calc', inputs), isNotNull);
    });

    test('handles numeric precision in inputs', () {
      final inputs1 = {'value': 1.0 / 3.0}; // 0.333333...
      final inputs2 = {'value': 1.0 / 3.0};
      final result = {'output': 50.0};

      cache.set('precision_test', inputs1, result);

      // Должно работать с одинаковой точностью
      final cached = cache.get('precision_test', inputs2);
      expect(cached, isNotNull);
      expect(cached!['output'], equals(50.0));
    });

    test('handles empty input map', () {
      final emptyInputs = <String, double>{};
      final result = {'default': 1.0};

      cache.set('empty_test', emptyInputs, result);

      final cached = cache.get('empty_test', emptyInputs);
      expect(cached, isNotNull);
      expect(cached!['default'], equals(1.0));
    });

    test('handles empty result map', () {
      final inputs = {'value': 1.0};
      final emptyResult = <String, double>{};

      cache.set('empty_result', inputs, emptyResult);

      final cached = cache.get('empty_result', inputs);
      expect(cached, isNotNull);
      expect(cached!.isEmpty, isTrue);
    });

    test('multiple calculators with overlapping input keys', () {
      final inputs = {'width': 10.0, 'height': 20.0};
      final result1 = {'area': 200.0};
      final result2 = {'perimeter': 60.0};

      cache.set('area_calc', inputs, result1);
      cache.set('perimeter_calc', inputs, result2);

      final cached1 = cache.get('area_calc', inputs);
      final cached2 = cache.get('perimeter_calc', inputs);

      expect(cached1!['area'], equals(200.0));
      expect(cached2!['perimeter'], equals(60.0));
      expect(cached1.containsKey('perimeter'), isFalse);
      expect(cached2.containsKey('area'), isFalse);
    });

    test('cache size limit is respected across different calculators', () {
      final inputs = {'value': 1.0};
      final result = {'output': 1.0};

      // Заполняем кэш разными калькуляторами
      for (int i = 0; i < 60; i++) {
        cache.set('calc_$i', inputs, result);
      }

      final stats = cache.getStats();
      // Размер не должен превышать 50
      expect(stats.totalEntries, equals(50));
    });
  });
}
