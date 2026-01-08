import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_decor_stone_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateDecorStoneV2', () {
    late CalculateDecorStoneV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateDecorStoneV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('15 sqm gypsum stone', () {
        final inputs = {
          'area': 15.0,
          'stoneType': 0.0, // gypsum
          'jointWidth': 10.0,
          'inputMode': 0.0, // manual
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 15 sqm
        expect(result.values['area'], equals(15.0));
        // Stone area = 15 * 1.1 = 16.5 sqm
        expect(result.values['stoneArea'], closeTo(16.5, 0.1));
        // Glue = 15 * 3 * 1.1 = 49.5 kg
        expect(result.values['glueKg'], closeTo(49.5, 0.1));
        // Bags = ceil(49.5 / 25) = 2
        expect(result.values['glueBags'], equals(2.0));
      });

      test('larger area needs more materials', () {
        final smallInputs = {
          'area': 5.0,
          'stoneType': 0.0,
          'inputMode': 0.0,
        };
        final largeInputs = {
          'area': 30.0,
          'stoneType': 0.0,
          'inputMode': 0.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['stoneArea'],
          greaterThan(smallResult.values['stoneArea']!),
        );
        expect(
          largeResult.values['glueKg'],
          greaterThan(smallResult.values['glueKg']!),
        );
      });
    });

    group('Stone types', () {
      test('gypsum stone: 3 kg glue/sqm', () {
        final inputs = {
          'area': 10.0,
          'stoneType': 0.0, // gypsum
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Glue = 10 * 3 * 1.1 = 33 kg
        expect(result.values['glueKg'], closeTo(33.0, 0.1));
      });

      test('concrete stone: 5 kg glue/sqm', () {
        final inputs = {
          'area': 10.0,
          'stoneType': 1.0, // concrete
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Glue = 10 * 5 * 1.1 = 55 kg
        expect(result.values['glueKg'], closeTo(55.0, 0.1));
      });

      test('natural stone: 7 kg glue/sqm', () {
        final inputs = {
          'area': 10.0,
          'stoneType': 2.0, // natural
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Glue = 10 * 7 * 1.1 = 77 kg
        expect(result.values['glueKg'], closeTo(77.0, 0.1));
      });

      test('natural stone needs more glue than gypsum', () {
        final gypsum = calculator({
          'area': 10.0,
          'stoneType': 0.0,
          'inputMode': 0.0,
        }, emptyPriceList);

        final natural = calculator({
          'area': 10.0,
          'stoneType': 2.0,
          'inputMode': 0.0,
        }, emptyPriceList);

        expect(
          natural.values['glueKg'],
          greaterThan(gypsum.values['glueKg']!),
        );
      });
    });

    group('Stone area (with waste)', () {
      test('stone area includes 10% waste', () {
        final inputs = {
          'area': 20.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Stone area = 20 * 1.1 = 22 sqm
        expect(result.values['stoneArea'], closeTo(22.0, 0.1));
      });
    });

    group('Grout calculations', () {
      test('grout calculated for 10mm joint', () {
        final inputs = {
          'area': 20.0,
          'jointWidth': 10.0,
          'needGrout': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Grout = 20 * (10/5) * 0.2 * 1.1 = 8.8 kg
        expect(result.values['groutKg'], closeTo(8.8, 0.1));
      });

      test('wider joint = more grout', () {
        final narrowInputs = {
          'area': 20.0,
          'jointWidth': 5.0,
          'needGrout': 1.0,
          'inputMode': 0.0,
        };
        final wideInputs = {
          'area': 20.0,
          'jointWidth': 15.0,
          'needGrout': 1.0,
          'inputMode': 0.0,
        };

        final narrowResult = calculator(narrowInputs, emptyPriceList);
        final wideResult = calculator(wideInputs, emptyPriceList);

        expect(
          wideResult.values['groutKg'],
          greaterThan(narrowResult.values['groutKg']!),
        );
      });

      test('no grout when not needed', () {
        final inputs = {
          'area': 20.0,
          'jointWidth': 10.0,
          'needGrout': 0.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['groutKg'], equals(0.0));
      });

      test('no grout when joint width is 0', () {
        final inputs = {
          'area': 20.0,
          'jointWidth': 0.0,
          'needGrout': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['groutKg'], equals(0.0));
      });
    });

    group('Primer calculations', () {
      test('primer calculated when needed', () {
        final inputs = {
          'area': 20.0,
          'needPrimer': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Primer = 20 * 0.15 * 1.1 = 3.3 liters
        expect(result.values['primerLiters'], closeTo(3.3, 0.1));
      });

      test('no primer when not needed', () {
        final inputs = {
          'area': 20.0,
          'needPrimer': 0.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['primerLiters'], equals(0.0));
      });
    });

    group('Input modes', () {
      test('wall mode calculates area from dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 4.0,
          'wallHeight': 2.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(10.0));
        expect(result.values['wallWidth'], equals(4.0));
        expect(result.values['wallHeight'], equals(2.5));
      });

      test('manual mode uses area directly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 25.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(25.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'area': 15.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(0.0)); // manual mode
        expect(result.values['stoneType'], equals(0.0)); // gypsum
        expect(result.values['jointWidth'], equals(10.0)); // 10mm
        expect(result.values['needGrout'], equals(1.0)); // yes
        expect(result.values['needPrimer'], equals(1.0)); // yes
      });
    });

    group('Glue bag calculations', () {
      test('correctly rounds up to bags', () {
        final inputs = {
          'area': 15.0,
          'stoneType': 0.0, // gypsum (3 kg/sqm)
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Glue = 15 * 3 * 1.1 = 49.5 kg
        // Bags = ceil(49.5 / 25) = 2
        expect(result.values['glueBags'], equals(2.0));
      });

      test('small amount still needs 1 bag', () {
        final inputs = {
          'area': 2.0,
          'stoneType': 0.0, // gypsum
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Glue = 2 * 3 * 1.1 = 6.6 kg -> 1 bag
        expect(result.values['glueBags'], equals(1.0));
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 1000.0, // Invalid, should clamp to 500
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(500.0));
      });

      test('clamps wall dimensions to valid range', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 100.0, // Invalid, should clamp to 30
          'wallHeight': 50.0, // Invalid, should clamp to 10
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallWidth'], equals(30.0));
        expect(result.values['wallHeight'], equals(10.0));
      });

      test('clamps joint width to valid range', () {
        final inputs = {
          'area': 15.0,
          'jointWidth': 50.0, // Invalid, should clamp to 20
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['jointWidth'], equals(20.0));
      });

      test('handles small area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 1.0, // Minimum
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(1.0));
        expect(result.values['stoneArea'], greaterThan(0));
        expect(result.values['glueBags'], greaterThan(0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area in manual mode', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': -15.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero wall width', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 0.0,
          'wallHeight': 2.7,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero wall height', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 4.0,
          'wallHeight': 0.0,
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
          'area': 15.0,
          'stoneType': 0.0,
          'needGrout': 1.0,
          'needPrimer': 1.0,
          'inputMode': 0.0,
        };
        final priceList = [
          const PriceItem(sku: 'decor_stone', name: 'Декоративный камень', price: 800.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'stone_glue', name: 'Клей для камня', price: 400.0, unit: 'мешок', imageUrl: ''),
          const PriceItem(sku: 'grout', name: 'Затирка', price: 200.0, unit: 'кг', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 100.0, unit: 'л', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 15.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('accent wall with gypsum stone', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 3.0,
          'wallHeight': 2.7,
          'stoneType': 0.0, // gypsum
          'jointWidth': 8.0,
          'needGrout': 1.0,
          'needPrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 3 * 2.7 = 8.1 sqm
        expect(result.values['area'], closeTo(8.1, 0.01));
        // Stone = 8.1 * 1.1 = 8.91 sqm
        expect(result.values['stoneArea'], closeTo(8.91, 0.1));
        // Glue = 8.1 * 3 * 1.1 = 26.73 kg -> 2 bags
        expect(result.values['glueBags'], equals(2.0));
      });

      test('fireplace with natural stone', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 5.0,
          'stoneType': 2.0, // natural
          'jointWidth': 5.0,
          'needGrout': 1.0,
          'needPrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 5 sqm
        expect(result.values['area'], equals(5.0));
        // Glue = 5 * 7 * 1.1 = 38.5 kg -> 2 bags
        expect(result.values['glueBags'], equals(2.0));
        // Grout = 5 * (5/5) * 0.2 * 1.1 = 1.1 kg
        expect(result.values['groutKg'], closeTo(1.1, 0.1));
      });

      test('facade with concrete stone, no grout', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 50.0,
          'stoneType': 1.0, // concrete
          'jointWidth': 0.0, // seamless
          'needGrout': 0.0,
          'needPrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 50 sqm
        expect(result.values['area'], equals(50.0));
        // Stone = 50 * 1.1 = 55 sqm
        expect(result.values['stoneArea'], closeTo(55.0, 0.1));
        // Glue = 50 * 5 * 1.1 = 275 kg -> 11 bags
        expect(result.values['glueBags'], equals(11.0));
        // No grout
        expect(result.values['groutKg'], equals(0.0));
      });
    });
  });
}
