import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_primer_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculatePrimerV2', () {
    late CalculatePrimerV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculatePrimerV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('deep primer on concrete, 30 sqm, 2 layers', () {
        final inputs = {
          'area': 30.0,
          'surfaceType': 0.0, // concrete
          'primerType': 0.0,  // deep
          'layers': 2.0,
          'canSize': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Rate = 0.1 * 1.3 = 0.13 l/m²
        // Liters = 30 * 0.13 * 2 * 1.1 = 8.58 l
        expect(result.values['litersNeeded'], closeTo(8.58, 0.1));
        expect(result.values['cansNeeded'], equals(1)); // ceil(8.58/10) = 1
        expect(result.values['area'], equals(30.0));
      });

      test('contact primer on plaster, 50 sqm, 1 layer', () {
        final inputs = {
          'area': 50.0,
          'surfaceType': 1.0, // plaster
          'primerType': 1.0,  // contact
          'layers': 1.0,
          'canSize': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Rate = 0.3 * 1.0 = 0.3 l/m²
        // Liters = 50 * 0.3 * 1 * 1.1 = 16.5 l
        expect(result.values['litersNeeded'], closeTo(16.5, 0.1));
        expect(result.values['cansNeeded'], equals(2)); // ceil(16.5/10) = 2
      });

      test('universal primer on drywall, 20 sqm, 3 layers', () {
        final inputs = {
          'area': 20.0,
          'surfaceType': 2.0, // drywall
          'primerType': 2.0,  // universal
          'layers': 3.0,
          'canSize': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Rate = 0.15 * 0.8 = 0.12 l/m²
        // Liters = 20 * 0.12 * 3 * 1.1 = 7.92 l
        expect(result.values['litersNeeded'], closeTo(7.92, 0.1));
        expect(result.values['cansNeeded'], equals(2)); // ceil(7.92/5) = 2
      });
    });

    group('Surface type affects consumption', () {
      test('concrete uses more primer than drywall', () {
        final concreteInputs = {
          'area': 10.0,
          'surfaceType': 0.0, // concrete (1.3x)
          'primerType': 0.0,
          'layers': 1.0,
          'canSize': 10.0,
        };
        final drywallInputs = {
          'area': 10.0,
          'surfaceType': 2.0, // drywall (0.8x)
          'primerType': 0.0,
          'layers': 1.0,
          'canSize': 10.0,
        };

        final concreteResult = calculator(concreteInputs, emptyPriceList);
        final drywallResult = calculator(drywallInputs, emptyPriceList);

        expect(
          concreteResult.values['litersNeeded']!,
          greaterThan(drywallResult.values['litersNeeded']!),
        );
        // Ratio should be 1.3/0.8 = 1.625
        final ratio = concreteResult.values['litersNeeded']! / drywallResult.values['litersNeeded']!;
        expect(ratio, closeTo(1.625, 0.01));
      });
    });

    group('Primer type affects consumption', () {
      test('contact primer uses more than deep primer', () {
        final deepInputs = {
          'area': 10.0,
          'surfaceType': 1.0,
          'primerType': 0.0, // deep (0.1)
          'layers': 1.0,
          'canSize': 10.0,
        };
        final contactInputs = {
          'area': 10.0,
          'surfaceType': 1.0,
          'primerType': 1.0, // contact (0.3)
          'layers': 1.0,
          'canSize': 10.0,
        };

        final deepResult = calculator(deepInputs, emptyPriceList);
        final contactResult = calculator(contactInputs, emptyPriceList);

        expect(
          contactResult.values['litersNeeded']!,
          greaterThan(deepResult.values['litersNeeded']!),
        );
        // Ratio should be 0.3/0.1 = 3.0
        final ratio = contactResult.values['litersNeeded']! / deepResult.values['litersNeeded']!;
        expect(ratio, closeTo(3.0, 0.01));
      });
    });

    group('Layers affect consumption', () {
      test('more layers = more primer', () {
        final oneLayerInputs = {
          'area': 10.0,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 1.0,
          'canSize': 10.0,
        };
        final threeLayersInputs = {
          'area': 10.0,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 3.0,
          'canSize': 10.0,
        };

        final oneResult = calculator(oneLayerInputs, emptyPriceList);
        final threeResult = calculator(threeLayersInputs, emptyPriceList);

        // 3 layers should need 3x more
        final ratio = threeResult.values['litersNeeded']! / oneResult.values['litersNeeded']!;
        expect(ratio, closeTo(3.0, 0.01));
      });
    });

    group('Room dimensions input', () {
      test('calculates wall area from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'roomHeight': 2.7,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 2.0,
          'canSize': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Wall area = 2 * (4 + 5) * 2.7 = 48.6 m²
        expect(result.values['area'], closeTo(48.6, 0.01));
      });

      test('area input takes priority over room dimensions', () {
        final inputs = {
          'area': 30.0,
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'roomHeight': 2.7,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 2.0,
          'canSize': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Should use explicit area, not room dimensions
        expect(result.values['area'], equals(30.0));
      });
    });

    group('Can size affects count', () {
      test('smaller cans = more cans needed', () {
        final largeCansInputs = {
          'area': 50.0,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 2.0,
          'canSize': 20.0,
        };
        final smallCansInputs = {
          'area': 50.0,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 2.0,
          'canSize': 5.0,
        };

        final largeResult = calculator(largeCansInputs, emptyPriceList);
        final smallResult = calculator(smallCansInputs, emptyPriceList);

        // Same liters needed
        expect(
          largeResult.values['litersNeeded'],
          equals(smallResult.values['litersNeeded']),
        );
        // But more small cans
        expect(
          smallResult.values['cansNeeded']!,
          greaterThan(largeResult.values['cansNeeded']!),
        );
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = {
          'area': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['surfaceType'], equals(0)); // concrete
        expect(result.values['primerType'], equals(0)); // deep
        expect(result.values['layers'], equals(2));
        expect(result.values['canSize'], equals(10.0));
      });
    });

    group('Edge cases', () {
      test('clamps surfaceType to valid range', () {
        final inputs = {
          'area': 10.0,
          'surfaceType': 99.0, // Invalid, should clamp to 2
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['surfaceType'], equals(2));
      });

      test('clamps primerType to valid range', () {
        final inputs = {
          'area': 10.0,
          'primerType': 99.0, // Invalid, should clamp to 2
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['primerType'], equals(2));
      });

      test('clamps layers to valid range', () {
        final inputs = {
          'area': 10.0,
          'layers': 10.0, // Invalid, should clamp to 3
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['layers'], equals(3));
      });

      test('handles small area correctly', () {
        final inputs = {
          'area': 1.0,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 1.0,
          'canSize': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['litersNeeded'], greaterThan(0));
        expect(result.values['cansNeeded'], equals(1));
      });

      test('handles large area correctly', () {
        final inputs = {
          'area': 500.0,
          'surfaceType': 0.0,
          'primerType': 1.0, // contact - high consumption
          'layers': 3.0,
          'canSize': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 500 * 0.3 * 1.3 * 3 * 1.1 = 643.5 l
        expect(result.values['litersNeeded'], closeTo(643.5, 1.0));
        expect(result.values['cansNeeded'], equals(65)); // ceil(643.5/10)
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area without dimensions', () {
        final inputs = {
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'area': -10.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
    });

    group('Price calculations', () {
      test('calculates total price when price available', () {
        final inputs = {
          'area': 30.0,
          'surfaceType': 0.0,
          'primerType': 0.0,
          'layers': 2.0,
          'canSize': 10.0,
        };
        final priceList = [
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 450.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        // 1 can * 450 = 450
        expect(result.totalPrice, equals(450.0));
      });

      test('returns null price when no price available', () {
        final inputs = {
          'area': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Consumption rate output', () {
      test('returns correct consumption rate', () {
        final inputs = {
          'area': 10.0,
          'surfaceType': 0.0, // concrete (1.3x)
          'primerType': 0.0, // deep (0.1)
          'layers': 1.0,
          'canSize': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 0.1 * 1.3 = 0.13
        expect(result.values['consumptionRate'], closeTo(0.13, 0.001));
      });
    });

    group('All surface and primer combinations', () {
      final testCases = <(int, int, double)>[
        // (surfaceType, primerType, expectedRate)
        (0, 0, 0.13),  // concrete, deep: 0.1 * 1.3
        (0, 1, 0.39),  // concrete, contact: 0.3 * 1.3
        (0, 2, 0.20),  // concrete, universal: 0.15 * 1.3 (rounded)
        (1, 0, 0.10),  // plaster, deep: 0.1 * 1.0
        (1, 1, 0.30),  // plaster, contact: 0.3 * 1.0
        (1, 2, 0.15),  // plaster, universal: 0.15 * 1.0
        (2, 0, 0.08),  // drywall, deep: 0.1 * 0.8
        (2, 1, 0.24),  // drywall, contact: 0.3 * 0.8
        (2, 2, 0.12),  // drywall, universal: 0.15 * 0.8
      ];

      for (final (surfaceType, primerType, expectedRate) in testCases) {
        test('surface=$surfaceType, primer=$primerType → rate=$expectedRate', () {
          final inputs = {
            'area': 10.0,
            'surfaceType': surfaceType.toDouble(),
            'primerType': primerType.toDouble(),
            'layers': 1.0,
            'canSize': 10.0,
          };

          final result = calculator(inputs, emptyPriceList);

          expect(result.values['consumptionRate'], closeTo(expectedRate, 0.001));
        });
      }
    });
  });
}
