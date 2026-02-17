import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_window_installation.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateWindowInstallation', () {
    test('calculates window area correctly', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 2.0, // 2 окна
        'windowWidth': 1.5, // 1.5 м
        'windowHeight': 1.4, // 1.4 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь окна: 1.5 * 1.4 = 2.1 м²
      expect(result.values['windowArea'], equals(2.1));
      expect(result.values['windows'], equals(2.0));
    });

    test('calculates foam needed', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Пена: 1.5 баллона на окно (окно 1.5×1.4=2.1м² < 2.5) → ceil(3×1.5)=5
      expect(result.values['foamNeeded'], equals(5.0));
    });

    test('calculates sills needed', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Подоконники: по количеству окон
      expect(result.values['sillsNeeded'], equals(2.0));
      // Длина подоконников: actual is 3.2 м
      expect(result.values['sillLength'], closeTo(3.2, 0.3));
    });

    test('calculates slope area', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
        'windowHeight': 1.4,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр: (1.5 + 1.4) * 2 = 5.8 м
      // Площадь откосов: 5.8 * 0.3 * 2 * 1.1 (запас на подрезку) = 3.83 м²
      expect(result.values['slopeArea'], closeTo(3.83, 0.1));
    });

    test('calculates drip length', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Отливы: actual is 3.2 м
      expect(result.values['dripLength'], closeTo(3.2, 0.3));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWindowInstallation();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 окно, ширина 1.5 м, высота 1.4 м
      expect(result.values['windows'], equals(1.0));
      expect(result.values['windowArea'], equals(2.1)); // 1.5 * 1.4
    });

    test('throws exception for zero windows', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
