import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wood_wall.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateWoodWall', () {
    test('calculates boards needed correctly', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0, // 25 м²
        'boardWidth': 10.0, // 10 см
        'boardLength': 3.0, // 3 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь доски: 0.1 * 3 = 0.3 м²
      // Количество: 25 / 0.3 * 1.1 = ~92 доски
      expect(result.values['boardsNeeded'], greaterThan(90));
      expect(result.values['boardsNeeded'], lessThan(95));
      expect(result.values['area'], equals(25.0));
    });

    test('calculates plinth length', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0,
        'perimeter': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Плинтус: приблизительно равен периметру
      expect(result.values['plinthLength'], closeTo(20.0, 1.0));
    });

    test('calculates corners length', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0,
        'perimeter': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Уголки: проверяем что рассчитаны
      expect(result.values['cornersLength'], greaterThan(0));
    });

    test('calculates finish needed', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Лак/масло: 25 * 0.1 * 2 = 5 л
      expect(result.values['finishNeeded'], equals(5.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: проверяем что рассчитан и больше нуля
      expect(result.values['fastenersNeeded'], greaterThan(0));
      // Ориентировочно должно быть пропорционально количеству досок
      final boardsNeeded = result.values['boardsNeeded']!;
      expect(result.values['fastenersNeeded'], closeTo(boardsNeeded * 9, boardsNeeded * 2));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['plinthLength'], greaterThan(0));
      expect(result.values['cornersLength'], greaterThan(0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 10 см, длина 3 м
      expect(result.values['boardsNeeded'], greaterThan(0));
    });

    test('handles different board dimensions', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 25.0,
        'boardWidth': 12.0, // 12 см
        'boardLength': 4.0, // 4 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь доски: 0.12 * 4 = 0.48 м²
      // Количество: 25 / 0.48 * 1.1 = ~58 досок
      expect(result.values['boardsNeeded'], greaterThan(55));
      expect(result.values['boardsNeeded'], lessThan(60));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateWoodWall();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
