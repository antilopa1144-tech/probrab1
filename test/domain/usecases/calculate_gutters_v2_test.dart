import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gutters_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateGuttersV2', () {
    late CalculateGuttersV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateGuttersV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('10x8 roof, 3m walls, 4 downpipes', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
          'needHeating': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2*(10+8) = 36 m
        expect(result.values['perimeter'], equals(36.0));
        // Gutter length = 36 * 1.05 = 37.8 m
        expect(result.values['gutterLength'], closeTo(37.8, 0.1));
        // Downpipe length = 4 * 3 * 1.1 = 13.2 m
        expect(result.values['downpipeLength'], closeTo(13.2, 0.1));
        // Corners = 4
        expect(result.values['cornersCount'], equals(4.0));
        // Funnels = 4
        expect(result.values['funnelsCount'], equals(4.0));
      });

      test('larger roof needs more materials', () {
        final smallInputs = {
          'roofLength': 8.0,
          'roofWidth': 6.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
        };
        final largeInputs = {
          'roofLength': 15.0,
          'roofWidth': 12.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['gutterLength'],
          greaterThan(smallResult.values['gutterLength']!),
        );
        expect(
          largeResult.values['bracketsCount'],
          greaterThan(smallResult.values['bracketsCount']!),
        );
      });
    });

    group('Gutter calculations', () {
      test('gutter length includes 5% waste', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 10.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2*(10+10) = 40 m
        // Gutter = 40 * 1.05 = 42 m
        expect(result.values['gutterLength'], closeTo(42.0, 0.1));
      });

      test('corners always equals 4', () {
        final inputs = {
          'roofLength': 20.0,
          'roofWidth': 15.0,
          'wallHeight': 5.0,
          'downpipesCount': 6.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cornersCount'], equals(4.0));
      });
    });

    group('Downpipe calculations', () {
      test('downpipe length depends on wall height and count', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 5.0,
          'downpipesCount': 6.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Downpipe = 6 * 5 * 1.1 = 33 m
        expect(result.values['downpipeLength'], closeTo(33.0, 0.1));
      });

      test('more downpipes need more funnels', () {
        final fewInputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 2.0,
        };
        final manyInputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 8.0,
        };

        final fewResult = calculator(fewInputs, emptyPriceList);
        final manyResult = calculator(manyInputs, emptyPriceList);

        expect(fewResult.values['funnelsCount'], equals(2.0));
        expect(manyResult.values['funnelsCount'], equals(8.0));
      });

      test('elbows = 2 per downpipe', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Elbows = 5 * 2 = 10
        expect(result.values['elbowsCount'], equals(10.0));
      });
    });

    group('Bracket calculations', () {
      test('gutter brackets every 0.6m', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 36 m
        // Brackets = ceil(36 / 0.6) = 60
        expect(result.values['bracketsCount'], equals(60.0));
      });

      test('downpipe brackets every 1m plus 2', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 4.0,
          'downpipesCount': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Per downpipe: ceil(4/1) + 2 = 4 + 2 = 6
        // Total: 3 * 6 = 18
        expect(result.values['downpipeBrackets'], equals(18.0));
      });

      test('tall walls need more downpipe brackets', () {
        final shortInputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
        };
        final tallInputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 8.0,
          'downpipesCount': 4.0,
        };

        final shortResult = calculator(shortInputs, emptyPriceList);
        final tallResult = calculator(tallInputs, emptyPriceList);

        expect(
          tallResult.values['downpipeBrackets'],
          greaterThan(shortResult.values['downpipeBrackets']!),
        );
      });
    });

    group('Heating calculations', () {
      test('no heating when disabled', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
          'needHeating': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['heatingLength'], equals(0.0));
        expect(result.values['needHeating'], equals(0.0));
      });

      test('heating length = gutters + downpipes when enabled', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
          'needHeating': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Gutter = 37.8, Downpipe = 13.2
        // Heating = 37.8 + 13.2 = 51.0
        expect(result.values['heatingLength'], closeTo(51.0, 0.1));
        expect(result.values['needHeating'], equals(1.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'roofLength': 10.0,
          'roofWidth': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallHeight'], equals(3.0));
        expect(result.values['downpipesCount'], equals(4.0));
        expect(result.values['needHeating'], equals(0.0));
      });
    });

    group('Edge cases', () {
      test('clamps values to valid range', () {
        final inputs = {
          'roofLength': 200.0, // Invalid, should clamp to 100
          'roofWidth': 100.0, // Invalid, should clamp to 50
          'wallHeight': 20.0, // Invalid, should clamp to 15
          'downpipesCount': 30.0, // Invalid, should clamp to 20
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['roofLength'], equals(100.0));
        expect(result.values['roofWidth'], equals(50.0));
        expect(result.values['wallHeight'], equals(15.0));
        expect(result.values['downpipesCount'], equals(20.0));
      });

      test('handles small roof correctly', () {
        final inputs = {
          'roofLength': 3.0,
          'roofWidth': 3.0,
          'wallHeight': 2.5,
          'downpipesCount': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['gutterLength'], greaterThan(0));
        expect(result.values['bracketsCount'], greaterThan(0));
      });

      test('handles large roof correctly', () {
        final inputs = {
          'roofLength': 50.0,
          'roofWidth': 30.0,
          'wallHeight': 10.0,
          'downpipesCount': 12.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2*(50+30) = 160 m
        expect(result.values['perimeter'], equals(160.0));
        // Gutter = 160 * 1.05 = 168 m
        expect(result.values['gutterLength'], closeTo(168.0, 0.1));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero roof length', () {
        final inputs = {
          'roofLength': 0.0,
          'roofWidth': 8.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero roof width', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative values', () {
        final inputs = {
          'roofLength': -5.0,
          'roofWidth': 8.0,
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
          'roofLength': 10.0,
          'roofWidth': 8.0,
          'wallHeight': 3.0,
          'downpipesCount': 4.0,
          'needHeating': 0.0,
        };
        final priceList = [
          const PriceItem(sku: 'gutter', name: 'Желоб', price: 250.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'downpipe', name: 'Труба', price: 300.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'corner', name: 'Угол', price: 150.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'funnel', name: 'Воронка', price: 200.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'bracket', name: 'Кронштейн', price: 50.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'elbow', name: 'Колено', price: 100.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'roofLength': 10.0,
          'roofWidth': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical house gutter system', () {
        final inputs = {
          'roofLength': 12.0,
          'roofWidth': 10.0,
          'wallHeight': 4.0,
          'downpipesCount': 4.0,
          'needHeating': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2*(12+10) = 44 m
        expect(result.values['perimeter'], equals(44.0));
        // Gutter = 44 * 1.05 = 46.2 m
        expect(result.values['gutterLength'], closeTo(46.2, 0.1));
        // Downpipe = 4 * 4 * 1.1 = 17.6 m
        expect(result.values['downpipeLength'], closeTo(17.6, 0.1));
        // Brackets = ceil(44 / 0.6) = 74
        expect(result.values['bracketsCount'], equals(74.0));
        // Downpipe brackets = 4 * (4 + 2) = 24
        expect(result.values['downpipeBrackets'], equals(24.0));
        // Elbows = 4 * 2 = 8
        expect(result.values['elbowsCount'], equals(8.0));
      });

      test('large building with heating', () {
        final inputs = {
          'roofLength': 30.0,
          'roofWidth': 20.0,
          'wallHeight': 6.0,
          'downpipesCount': 8.0,
          'needHeating': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2*(30+20) = 100 m
        expect(result.values['perimeter'], equals(100.0));
        // Gutter = 100 * 1.05 = 105 m
        expect(result.values['gutterLength'], closeTo(105.0, 0.1));
        // Downpipe = 8 * 6 * 1.1 = 52.8 m
        expect(result.values['downpipeLength'], closeTo(52.8, 0.1));
        // Heating = 105 + 52.8 = 157.8 m
        expect(result.values['heatingLength'], closeTo(157.8, 0.1));
        // Funnels = 8
        expect(result.values['funnelsCount'], equals(8.0));
        // Elbows = 8 * 2 = 16
        expect(result.values['elbowsCount'], equals(16.0));
      });
    });
  });
}
