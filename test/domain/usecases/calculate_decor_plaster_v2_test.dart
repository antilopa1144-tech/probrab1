import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_decor_plaster_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateDecorPlasterV2', () {
    late CalculateDecorPlasterV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateDecorPlasterV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('30 sqm venetian plaster, 2 layers', () {
        final inputs = {
          'area': 30.0,
          'plasterType': 0.0, // venetian
          'layers': 2.0,
          'inputMode': 0.0, // manual
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 30 sqm
        expect(result.values['area'], equals(30.0));
        // Plaster = 30 * 0.4 * 2 * 1.1 = 26.4 kg
        expect(result.values['plasterKg'], closeTo(26.4, 0.1));
        // Buckets = ceil(26.4 / 25) = 2
        expect(result.values['plasterBuckets'], equals(2.0));
      });

      test('larger area needs more plaster', () {
        final smallInputs = {
          'area': 10.0,
          'plasterType': 0.0,
          'layers': 2.0,
          'inputMode': 0.0,
        };
        final largeInputs = {
          'area': 50.0,
          'plasterType': 0.0,
          'layers': 2.0,
          'inputMode': 0.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['plasterKg'],
          greaterThan(smallResult.values['plasterKg']!),
        );
      });
    });

    group('Plaster types', () {
      test('venetian plaster: 0.4 kg/sqm per layer', () {
        final inputs = {
          'area': 20.0,
          'plasterType': 0.0, // venetian
          'layers': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 0.4 * 1 * 1.1 = 8.8 kg
        expect(result.values['plasterKg'], closeTo(8.8, 0.1));
      });

      test('bark plaster: 2.5 kg/sqm per layer', () {
        final inputs = {
          'area': 20.0,
          'plasterType': 1.0, // bark
          'layers': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 2.5 * 1 * 1.1 = 55 kg
        expect(result.values['plasterKg'], closeTo(55.0, 0.1));
      });

      test('silk plaster: 0.3 kg/sqm per layer', () {
        final inputs = {
          'area': 20.0,
          'plasterType': 2.0, // silk
          'layers': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 0.3 * 1 * 1.1 = 6.6 kg
        expect(result.values['plasterKg'], closeTo(6.6, 0.1));
      });

      test('bark plaster needs more material than venetian', () {
        final venetian = calculator({
          'area': 20.0,
          'plasterType': 0.0,
          'layers': 2.0,
          'inputMode': 0.0,
        }, emptyPriceList);

        final bark = calculator({
          'area': 20.0,
          'plasterType': 1.0,
          'layers': 2.0,
          'inputMode': 0.0,
        }, emptyPriceList);

        expect(
          bark.values['plasterKg'],
          greaterThan(venetian.values['plasterKg']!),
        );
      });
    });

    group('Layers', () {
      test('more layers = more plaster', () {
        final oneLayer = calculator({
          'area': 20.0,
          'plasterType': 0.0,
          'layers': 1.0,
          'inputMode': 0.0,
        }, emptyPriceList);

        final threeLayers = calculator({
          'area': 20.0,
          'plasterType': 0.0,
          'layers': 3.0,
          'inputMode': 0.0,
        }, emptyPriceList);

        expect(
          threeLayers.values['plasterKg'],
          greaterThan(oneLayer.values['plasterKg']!),
        );
        // 3 layers should use ~3x more plaster than 1 layer
        expect(
          threeLayers.values['plasterKg']! / oneLayer.values['plasterKg']!,
          closeTo(3.0, 0.01),
        );
      });

      test('clamps layers to valid range', () {
        final inputs = {
          'area': 20.0,
          'layers': 10.0, // Should clamp to 5
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['layers'], equals(5.0));
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

      test('more area = more primer', () {
        final smallInputs = {
          'area': 10.0,
          'needPrimer': 1.0,
          'inputMode': 0.0,
        };
        final largeInputs = {
          'area': 40.0,
          'needPrimer': 1.0,
          'inputMode': 0.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['primerLiters'],
          greaterThan(smallResult.values['primerLiters']!),
        );
      });
    });

    group('Wax calculations', () {
      test('wax calculated for venetian plaster', () {
        final inputs = {
          'area': 20.0,
          'plasterType': 0.0, // venetian
          'needWax': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Wax = 20 * 0.05 * 1.1 = 1.1 kg
        expect(result.values['waxKg'], closeTo(1.1, 0.1));
      });

      test('no wax for bark plaster even if requested', () {
        final inputs = {
          'area': 20.0,
          'plasterType': 1.0, // bark
          'needWax': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['waxKg'], equals(0.0));
      });

      test('no wax for silk plaster even if requested', () {
        final inputs = {
          'area': 20.0,
          'plasterType': 2.0, // silk
          'needWax': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['waxKg'], equals(0.0));
      });

      test('no wax when not needed for venetian', () {
        final inputs = {
          'area': 20.0,
          'plasterType': 0.0, // venetian
          'needWax': 0.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['waxKg'], equals(0.0));
      });
    });

    group('Input modes', () {
      test('wall mode calculates area from dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 5.0,
          'wallHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(15.0));
        expect(result.values['wallWidth'], equals(5.0));
        expect(result.values['wallHeight'], equals(3.0));
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
          'area': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(0.0)); // manual mode
        expect(result.values['plasterType'], equals(0.0)); // venetian
        expect(result.values['layers'], equals(2.0)); // 2 layers
        expect(result.values['needPrimer'], equals(1.0)); // yes
        expect(result.values['needWax'], equals(1.0)); // yes
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

      test('handles small area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(5.0));
        expect(result.values['plasterBuckets'], greaterThan(0));
      });

      test('handles large area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 200.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(200.0));
        expect(result.values['plasterBuckets'], greaterThan(0));
      });
    });

    group('Bucket calculations', () {
      test('correctly rounds up to buckets', () {
        // 30 sqm * 0.4 kg/sqm * 2 layers * 1.1 = 26.4 kg
        // 26.4 / 25 = 1.056 -> ceil = 2 buckets
        final inputs = {
          'area': 30.0,
          'plasterType': 0.0,
          'layers': 2.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['plasterBuckets'], equals(2.0));
      });

      test('small amount still needs 1 bucket', () {
        final inputs = {
          'area': 5.0, // Minimum
          'plasterType': 2.0, // silk - lowest consumption
          'layers': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 5 * 0.3 * 1 * 1.1 = 1.65 kg -> 1 bucket
        expect(result.values['plasterBuckets'], equals(1.0));
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
          'area': -20.0,
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
          'wallWidth': 5.0,
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
          'area': 20.0,
          'plasterType': 0.0, // venetian (needs wax)
          'needPrimer': 1.0,
          'needWax': 1.0,
          'inputMode': 0.0,
        };
        final priceList = [
          const PriceItem(sku: 'decor_plaster', name: 'Декоративная штукатурка', price: 500.0, unit: 'ведро', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 100.0, unit: 'л', imageUrl: ''),
          const PriceItem(sku: 'wax', name: 'Воск', price: 800.0, unit: 'кг', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 20.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical living room wall with venetian plaster', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 5.0,
          'wallHeight': 2.7,
          'plasterType': 0.0, // venetian
          'layers': 3.0,
          'needPrimer': 1.0,
          'needWax': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 5 * 2.7 = 13.5 sqm
        expect(result.values['area'], closeTo(13.5, 0.01));
        // Plaster = 13.5 * 0.4 * 3 * 1.1 = 17.82 kg -> 1 bucket
        expect(result.values['plasterBuckets'], equals(1.0));
        // Primer = 13.5 * 0.15 * 1.1 = 2.2275 liters
        expect(result.values['primerLiters'], closeTo(2.23, 0.1));
        // Wax = 13.5 * 0.05 * 1.1 = 0.7425 kg
        expect(result.values['waxKg'], closeTo(0.74, 0.1));
      });

      test('facade with bark plaster', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 100.0,
          'plasterType': 1.0, // bark
          'layers': 1.0,
          'needPrimer': 1.0,
          'needWax': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 100 sqm
        expect(result.values['area'], equals(100.0));
        // Plaster = 100 * 2.5 * 1 * 1.1 = 275 kg -> 11 buckets
        expect(result.values['plasterBuckets'], equals(11.0));
        // No wax for bark plaster
        expect(result.values['waxKg'], equals(0.0));
      });

      test('bedroom with silk plaster', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 4.0,
          'wallHeight': 2.5,
          'plasterType': 2.0, // silk
          'layers': 2.0,
          'needPrimer': 1.0,
          'needWax': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 2.5 = 10 sqm
        expect(result.values['area'], equals(10.0));
        // Plaster = 10 * 0.3 * 2 * 1.1 = 6.6 kg -> 1 bucket
        expect(result.values['plasterBuckets'], equals(1.0));
        // No wax for silk plaster
        expect(result.values['waxKg'], equals(0.0));
      });
    });
  });
}
