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
  });
}
