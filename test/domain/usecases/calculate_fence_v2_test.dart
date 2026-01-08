import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_fence_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateFenceV2', () {
    late CalculateFenceV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateFenceV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('50m fence, 2m height, profiled sheets', () {
        final inputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
          'fenceType': 0.0, // profiled
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 50 * 2 = 100 m²
        expect(result.values['fenceArea'], equals(100.0));
        // Posts = ceil(50 / 2.5) + 1 = 20 + 1 = 21
        expect(result.values['postsCount'], equals(21.0));
        // Lags: 2m height > 1.8 threshold, so 3 rows
        expect(result.values['lagsRows'], equals(3.0));
        // LagsLength = 50 * 3 * 1.05 = 157.5 m
        expect(result.values['lagsLength'], closeTo(157.5, 0.1));
        // Sheets (profiled): ceil(50 / 1.1) = 46
        expect(result.values['sheetsCount'], equals(46.0));
      });

      test('taller fence uses 3 lags rows', () {
        final lowInputs = {
          'fenceLength': 50.0,
          'fenceHeight': 1.8,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };
        final highInputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.5,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final lowResult = calculator(lowInputs, emptyPriceList);
        final highResult = calculator(highInputs, emptyPriceList);

        expect(lowResult.values['lagsRows'], equals(2.0));
        expect(highResult.values['lagsRows'], equals(3.0));
      });
    });

    group('Fence types', () {
      test('profiled sheet type uses 1.1m width', () {
        final inputs = {
          'fenceLength': 11.0, // Exactly 10 sheets
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
          'fenceType': 0.0, // profiled
        };

        final result = calculator(inputs, emptyPriceList);

        // ceil(11 / 1.1) = 10
        expect(result.values['sheetsCount'], equals(10.0));
      });

      test('picket type uses 0.15m width', () {
        final inputs = {
          'fenceLength': 15.0,
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
          'fenceType': 1.0, // picket
        };

        final result = calculator(inputs, emptyPriceList);

        // ceil(15 / 0.15) = 100
        expect(result.values['sheetsCount'], equals(100.0));
      });

      test('chain link type uses 10m rolls', () {
        final inputs = {
          'fenceLength': 55.0,
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
          'fenceType': 2.0, // chain
        };

        final result = calculator(inputs, emptyPriceList);

        // ceil(55 / 10) = 6 rolls
        expect(result.values['sheetsCount'], equals(6.0));
      });

      test('different types produce different sheet counts', () {
        final baseInputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
        };

        final profiledResult = calculator({...baseInputs, 'fenceType': 0.0}, emptyPriceList);
        final picketResult = calculator({...baseInputs, 'fenceType': 1.0}, emptyPriceList);
        final chainResult = calculator({...baseInputs, 'fenceType': 2.0}, emptyPriceList);

        // profiled: ceil(50/1.1) = 46
        // picket: ceil(50/0.15) = 334
        // chain: ceil(50/10) = 5
        expect(profiledResult.values['sheetsCount'], equals(46.0));
        expect(picketResult.values['sheetsCount'], equals(334.0));
        expect(chainResult.values['sheetsCount'], equals(5.0));
      });
    });

    group('Posts calculations', () {
      test('posts count depends on spacing', () {
        final wideInputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0,
          'postSpacing': 3.5,
          'fenceType': 0.0,
        };
        final narrowInputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0,
          'postSpacing': 2.0,
          'fenceType': 0.0,
        };

        final wideResult = calculator(wideInputs, emptyPriceList);
        final narrowResult = calculator(narrowInputs, emptyPriceList);

        // Wide: ceil(50 / 3.5) + 1 = 15 + 1 = 16
        expect(wideResult.values['postsCount'], equals(16.0));
        // Narrow: ceil(50 / 2.0) + 1 = 25 + 1 = 26
        expect(narrowResult.values['postsCount'], equals(26.0));
      });

      test('always includes corner post (+1)', () {
        final inputs = {
          'fenceLength': 10.0, // Exactly 4 sections of 2.5m
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // ceil(10 / 2.5) + 1 = 4 + 1 = 5 posts
        expect(result.values['postsCount'], equals(5.0));
      });
    });

    group('Lags calculations', () {
      test('lags length includes 5% waste', () {
        final inputs = {
          'fenceLength': 100.0,
          'fenceHeight': 1.5, // 2 rows
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 100 * 2 * 1.05 = 210 m
        expect(result.values['lagsLength'], closeTo(210.0, 0.1));
      });

      test('height threshold for 3 rows is 1.8m', () {
        final at18 = calculator({
          'fenceLength': 50.0,
          'fenceHeight': 1.8,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        }, emptyPriceList);

        final at19 = calculator({
          'fenceLength': 50.0,
          'fenceHeight': 1.9,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        }, emptyPriceList);

        // Exactly 1.8m uses 2 rows (not > 1.8)
        expect(at18.values['lagsRows'], equals(2.0));
        // Above 1.8m uses 3 rows
        expect(at19.values['lagsRows'], equals(3.0));
      });
    });

    group('Fasteners calculations', () {
      test('calculates fasteners from area', () {
        final inputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0, // Area = 100 m²
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Total fasteners = 100 * 8 = 800
        expect(result.values['fastenersTotal'], equals(800.0));
        // Bags = ceil(800 / 200) = 4
        expect(result.values['fastenersBags'], equals(4.0));
      });

      test('small fence needs at least 1 bag', () {
        final inputs = {
          'fenceLength': 10.0,
          'fenceHeight': 1.0, // Area = 10 m²
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Total fasteners = 10 * 8 = 80
        // Bags = ceil(80 / 200) = 1
        expect(result.values['fastenersBags'], equals(1.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'fenceLength': 50.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['fenceHeight'], equals(2.0));
        expect(result.values['postSpacing'], equals(2.5));
        expect(result.values['fenceType'], equals(0.0)); // profiled
      });
    });

    group('Edge cases', () {
      test('clamps height to valid range', () {
        final inputs = {
          'fenceLength': 50.0,
          'fenceHeight': 5.0, // Invalid, should clamp to 3.0
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['fenceHeight'], equals(3.0));
      });

      test('clamps postSpacing to valid range', () {
        final inputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0,
          'postSpacing': 1.0, // Invalid, should clamp to 2.0
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['postSpacing'], equals(2.0));
      });

      test('handles small fence correctly', () {
        final inputs = {
          'fenceLength': 3.0,
          'fenceHeight': 1.0,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['postsCount'], greaterThan(0));
        expect(result.values['sheetsCount'], greaterThan(0));
      });

      test('handles large fence correctly', () {
        final inputs = {
          'fenceLength': 500.0,
          'fenceHeight': 3.0,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 1500 m²
        expect(result.values['fenceArea'], equals(1500.0));
        // Posts = ceil(500 / 2.5) + 1 = 200 + 1 = 201
        expect(result.values['postsCount'], equals(201.0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero length', () {
        final inputs = {
          'fenceLength': 0.0,
          'fenceHeight': 2.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative length', () {
        final inputs = {
          'fenceLength': -10.0,
          'fenceHeight': 2.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
          'fenceType': 0.0,
        };
        final priceList = [
          const PriceItem(sku: 'post', name: 'Столб', price: 500.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'lag', name: 'Лага', price: 150.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'profiled', name: 'Профлист', price: 300.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'fasteners', name: 'Саморезы', price: 200.0, unit: 'уп', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'fenceLength': 50.0,
          'fenceHeight': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical backyard fence', () {
        final inputs = {
          'fenceLength': 100.0,
          'fenceHeight': 2.0,
          'postSpacing': 2.5,
          'fenceType': 0.0, // profiled
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 200 m²
        expect(result.values['fenceArea'], equals(200.0));
        // Posts = ceil(100/2.5) + 1 = 40 + 1 = 41
        expect(result.values['postsCount'], equals(41.0));
        // Lags = 100 * 3 * 1.05 = 315 m (3 rows for 2m height > 1.8)
        expect(result.values['lagsLength'], closeTo(315.0, 0.1));
        // Sheets = ceil(100/1.1) = 91
        expect(result.values['sheetsCount'], equals(91.0));
        // Fasteners = ceil(200*8/200) = 8 bags
        expect(result.values['fastenersBags'], equals(8.0));
      });

      test('garden picket fence', () {
        final inputs = {
          'fenceLength': 30.0,
          'fenceHeight': 1.5,
          'postSpacing': 2.0,
          'fenceType': 1.0, // picket
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 45 m²
        expect(result.values['fenceArea'], equals(45.0));
        // Posts = ceil(30/2.0) + 1 = 15 + 1 = 16
        expect(result.values['postsCount'], equals(16.0));
        // Pickets = ceil(30/0.15) = 200
        expect(result.values['sheetsCount'], equals(200.0));
        // Low fence = 2 lags rows
        expect(result.values['lagsRows'], equals(2.0));
      });

      test('perimeter chain link fence', () {
        final inputs = {
          'fenceLength': 200.0,
          'fenceHeight': 2.5,
          'postSpacing': 3.0,
          'fenceType': 2.0, // chain
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 500 m²
        expect(result.values['fenceArea'], equals(500.0));
        // Posts = ceil(200/3.0) + 1 = 67 + 1 = 68
        expect(result.values['postsCount'], equals(68.0));
        // Rolls = ceil(200/10) = 20
        expect(result.values['sheetsCount'], equals(20.0));
        // High fence = 3 lags rows
        expect(result.values['lagsRows'], equals(3.0));
      });
    });
  });
}
