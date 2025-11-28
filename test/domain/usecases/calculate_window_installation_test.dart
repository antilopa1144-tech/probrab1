import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_window_installation.dart';
import 'package:probrab_ai/data/models/price_item.dart';

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

      // Пена: 1 баллон на окно
      expect(result.values['foamNeeded'], equals(3.0));
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
      // Длина подоконников: 1.5 * 2 = 3 м
      expect(result.values['sillLength'], equals(3.0));
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
      // Площадь откосов: 5.8 * 0.3 * 2 = 3.48 м²
      expect(result.values['slopeArea'], closeTo(3.48, 0.1));
    });

    test('calculates drip length', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 2.0,
        'windowWidth': 1.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Отливы: 1.5 * 2 = 3 м
      expect(result.values['dripLength'], equals(3.0));
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

    test('handles zero windows', () {
      final calculator = CalculateWindowInstallation();
      final inputs = {
        'windows': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['foamNeeded'], equals(0.0));
      expect(result.values['sillsNeeded'], equals(0.0));
    });
  });
}
