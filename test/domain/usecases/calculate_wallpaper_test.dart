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
        'inputMode': 1.0,
        'area': 50.0, // 50 м? стен
        'rollSize': 1.0, // 0.53×10
        'wallHeight': 2.5,
        'reserve': 5.0, // 5% запас
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Новый алгоритм: периметр ? √(50*4) ? 14.14м  ~27 полос (14.14/0.53)
      // Полос из рулона: 10.05/2.5 = 4 полосы  ~7 рулонов с запасом 5%
      expect(result.values['rollsNeeded'], greaterThanOrEqualTo(7.0));
      expect(result.values['rollsNeeded'], lessThanOrEqualTo(15.0));
    });

    test('subtracts windows and doors area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'rollSize': 1.0, // 0.53×10
        'windowsArea': 4.0, // 4 м? окон
        'doorsArea': 4.0, // 4 м? дверей
        'reserve': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь = 50 - 4 - 4 = 42 м?
      expect(result.values['usefulArea'], closeTo(42.0, 2.1));
    });

    test('calculates glue needed correctly', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'rollSize': 1.0, // 0.53×10
        'reserve': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей (сухая смесь) = 50 м² × 0.008 кг/м² = 0.4 кг = 400 г
      expect(result.values['glueNeeded'], closeTo(0.4, 0.05));
    });

    test('handles rapport correctly', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'rollSize': 1.0, // 0.53×10
        'rapport': 64.0, // 64 см раппорт
        'wallHeight': 2.5,
        'reserve': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // С раппортом потребуется больше рулонов
      expect(result.values['rollsNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 0.0,
        'rollSize': 1.0,
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
        'inputMode': 1.0,
        'area': 50.0,
        'reserve': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: rollSize=1 → 0.53 x 10.05
      expect(result.values['usefulArea'], closeTo(50.0, 2.5));
      expect(result.values['rollsNeeded'], greaterThan(0));
    });

    test('handles wide wallpaper rolls', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'rollSize': 2.0, // 1.06×10 метровые обои
        'reserve': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Широкие обои требуют меньше рулонов
      expect(result.values['rollsNeeded'], lessThanOrEqualTo(15));
    });

    test('returns error for negative useful area', () {
      final inputs = {
        'inputMode': 1.0,
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
        'inputMode': 1.0,
        'area': 50.0,
        'rollWidth': 0.53,
        'rollLength': 10.05,
      };
      final priceList = [
        const PriceItem(
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
        'inputMode': 1.0,
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
