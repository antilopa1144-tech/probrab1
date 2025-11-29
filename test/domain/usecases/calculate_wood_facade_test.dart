import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wood_facade.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWoodFacade', () {
    test('calculates boards needed correctly', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 30.0, // 30 м²
        'boardWidth': 14.0, // 14 см
        'boardLength': 3.0, // 3 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь доски: 0.14 * 3 = 0.42 м²
      // Количество: 30 / 0.42 * 1.1 = ~79 досок
      expect(result.values['boardsNeeded'], greaterThan(75));
      expect(result.values['boardsNeeded'], lessThan(85));
      expect(result.values['area'], equals(30.0));
    });

    test('calculates corners length', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 30.0,
        'perimeter': 25.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Уголки: периметр
      expect(result.values['cornersLength'], equals(25.0));
    });

    test('calculates finish needed', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Лак/масло: 30 * 0.15 * 2.5 = 11.25 л
      expect(result.values['finishNeeded'], equals(11.25));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: количество досок * 8
      final boardsNeeded = result.values['boardsNeeded']!;
      expect(result.values['fastenersNeeded'], equals(boardsNeeded * 8));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['cornersLength'], greaterThan(0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 14 см, длина 3 м
      expect(result.values['boardsNeeded'], greaterThan(0));
    });

    test('handles different board dimensions', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 30.0,
        'boardWidth': 10.0, // 10 см
        'boardLength': 4.0, // 4 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь доски: 0.1 * 4 = 0.4 м²
      // Количество: 30 / 0.4 * 1.1 = ~83 доски
      expect(result.values['boardsNeeded'], greaterThan(80));
      expect(result.values['boardsNeeded'], lessThan(90));
    });

    test('handles zero area', () {
      final calculator = CalculateWoodFacade();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['boardsNeeded'], equals(0.0));
      expect(result.values['finishNeeded'], equals(0.0));
    });
  });
}
