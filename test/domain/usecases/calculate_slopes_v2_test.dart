import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_slopes_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateSlopesV2', () {
    late CalculateSlopesV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateSlopesV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('3 windows, standard dimensions', () {
        final inputs = {
          'windowsCount': 3.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'slopeDepth': 0.25,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area per window = 2 * 1.5 * 0.25 + 1.4 * 0.25 = 0.75 + 0.35 = 1.1 sqm
        // Total area = 1.1 * 3 = 3.3 sqm
        expect(result.values['totalArea'], closeTo(3.3, 0.01));
        // Material area = 3.3 * 1.15 = 3.795 sqm
        expect(result.values['materialArea'], closeTo(3.795, 0.01));
      });

      test('more windows = more materials', () {
        final fewWindows = calculator({
          'windowsCount': 2.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
        }, emptyPriceList);

        final manyWindows = calculator({
          'windowsCount': 8.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
        }, emptyPriceList);

        expect(
          manyWindows.values['totalArea'],
          greaterThan(fewWindows.values['totalArea']!),
        );
        expect(
          manyWindows.values['materialArea'],
          greaterThan(fewWindows.values['materialArea']!),
        );
      });
    });

    group('Slope area calculations', () {
      test('area includes 2 sides + 1 top', () {
        final inputs = {
          'windowsCount': 1.0,
          'windowWidth': 1.0,
          'windowHeight': 2.0,
          'slopeDepth': 0.2,
        };

        final result = calculator(inputs, emptyPriceList);

        // Side area = 2 * 2.0 * 0.2 = 0.8 sqm
        // Top area = 1.0 * 0.2 = 0.2 sqm
        // Total = 1.0 sqm
        expect(result.values['totalArea'], closeTo(1.0, 0.01));
      });

      test('deeper slopes = more area', () {
        final shallow = calculator({
          'windowsCount': 5.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'slopeDepth': 0.15,
        }, emptyPriceList);

        final deep = calculator({
          'windowsCount': 5.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'slopeDepth': 0.40,
        }, emptyPriceList);

        expect(
          deep.values['totalArea'],
          greaterThan(shallow.values['totalArea']!),
        );
      });

      test('larger windows = more area', () {
        final small = calculator({
          'windowsCount': 3.0,
          'windowWidth': 0.6,
          'windowHeight': 0.8,
          'slopeDepth': 0.25,
        }, emptyPriceList);

        final large = calculator({
          'windowsCount': 3.0,
          'windowWidth': 2.0,
          'windowHeight': 2.0,
          'slopeDepth': 0.25,
        }, emptyPriceList);

        expect(
          large.values['totalArea'],
          greaterThan(small.values['totalArea']!),
        );
      });
    });

    group('Material area (with waste)', () {
      test('material area includes 15% waste', () {
        final inputs = {
          'windowsCount': 5.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'slopeDepth': 0.25,
        };

        final result = calculator(inputs, emptyPriceList);

        // Material = totalArea * 1.15
        final expectedMaterial = result.values['totalArea']! * 1.15;
        expect(result.values['materialArea'], closeTo(expectedMaterial, 0.01));
      });
    });

    group('Corner calculations', () {
      test('corners calculated with 10% waste', () {
        final inputs = {
          'windowsCount': 3.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'needCorners': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter per window = 2 * 1.5 + 1.4 = 4.4 m
        // Total = 4.4 * 3 * 1.1 = 14.52 m
        expect(result.values['cornerLength'], closeTo(14.52, 0.01));
      });

      test('no corners when disabled', () {
        final inputs = {
          'windowsCount': 5.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'needCorners': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cornerLength'], equals(0.0));
      });

      test('corner length scales with window count', () {
        final few = calculator({
          'windowsCount': 2.0,
          'needCorners': 1.0,
        }, emptyPriceList);

        final many = calculator({
          'windowsCount': 10.0,
          'needCorners': 1.0,
        }, emptyPriceList);

        expect(
          many.values['cornerLength'],
          greaterThan(few.values['cornerLength']!),
        );
      });
    });

    group('Primer calculations', () {
      test('primer calculated at 0.15 l/sqm', () {
        final inputs = {
          'windowsCount': 5.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'slopeDepth': 0.25,
          'needPrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Primer = totalArea * 0.15
        final expectedPrimer = result.values['totalArea']! * 0.15;
        expect(result.values['primerLiters'], closeTo(expectedPrimer, 0.01));
      });

      test('no primer when disabled', () {
        final inputs = {
          'windowsCount': 5.0,
          'needPrimer': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['primerLiters'], equals(0.0));
      });
    });

    group('Sealant calculations', () {
      test('1 tube per 2.5 windows', () {
        // 3 windows -> ceil(3/2.5) = 2 tubes
        final result3 = calculator({
          'windowsCount': 3.0,
        }, emptyPriceList);
        expect(result3.values['sealantTubes'], equals(2.0));

        // 5 windows -> ceil(5/2.5) = 2 tubes
        final result5 = calculator({
          'windowsCount': 5.0,
        }, emptyPriceList);
        expect(result5.values['sealantTubes'], equals(2.0));

        // 6 windows -> ceil(6/2.5) = 3 tubes
        final result6 = calculator({
          'windowsCount': 6.0,
        }, emptyPriceList);
        expect(result6.values['sealantTubes'], equals(3.0));
      });

      test('minimum 1 tube for any window count', () {
        final result = calculator({
          'windowsCount': 1.0,
        }, emptyPriceList);

        expect(result.values['sealantTubes'], equals(1.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['windowsCount'], equals(3.0));
        expect(result.values['windowWidth'], equals(1.4));
        expect(result.values['windowHeight'], equals(1.5));
        expect(result.values['slopeDepth'], equals(0.25));
        expect(result.values['slopesType'], equals(1.0)); // gypsum
        expect(result.values['needCorners'], equals(1.0)); // yes
        expect(result.values['needPrimer'], equals(1.0)); // yes
      });
    });

    group('Edge cases', () {
      test('clamps window count to valid range', () {
        final inputs = {
          'windowsCount': 50.0, // Invalid, should clamp to 30
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['windowsCount'], equals(30.0));
      });

      test('clamps window dimensions to valid range', () {
        final inputs = {
          'windowWidth': 5.0, // Invalid, should clamp to 3.0
          'windowHeight': 5.0, // Invalid, should clamp to 2.5
          'slopeDepth': 1.0, // Invalid, should clamp to 0.5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['windowWidth'], equals(3.0));
        expect(result.values['windowHeight'], equals(2.5));
        expect(result.values['slopeDepth'], equals(0.5));
      });

      test('handles minimum values', () {
        final inputs = {
          'windowsCount': 1.0,
          'windowWidth': 0.4,
          'windowHeight': 0.4,
          'slopeDepth': 0.1,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['windowsCount'], equals(1.0));
        expect(result.values['windowWidth'], equals(0.4));
        expect(result.values['windowHeight'], equals(0.4));
        expect(result.values['slopeDepth'], equals(0.1));
        expect(result.values['totalArea'], greaterThan(0));
      });

      test('handles large window count', () {
        final inputs = {
          'windowsCount': 30.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['windowsCount'], equals(30.0));
        expect(result.values['sealantTubes'], equals(12.0)); // ceil(30/2.5)
      });
    });

    group('Validation errors', () {
      test('throws exception for zero windows', () {
        final inputs = {
          'windowsCount': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative windows', () {
        final inputs = {
          'windowsCount': -3.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero window width', () {
        final inputs = {
          'windowWidth': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero window height', () {
        final inputs = {
          'windowHeight': 0.0,
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
          'windowsCount': 5.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'needCorners': 1.0,
          'needPrimer': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'slopes_material', name: 'Материал для откосов', price: 500.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'corner_profile', name: 'Уголок', price: 50.0, unit: 'м.п.', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 100.0, unit: 'л', imageUrl: ''),
          const PriceItem(sku: 'sealant', name: 'Герметик', price: 300.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'windowsCount': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('small apartment - 4 standard windows', () {
        final inputs = {
          'windowsCount': 4.0,
          'windowWidth': 1.4,
          'windowHeight': 1.5,
          'slopeDepth': 0.25,
          'slopesType': 1.0, // gypsum
          'needCorners': 1.0,
          'needPrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area per window = 2 * 1.5 * 0.25 + 1.4 * 0.25 = 1.1 sqm
        // Total = 1.1 * 4 = 4.4 sqm
        expect(result.values['totalArea'], closeTo(4.4, 0.01));
        // Material = 4.4 * 1.15 = 5.06 sqm
        expect(result.values['materialArea'], closeTo(5.06, 0.01));
        // Sealant = ceil(4/2.5) = 2 tubes
        expect(result.values['sealantTubes'], equals(2.0));
      });

      test('large house - 12 windows, sandwich panels', () {
        final inputs = {
          'windowsCount': 12.0,
          'windowWidth': 1.2,
          'windowHeight': 1.4,
          'slopeDepth': 0.30,
          'slopesType': 2.0, // sandwich
          'needCorners': 1.0,
          'needPrimer': 0.0, // no primer for sandwich
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['windowsCount'], equals(12.0));
        expect(result.values['slopesType'], equals(2.0));
        expect(result.values['primerLiters'], equals(0.0));
        expect(result.values['sealantTubes'], equals(5.0)); // ceil(12/2.5)
      });

      test('renovation - 6 windows, plaster, no corners', () {
        final inputs = {
          'windowsCount': 6.0,
          'windowWidth': 1.0,
          'windowHeight': 1.2,
          'slopeDepth': 0.20,
          'slopesType': 0.0, // plaster
          'needCorners': 0.0,
          'needPrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['slopesType'], equals(0.0));
        expect(result.values['cornerLength'], equals(0.0));
        expect(result.values['primerLiters'], greaterThan(0));
      });
    });
  });
}
