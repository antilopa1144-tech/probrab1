import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallpaper', () {
    late CalculateWallpaper calculator;

    setUp(() {
      calculator = CalculateWallpaper();
    });

    test('calculates rolls needed correctly with 10% reserve', () {
      final inputs = {
        'area': 50.0, // 50 м² стен
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь рулона = 0.53 * 10.05 = 5.3265 м²
      // Количество = ceil(50 / 5.3265 * 1.1) = ceil(10.33) = 11 рулонов
      expect(result.values['rollsNeeded'], greaterThanOrEqualTo(10.0));
      expect(result.values['rollsNeeded'], lessThanOrEqualTo(12.0));
    });

    test('subtracts windows and doors area', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
        'windowsArea': 4.0, // 4 м² окон
        'doorsArea': 4.0, // 4 м² дверей
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь = 50 - 4 - 4 = 42 м²
      expect(result.values['usefulArea'], equals(42.0));
    });

    test('calculates glue needed correctly', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей = 50 * 0.2 = 10 кг
      expect(result.values['glueNeeded'], equals(10.0));
    });

    test('handles rapport correctly', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
        'rapport': 0.64, // 64 см раппорт
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // С раппортом потребуется больше рулонов
      expect(result.values['rollsNeeded'], greaterThan(0));
    });

    test('handles zero area gracefully', () {
      final inputs = {
        'area': 0.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['rollsNeeded'], equals(0.0));
    });

    test('uses default roll dimensions when not provided', () {
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 0.53 x 10.05
      expect(result.values['usefulArea'], equals(50.0));
      expect(result.values['rollsNeeded'], greaterThan(0));
    });

    test('handles wide wallpaper rolls', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 1.06, // метровые обои
        'rollLength': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь рулона = 1.06 * 10 = 10.6 м²
      // Меньше рулонов потребуется
      expect(result.values['rollsNeeded'], lessThan(8));
    });

    test('does not allow negative useful area', () {
      final inputs = {
        'area': 10.0,
        'windowsArea': 20.0, // больше чем общая площадь
        'doorsArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь не может быть отрицательной
      expect(result.values['usefulArea'], equals(0.0));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final priceList = [
        PriceItem()
          ..sku = 'wallpaper'
          ..name = 'Обои'
          ..price = 600
          ..unit = 'рул',
      ];

      final result = calculator(inputs, priceList);

      // rollsNeeded * 600
      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice!, greaterThan(0));
    });

    test('calculates effective roll area', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Эффективная площадь = 0.53 * 10.05 = 5.3265 м²
      expect(result.values['effectiveRollArea'], closeTo(5.3265, 0.01));
    });
  });
}
