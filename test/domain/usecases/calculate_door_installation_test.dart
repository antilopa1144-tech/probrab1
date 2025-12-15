import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_door_installation.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateDoorInstallation', () {
    test('calculates foam needed correctly', () {
      final calculator = CalculateDoorInstallation();
      final inputs = {
        'doors': 3.0, // 3 двери
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Пена: 1 баллон на дверь
      expect(result.values['foamNeeded'], equals(3.0));
      expect(result.values['doors'], equals(3.0));
    });

    test('calculates architrave length', () {
      final calculator = CalculateDoorInstallation();
      final inputs = {
        'doors': 2.0,
        'doorWidth': 0.9,
        'doorHeight': 2.1,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр: (0.9 + 2.1) * 2 = 6 м
      // Наличники: 6 * 2 = 12 м
      expect(result.values['architraveLength'], closeTo(12.0, 0.6));
    });

    test('calculates frames needed', () {
      final calculator = CalculateDoorInstallation();
      final inputs = {
        'doors': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Коробки: по количеству дверей
      expect(result.values['framesNeeded'], equals(3.0));
    });

    test('calculates hinges needed', () {
      final calculator = CalculateDoorInstallation();
      final inputs = {
        'doors': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Петли: 3 * 2 = 6 шт
      expect(result.values['hingesNeeded'], equals(6.0));
    });

    test('calculates locks needed', () {
      final calculator = CalculateDoorInstallation();
      final inputs = {
        'doors': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Замки: по количеству дверей
      expect(result.values['locksNeeded'], equals(3.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateDoorInstallation();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 дверь, ширина 0.9 м, высота 2.1 м
      expect(result.values['doors'], equals(1.0));
      expect(result.values['foamNeeded'], equals(1.0));
    });

    test('handles zero doors', () {
      final calculator = CalculateDoorInstallation();
      final inputs = {
        'doors': 0.0,
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
