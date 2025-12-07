import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallpaper', () {
    late CalculateWallpaper calculator;

    setUp(() {
      calculator = CalculateWallpaper();
    });

    test('calculates rolls needed correctly with 5% reserve', () {
      final inputs = {
        'area': 50.0, // 50 м² стен
        'rollWidth': 0.53,
        'rollLength': 10.05,
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Новый алгоритм: периметр ≈ √(50*4) ≈ 14.14м → ~27 полос (14.14/0.53)
      // Полос из рулона: 10.05/2.5 = 4 полосы → ~7 рулонов с запасом 5%
      expect(result.values['rollsNeeded'], greaterThanOrEqualTo(7.0));
      expect(result.values['rollsNeeded'], lessThanOrEqualTo(15.0));
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

      // Клей = 50 * 0.22 = 11 кг
      expect(result.values['glueNeeded'], equals(11.0));
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

    test('throws exception for zero area', () {
      final inputs = {
        'area': 0.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final emptyPriceList = <PriceItem>[];

      // Калькулятор должен выбросить исключение при area <= 0
      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<Exception>()),
      );
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

      // Широкие обои требуют меньше рулонов
      expect(result.values['rollsNeeded'], lessThanOrEqualTo(8));
    });

    test('returns error for negative useful area', () {
      final inputs = {
        'area': 10.0,
        'windowsArea': 20.0, // больше, чем общая площадь
        'doorsArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Калькулятор возвращает ошибку при отрицательной полезной площади
      expect(result.values['error'], equals(1.0));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final priceList = [
        PriceItem(
          sku: 'wallpaper',
          name: 'Обои',
          price: 600,
          unit: 'рул',
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      // rollsNeeded * 600
      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));
    });

    test('calculates strip length and strips needed', () {
      final inputs = {
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Длина полосы = высота стен (без раппорта)
      expect(result.values['stripLength'], equals(2.5));
      // Количество полос должно быть больше 0
      expect(result.values['stripsNeeded'], greaterThan(0));
    });
  });
}
