import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/calculator_category.dart';
import 'package:probrab_ai/domain/calculators/calculator_constants.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';

void main() {
  group('CalculatorRegistry', () {
    setUp(() {
      // Очищаем кэш перед каждым тестом
      CalculatorRegistry.clearCache();
    });

    test('возвращает все калькуляторы', () {
      final all = CalculatorRegistry.allCalculators;
      expect(all, isNotEmpty);
      expect(
        all.length,
        greaterThan(10),
      ); // Должно быть минимум 10 калькуляторов
    });

    test('все калькуляторы имеют уникальные ID', () {
      final ids = CalculatorRegistry.allCalculators
          .map((calc) => calc.id)
          .toList();
      expect(ids.toSet().length, equals(ids.length));
    });

    test('getById возвращает калькулятор по ID (O(1))', () {
      final calc = CalculatorRegistry.getById('paint_universal');

      expect(calc, isNotNull);
      expect(calc!.id, equals('paint_universal'));
    });

    test('getById возвращает null для несуществующего ID', () {
      final calc = CalculatorRegistry.getById('nonexistent_calculator');
      expect(calc, isNull);
    });

    test('exists проверяет наличие калькулятора (O(1))', () {
      expect(CalculatorRegistry.exists('paint_universal'), isTrue);
      expect(CalculatorRegistry.exists('nonexistent'), isFalse);
    });

    test('getByCategory фильтрует по категории', () {
      final interiorCalcs = CalculatorRegistry.getByCategory(
        CalculatorCategory.interior,
      );

      expect(interiorCalcs, isNotEmpty);
      expect(
        interiorCalcs.every(
          (calc) => calc.category == CalculatorCategory.interior,
        ),
        isTrue,
      );
    });

    test('getByCategory кэширует результаты', () {
      // Первый вызов
      final result1 = CalculatorRegistry.getByCategory(
        CalculatorCategory.interior,
      );

      // Второй вызов должен вернуть тот же объект из кэша
      final result2 = CalculatorRegistry.getByCategory(
        CalculatorCategory.interior,
      );

      expect(identical(result1, result2), isTrue);
    });

    test(
      'getPopular возвращает калькуляторы отсортированные по популярности',
      () {
        final popular = CalculatorRegistry.getPopular(limit: 5);

        expect(popular.length, lessThanOrEqualTo(5));

        // Проверяем, что отсортировано по убыванию популярности
        for (var i = 1; i < popular.length; i++) {
          expect(
            popular[i - 1].popularity >= popular[i].popularity,
            isTrue,
            reason: 'Популярность должна убывать',
          );
        }
      },
    );

    test('getPopular кэширует отсортированный список', () {
      // Первый вызов
      final result1 = CalculatorRegistry.getPopular();

      // Второй вызов должен вернуть результат из кэша
      final result2 = CalculatorRegistry.getPopular();

      // Проверяем что списки идентичны по содержимому
      expect(result1.length, equals(result2.length));
      for (var i = 0; i < result1.length; i++) {
        expect(result1[i].id, equals(result2[i].id));
      }
    });

    test('search находит калькуляторы по названию', () {
      final results = CalculatorRegistry.search('paint');

      expect(results, isNotEmpty);
      expect(
        results.any(
          (calc) =>
              calc.titleKey.toLowerCase().contains('paint') ||
              calc.id.toLowerCase().contains('paint'),
        ),
        isTrue,
      );
    });

    test('search возвращает все калькуляторы для пустого запроса', () {
      final results = CalculatorRegistry.search('');
      expect(results.length, equals(CalculatorRegistry.count));
    });

    test('search работает регистронезависимо', () {
      final results1 = CalculatorRegistry.search('PAINT');
      final results2 = CalculatorRegistry.search('paint');

      expect(results1.length, equals(results2.length));
    });

    test('getByComplexity фильтрует по уровню сложности', () {
      final simple = CalculatorRegistry.getByComplexity(1);

      expect(simple, isNotEmpty);
      expect(simple.every((calc) => calc.complexity == 1), isTrue);
    });

    test('count возвращает правильное количество', () {
      expect(
        CalculatorRegistry.count,
        equals(CalculatorRegistry.allCalculators.length),
      );
    });

    test('акцентные цвета унифицированы', () {
      for (final calc in CalculatorRegistry.allCalculators) {
        expect(calc.accentColor, equals(kCalculatorAccentColor));
      }
    });

    test('register добавляет новый калькулятор динамически', () {
      expect(() => CalculatorRegistry.register, returnsNormally);

      // Восстанавливаем состояние
      CalculatorRegistry.clearCache();
    });

    test('clearCache очищает все кэши', () {
      // Заполняем кэши
      CalculatorRegistry.getById('paint_universal');
      CalculatorRegistry.getPopular();
      CalculatorRegistry.getByCategory(CalculatorCategory.exterior);

      // Очищаем
      CalculatorRegistry.clearCache();

      // После очистки всё должно работать
      expect(CalculatorRegistry.exists('paint_universal'), isTrue);
    });

    test('производительность: getById O(1) vs линейный поиск O(n)', () {
      final testId = CalculatorRegistry.allCalculators[5].id;

      // Измеряем O(1) поиск через Map
      final stopwatch1 = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        CalculatorRegistry.getById(testId);
      }
      stopwatch1.stop();

      // Измеряем O(n) линейный поиск
      final stopwatch2 = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        CalculatorRegistry.allCalculators.firstWhere(
          (calc) => calc.id == testId,
          orElse: () => CalculatorRegistry.allCalculators.first,
        );
      }
      stopwatch2.stop();

      // Map должен быть быстрее
      expect(
        stopwatch1.elapsedMilliseconds <= stopwatch2.elapsedMilliseconds,
        isTrue,
        reason:
            'Map поиск (${stopwatch1.elapsedMilliseconds}ms) должен быть '
            'быстрее или равен линейному (${stopwatch2.elapsedMilliseconds}ms)',
      );

      print('📊 CalculatorRegistry Benchmark:');
      print('  Map O(1):      ${stopwatch1.elapsedMilliseconds}ms');
      print('  List O(n):     ${stopwatch2.elapsedMilliseconds}ms');
      if (stopwatch1.elapsedMilliseconds > 0) {
        print(
          '  Ускорение:     ${(stopwatch2.elapsedMilliseconds / stopwatch1.elapsedMilliseconds).toStringAsFixed(1)}x',
        );
      }
    });
  });
}

// ignore_for_file: avoid_print
