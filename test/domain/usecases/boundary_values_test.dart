import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculate_strip_foundation.dart';
import 'package:probrab_ai/domain/usecases/calculate_heating.dart';
import 'package:probrab_ai/domain/usecases/calculate_warm_floor.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';

/// Тесты на граничные значения для калькуляторов.
///
/// Проверяет поведение калькуляторов при:
/// - Нулевых значениях
/// - Отрицательных значениях
/// - Очень больших значениях
/// - Граничных значениях (min/max)
void main() {
  final emptyPriceList = <PriceItem>[];

  group('Граничные значения: Нулевые значения', () {
    test('StripFoundation: периметр = 0', () {
      final calculator = CalculateStripFoundation();
      final inputs = {'perimeter': 0.0, 'width': 0.4, 'height': 0.8};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('Plaster: площадь = 0', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 0.0, 'thickness': 10.0};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('Tile: площадь = 0', () {
      final calculator = CalculateTile();
      final inputs = {'area': 0.0, 'tileWidth': 30.0, 'tileHeight': 30.0};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });

  group('Граничные значения: Отрицательные значения', () {
    test('StripFoundation: отрицательный периметр', () {
      final calculator = CalculateStripFoundation();
      final inputs = {'perimeter': -10.0, 'width': 0.4, 'height': 0.8};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('Plaster: отрицательная площадь', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': -50.0, 'thickness': 10.0};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('Heating: отрицательная площадь', () {
      final calculator = CalculateHeating();
      final inputs = {'area': -100.0, 'rooms': 1.0};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });

  group('Граничные значения: Очень большие значения', () {
    test('StripFoundation: очень большой периметр (1000 м)', () {
      final calculator = CalculateStripFoundation();
      final inputs = {'perimeter': 1000.0, 'width': 0.4, 'height': 0.8};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['concreteVolume'], greaterThan(0));
      expect(result.values['concreteVolume'], lessThan(1e10));
    });

    test('Plaster: очень большая площадь (10000 м²)', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 10000.0, 'thickness': 10.0};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['volume'], greaterThan(0));
      expect(result.values['volume'], lessThan(1e10));
    });

    test('Heating: очень большая площадь (5000 м²)', () {
      final calculator = CalculateHeating();
      final inputs = {'area': 5000.0, 'rooms': 10.0, 'ceilingHeight': 3.0};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['totalPower'], greaterThan(0));
      expect(result.values['totalPower'], lessThan(1e10));
    });
  });

  group('Граничные значения: Минимальные допустимые значения', () {
    test('StripFoundation: минимальный периметр (4 м)', () {
      final calculator = CalculateStripFoundation();
      final inputs = {'perimeter': 4.0, 'width': 0.2, 'height': 0.3};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['concreteVolume'], greaterThan(0));
    });

    test('Plaster: минимальная площадь (0.1 м²)', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 0.1, 'thickness': 5.0};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['volume'], greaterThan(0));
    });

    test('WarmFloor: минимальная площадь (0.1 м²)', () {
      final calculator = CalculateWarmFloor();
      final inputs = {'area': 0.1, 'power': 80.0, 'type': 1.0};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['usefulArea'], greaterThan(0));
    });
  });

  group('Граничные значения: Максимальные допустимые значения', () {
    test('StripFoundation: максимальный периметр (500 м)', () {
      final calculator = CalculateStripFoundation();
      final inputs = {'perimeter': 500.0, 'width': 2.0, 'height': 3.0};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['concreteVolume'], greaterThan(0));
      expect(result.values['concreteVolume'], lessThan(1e10));
    });

    test('Plaster: очень большая толщина (100 мм)', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 100.0, 'thickness': 100.0};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['volume'], greaterThan(0));
      expect(result.values['volume'], lessThan(1e10));
    });
  });

  group('Граничные значения: Специальные случаи', () {
    test('StripFoundation: нулевая ширина', () {
      final calculator = CalculateStripFoundation();
      final inputs = {'perimeter': 50.0, 'width': 0.0, 'height': 0.8};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('Plaster: нулевая толщина', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 50.0, 'thickness': 0.0};

      final result = calculator.call(inputs, emptyPriceList);
      expect(result.values['volume'], equals(0));
    });

    test('Tile: нулевой размер плитки', () {
      final calculator = CalculateTile();
      final inputs = {'area': 50.0, 'tileWidth': 0.0, 'tileHeight': 30.0};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });

  group('Граничные значения: Переполнение', () {
    test(
      'StripFoundation: предотвращение переполнения при очень больших значениях',
      () {
        final calculator = CalculateStripFoundation();
        final inputs = {
          'perimeter': 1e6, // 1 миллион метров
          'width': 1.0,
          'height': 1.0,
        };

        expect(
          () => calculator.call(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      },
    );

    test(
      'Plaster: предотвращение переполнения при очень больших значениях',
      () {
        final calculator = CalculatePlaster();
        final inputs = {
          'area': 1e6, // 1 миллион м²
          'thickness': 100.0,
        };

        expect(
          () => calculator.call(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      },
    );
  });

  group('Граничные значения: NaN и Infinity', () {
    test('StripFoundation: NaN в входных данных', () {
      final calculator = CalculateStripFoundation();
      final inputs = {'perimeter': double.nan, 'width': 0.4, 'height': 0.8};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('Plaster: Infinity в входных данных', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': double.infinity, 'thickness': 10.0};

      expect(
        () => calculator.call(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
