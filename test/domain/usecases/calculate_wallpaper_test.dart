import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallpaper', () {
    late CalculateWallpaper calculator;

    setUp(() {
      calculator = CalculateWallpaper();
    });

    // ================================================================
    // Existing tests (updated for new paste/primer formulas)
    // ================================================================

    test('calculates rolls needed correctly (no reserve)', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0, // 50 м² стен
        'rollSize': 1.0, // 0.53×10
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр = area / wallHeight = 50 / 2.5 = 20 м
      // Полос = ceil(20 / 0.53) = 38
      // Полос из рулона: floor(10.05 / 2.5) = 4
      // Рулонов = ceil(38 / 4) = 10
      expect(result.values['rollsNeeded'], closeTo(10.0, 1.0));
    });

    test('subtracts windows and doors area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'rollSize': 1.0, // 0.53×10
        'windowsArea': 4.0, // 4 м² окон
        'doorsArea': 4.0, // 4 м² дверей
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь = 50 - 4 - 4 = 42 м²
      expect(result.values['usefulArea'], closeTo(42.0, 2.1));
    });

    test('calculates paste (glueNeeded) for default paper type', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'rollSize': 1.0, // 0.53×10
        'wallpaperType': 1.0, // бумажные
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Бумажные: 50 м² × 0.005 кг/м² × 1.1 = 0.275 кг → rounded to 0.28
      expect(result.values['glueNeeded'], closeTo(0.28, 0.01));
      // pasteNeeded should match glueNeeded (backward compat)
      expect(result.values['pasteNeeded'], result.values['glueNeeded']);
    });

    test('handles rapport correctly', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'rollSize': 1.0, // 0.53×10
        'rapport': 64.0, // 64 см раппорт
        'wallHeight': 2.5,
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

    // ================================================================
    // New tests: wallpaper types affect paste consumption
    // ================================================================

    group('Wallpaper type — paste consumption rate', () {
      test('paper (type 1) uses lowest paste rate: 0.005 kg/m²', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 100.0,
          'rollSize': 1.0,
          'wallpaperType': 1.0, // бумажные
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 100 × 0.005 × 1.1 = 0.55 кг
        expect(result.values['pasteNeeded'], closeTo(0.55, 0.01));
        expect(result.values['wallpaperType'], equals(1.0));
      });

      test('vinyl (type 2) uses highest paste rate: 0.010 kg/m²', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 100.0,
          'rollSize': 1.0,
          'wallpaperType': 2.0, // виниловые
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 100 × 0.010 × 1.1 = 1.1 кг
        expect(result.values['pasteNeeded'], closeTo(1.1, 0.01));
        expect(result.values['wallpaperType'], equals(2.0));
      });

      test('fleece (type 3) uses medium paste rate: 0.008 kg/m²', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 100.0,
          'rollSize': 1.0,
          'wallpaperType': 3.0, // флизелиновые
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 100 × 0.008 × 1.1 = 0.88 кг
        expect(result.values['pasteNeeded'], closeTo(0.88, 0.01));
        expect(result.values['wallpaperType'], equals(3.0));
      });

      test('vinyl paste > fleece paste > paper paste for same area', () {
        final emptyPriceList = <PriceItem>[];
        final baseInputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'rollSize': 1.0,
        };

        final paperResult = calculator(
          {...baseInputs, 'wallpaperType': 1.0},
          emptyPriceList,
        );
        final vinylResult = calculator(
          {...baseInputs, 'wallpaperType': 2.0},
          emptyPriceList,
        );
        final fleeceResult = calculator(
          {...baseInputs, 'wallpaperType': 3.0},
          emptyPriceList,
        );

        expect(
          vinylResult.values['pasteNeeded'],
          greaterThan(fleeceResult.values['pasteNeeded']!),
        );
        expect(
          fleeceResult.values['pasteNeeded'],
          greaterThan(paperResult.values['pasteNeeded']!),
        );
      });

      test('default wallpaperType is 1 (paper) when not specified', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'rollSize': 1.0,
          // wallpaperType not set — defaults to 1
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Default = paper (type 1): 50 × 0.005 × 1.1 = 0.275 → rounded 0.28
        expect(result.values['pasteNeeded'], closeTo(0.28, 0.01));
        expect(result.values['wallpaperType'], equals(1.0));
      });
    });

    // ================================================================
    // New tests: paste packs
    // ================================================================

    group('Paste packs (250g packaging)', () {
      test('small area — at least 1 pack', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 5.0,
          'rollSize': 1.0,
          'wallpaperType': 1.0, // бумажные
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 5 × 0.005 × 1.1 = 0.0275 кг → ceil(0.0275 / 0.25) = 1 упаковка
        expect(result.values['pastePacks'], equals(1.0));
      });

      test('medium area vinyl — correct pack count', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'rollSize': 1.0,
          'wallpaperType': 2.0, // виниловые
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 50 × 0.010 × 1.1 = 0.55 кг → ceil(0.55 / 0.25) = 3 упаковки
        expect(result.values['pastePacks'], equals(3.0));
      });

      test('large area — multiple packs', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 200.0,
          'rollSize': 1.0,
          'wallpaperType': 2.0, // виниловые
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 200 × 0.010 × 1.1 = 2.2 кг → ceil(2.2 / 0.25) = 9 упаковок
        expect(result.values['pastePacks'], equals(9.0));
      });
    });

    // ================================================================
    // New tests: primer cans
    // ================================================================

    group('Primer cans (5L packaging)', () {
      test('small area — 1 can', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 10.0,
          'rollSize': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 10 × 0.15 × 1.1 = 1.65 л → ceil(1.65 / 5.0) = 1 канистра
        expect(result.values['primerCans'], equals(1.0));
      });

      test('medium area — correct can count', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'rollSize': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 50 × 0.15 × 1.1 = 8.25 л → ceil(8.25 / 5.0) = 2 канистры
        expect(result.values['primerCans'], equals(2.0));
        // primerNeeded = 8.25 → rounded to 8.25
        expect(result.values['primerNeeded'], closeTo(8.25, 0.01));
      });

      test('large area — multiple cans', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 200.0,
          'rollSize': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 200 × 0.15 × 1.1 = 33.0 л → ceil(33.0 / 5.0) = 7 канистр
        expect(result.values['primerCans'], equals(7.0));
      });
    });

    // ================================================================
    // New tests: backward compatibility
    // ================================================================

    group('Backward compatibility', () {
      test('glueNeeded and pasteNeeded have the same value', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'rollSize': 1.0,
          'wallpaperType': 2.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glueNeeded'], isNotNull);
        expect(result.values['pasteNeeded'], isNotNull);
        expect(result.values['glueNeeded'], equals(result.values['pasteNeeded']));
      });
    });

    // ================================================================
    // Practical scenario
    // ================================================================

    group('Practical: комната 4×5, виниловые, h=2.5м', () {
      test('complete calculation for a real room', () {
        final inputs = {
          'inputMode': 0.0, // по размерам
          'length': 4.0,
          'width': 5.0,
          'wallHeight': 2.5,
          'rollSize': 1.0, // 0.53×10
          'wallpaperType': 2.0, // виниловые
          'windowsArea': 3.0, // одно окно ~1.5×2.0
          'doorsArea': 1.8, // одна дверь 0.9×2.0
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Площадь стен = (4+5) × 2 × 2.5 = 45 м²
        // Полезная площадь = 45 - 3 - 1.8 = 40.2 м²
        expect(result.values['usefulArea'], closeTo(40.2, 0.1));

        // Периметр = (4+5) × 2 = 18 м
        // Полос = ceil(18 / 0.53) = 34
        expect(result.values['stripsNeeded'], equals(34.0));

        // Полос из рулона: floor(10.05 / 2.5) = 4
        // Рулонов = ceil(34 / 4) = 9
        expect(result.values['rollsNeeded'], equals(9.0));

        // Клей (виниловые): 40.2 × 0.010 × 1.1 = 0.4422 → rounded 0.44
        expect(result.values['pasteNeeded'], closeTo(0.44, 0.01));

        // Пачки клея: ceil(0.4422 / 0.25) = 2
        expect(result.values['pastePacks'], equals(2.0));

        // Грунтовка: 40.2 × 0.15 × 1.1 = 6.633 → rounded 6.63
        expect(result.values['primerNeeded'], closeTo(6.63, 0.01));

        // Канистры: ceil(6.633 / 5.0) = 2
        expect(result.values['primerCans'], equals(2.0));
      });
    });
  });
}
