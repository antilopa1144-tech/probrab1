import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallpaper', () {
    test('calculates rolls needed correctly', () {
      final calculator = CalculateWallpaper();
      final inputs = {
        'area': 50.0, // 50 м²
        'rollWidth': 0.53, // стандартная ширина
        'rollLength': 10.05, // стандартная длина
        'wallHeight': 2.5, // высота стен
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь рулона: 0.53 * 10.05 = ~5.3 м²
      // Количество: 50 / 5.3 * 1.1 = ~11 рулонов
      expect(result.values['rollsNeeded'], greaterThan(8));
      expect(result.values['rollsNeeded'], lessThan(15));
      expect(result.values['usefulArea'], equals(50.0));
    });

    test('subtracts windows and doors area', () {
      final calculator = CalculateWallpaper();
      final inputs = {
        'area': 50.0,
        'windowsArea': 5.0,
        'doorsArea': 2.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь: 50 - 5 - 2 = 43 м²
      expect(result.values['usefulArea'], equals(43.0));
      expect(result.values['rollsNeeded'], greaterThan(7));
    });

    test('calculates glue needed', () {
      final calculator = CalculateWallpaper();
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 50 м² * 0.2 кг/м² = 10 кг
      expect(result.values['glueNeeded'], equals(10.0));
    });

    test('handles rapport correctly', () {
      final calculator = CalculateWallpaper();
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
        'rapport': 0.5, // раппорт 50 см
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // С раппортом нужно больше рулонов
      expect(result.values['rollsNeeded'], greaterThan(0));
      expect(result.values['effectiveRollArea'], lessThanOrEqualTo(0.53 * 10.05));
    });

    test('handles zero area', () {
      final calculator = CalculateWallpaper();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['rollsNeeded'], equals(0.0));
      expect(result.values['glueNeeded'], equals(0.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWallpaper();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 0.53, длина 10.05, высота 2.5
      expect(result.values['rollsNeeded'], greaterThan(0));
      expect(result.values['effectiveRollArea'], greaterThan(0));
    });

    test('handles negative useful area', () {
      final calculator = CalculateWallpaper();
      final inputs = {
        'area': 10.0,
        'windowsArea': 15.0, // больше общей площади
        'doorsArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь должна быть >= 0
      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['rollsNeeded'], equals(0.0));
    });
  });
}
