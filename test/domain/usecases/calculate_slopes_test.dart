import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_slopes.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateSlopes', () {
    test('calculates slope area correctly', () {
      final calculator = CalculateSlopes();
      final inputs = {
        'windows': 2.0, // 2 окна
        'windowWidth': 1.5, // 1.5 м
        'windowHeight': 1.4, // 1.4 м
        'slopeWidth': 0.3, // 0.3 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр: (1.5 + 1.4) * 2 = 5.8 м
      // Площадь: 5.8 * 0.3 * 2 = 3.48 м²
      expect(result.values['slopeArea'], closeTo(3.48, 0.1));
      expect(result.values['windows'], equals(2.0));
    });

    test('calculates putty needed', () {
      final calculator = CalculateSlopes();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
        'windowHeight': 1.4,
        'slopeWidth': 0.3,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Шпаклёвка: 3.48 * 1.5 = 5.22 кг
      expect(result.values['puttyNeeded'], closeTo(5.22, 0.1));
    });

    test('calculates primer needed', () {
      final calculator = CalculateSlopes();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
        'windowHeight': 1.4,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: площадь * 0.2
      final slopeArea = result.values['slopeArea']!;
      expect(result.values['primerNeeded'], closeTo(slopeArea * 0.2, 0.1));
    });

    test('calculates paint needed', () {
      final calculator = CalculateSlopes();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
        'windowHeight': 1.4,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска: площадь * 0.12 * 2 = площадь * 0.24
      final slopeArea = result.values['slopeArea']!;
      expect(result.values['paintNeeded'], closeTo(slopeArea * 0.24, 0.1));
    });

    test('calculates corner length', () {
      final calculator = CalculateSlopes();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
        'windowHeight': 1.4,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр: 5.8 м
      // Уголки: 5.8 * 2 = 11.6 м
      expect(result.values['cornerLength'], closeTo(11.6, 0.1));
    });

    test('uses default values when missing', () {
      final calculator = CalculateSlopes();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 окно, ширина 1.5 м, высота 1.4 м, ширина откоса 0.3 м
      expect(result.values['windows'], equals(1.0));
      expect(result.values['slopeArea'], greaterThan(0));
    });

    test('handles zero windows', () {
      final calculator = CalculateSlopes();
      final inputs = {
        'windows': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      // Должно выбрасываться исключение для нулевого количества
      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
