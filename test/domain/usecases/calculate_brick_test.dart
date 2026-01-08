import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_brick.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateBrick', () {
    late CalculateBrick calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateBrick();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('single brick, 1 thickness, 20 sqm → correct count', () {
        final inputs = {
          'area': 20.0,
          'brickType': 0.0, // single
          'wallThickness': 1.0, // 1 brick
        };

        final result = calculator(inputs, emptyPriceList);

        // 102 bricks/m² * 20 m² * 1.05 margin = 2142
        expect(result.values['bricksNeeded'], equals(2142));
        expect(result.values['area'], equals(20.0));
      });

      test('single brick, half thickness, 20 sqm', () {
        final inputs = {
          'area': 20.0,
          'brickType': 0.0, // single
          'wallThickness': 0.0, // 0.5 brick
        };

        final result = calculator(inputs, emptyPriceList);

        // 51 bricks/m² * 20 m² * 1.05 = 1071
        expect(result.values['bricksNeeded'], equals(1071));
      });

      test('double brick reduces count', () {
        final singleInputs = {
          'area': 10.0,
          'brickType': 0.0, // single
          'wallThickness': 1.0,
        };
        final doubleInputs = {
          'area': 10.0,
          'brickType': 2.0, // double
          'wallThickness': 1.0,
        };

        final singleResult = calculator(singleInputs, emptyPriceList);
        final doubleResult = calculator(doubleInputs, emptyPriceList);

        // Double brick should need fewer bricks
        expect(
          doubleResult.values['bricksNeeded']!,
          lessThan(singleResult.values['bricksNeeded']!),
        );
      });

      test('thicker wall needs more bricks', () {
        final halfInputs = {
          'area': 10.0,
          'brickType': 0.0,
          'wallThickness': 0.0, // 0.5 brick = 51/m²
        };
        final twoInputs = {
          'area': 10.0,
          'brickType': 0.0,
          'wallThickness': 3.0, // 2 bricks = 204/m²
        };

        final halfResult = calculator(halfInputs, emptyPriceList);
        final twoResult = calculator(twoInputs, emptyPriceList);

        // 2-brick wall should need ~4x more than 0.5-brick (204/51 = 4)
        // Due to ceiling rounding, allow small tolerance
        final ratio = twoResult.values['bricksNeeded']! / halfResult.values['bricksNeeded']!;
        expect(ratio, closeTo(4.0, 0.01));
      });
    });

    group('Wall dimensions input', () {
      test('calculates area from wall dimensions', () {
        final inputs = {
          'wallWidth': 5.0,
          'wallHeight': 2.7,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 5.0 * 2.7 = 13.5 m²
        expect(result.values['area'], closeTo(13.5, 0.01));
      });

      test('area input takes priority over dimensions', () {
        final inputs = {
          'area': 20.0,
          'wallWidth': 5.0,
          'wallHeight': 2.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Should use explicit area, not 5*2=10
        expect(result.values['area'], equals(20.0));
      });
    });

    group('Mortar calculations', () {
      test('calculates mortar volume', () {
        final inputs = {
          'area': 20.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // mortarVolume = bricksNeeded * 0.00025 * thicknessMultiplier
        // 2142 * 0.00025 * 1.0 = 0.5355 m³
        expect(result.values['mortarVolume'], closeTo(0.54, 0.01));
      });

      test('thicker wall uses more mortar per brick', () {
        final oneInputs = {
          'area': 20.0,
          'brickType': 0.0,
          'wallThickness': 1.0, // multiplier = 1.0
        };
        final twoInputs = {
          'area': 20.0,
          'brickType': 0.0,
          'wallThickness': 3.0, // multiplier = 1.8
        };

        final oneResult = calculator(oneInputs, emptyPriceList);
        final twoResult = calculator(twoInputs, emptyPriceList);

        // 2-brick wall has higher multiplier but also 4x bricks
        // So mortar should be significantly higher
        expect(
          twoResult.values['mortarVolume']!,
          greaterThan(oneResult.values['mortarVolume']! * 3),
        );
      });

      test('calculates mortar bags', () {
        final inputs = {
          'area': 20.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // mortarBags = ceil(mortarVolume / 0.015)
        // ceil(0.5355 / 0.015) = ceil(35.7) = 36
        expect(result.values['mortarBags'], equals(36));
      });
    });

    group('Brick type outputs', () {
      test('returns correct brick dimensions for single', () {
        final inputs = {
          'area': 10.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['brickLength'], equals(250));
        expect(result.values['brickWidth'], equals(120));
        expect(result.values['brickHeight'], equals(65));
      });

      test('returns correct brick dimensions for oneAndHalf', () {
        final inputs = {
          'area': 10.0,
          'brickType': 1.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['brickLength'], equals(250));
        expect(result.values['brickWidth'], equals(120));
        expect(result.values['brickHeight'], equals(88));
      });

      test('returns correct brick dimensions for double', () {
        final inputs = {
          'area': 10.0,
          'brickType': 2.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['brickLength'], equals(250));
        expect(result.values['brickWidth'], equals(120));
        expect(result.values['brickHeight'], equals(138));
      });

      test('returns wall thickness in mm', () {
        final inputs = {
          'area': 10.0,
          'brickType': 0.0,
          'wallThickness': 2.0, // 1.5 bricks = 380 mm
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallThicknessMm'], equals(380));
      });
    });

    group('All brick type and thickness combinations', () {
      // Test matrix: all combinations of brick type and wall thickness
      final testCases = <(int, int, int)>[
        // (brickType, wallThickness, expectedBricksPerSqm)
        (0, 0, 51),   // single, 0.5 brick
        (0, 1, 102),  // single, 1 brick
        (0, 2, 153),  // single, 1.5 bricks
        (0, 3, 204),  // single, 2 bricks
        (1, 0, 39),   // oneAndHalf, 0.5 brick
        (1, 1, 78),   // oneAndHalf, 1 brick
        (1, 2, 117),  // oneAndHalf, 1.5 bricks
        (1, 3, 156),  // oneAndHalf, 2 bricks
        (2, 0, 26),   // double, 0.5 brick
        (2, 1, 52),   // double, 1 brick
        (2, 2, 78),   // double, 1.5 bricks
        (2, 3, 104),  // double, 2 bricks
      ];

      for (final (brickType, wallThickness, expectedPerSqm) in testCases) {
        test('brickType=$brickType, thickness=$wallThickness → $expectedPerSqm/m²', () {
          final inputs = {
            'area': 10.0,
            'brickType': brickType.toDouble(),
            'wallThickness': wallThickness.toDouble(),
          };

          final result = calculator(inputs, emptyPriceList);

          // 10 m² * expectedPerSqm * 1.05 margin
          final expected = (10.0 * expectedPerSqm * 1.05).ceil();
          expect(result.values['bricksNeeded'], equals(expected));
        });
      }
    });

    group('Default values', () {
      test('uses single brick type by default', () {
        final inputs = {
          'area': 10.0,
          // No brickType specified
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Single brick, 1 thickness = 102/m²
        // 10 * 102 * 1.05 = 1071
        expect(result.values['bricksNeeded'], equals(1071));
        expect(result.values['brickType'], equals(0));
      });

      test('uses 1 brick thickness by default', () {
        final inputs = {
          'area': 10.0,
          'brickType': 0.0,
          // No wallThickness specified
        };

        final result = calculator(inputs, emptyPriceList);

        // Single brick, 1 thickness = 102/m²
        expect(result.values['bricksNeeded'], equals(1071));
        expect(result.values['wallThickness'], equals(1));
      });
    });

    group('Edge cases', () {
      test('clamps brickType to valid range', () {
        final inputs = {
          'area': 10.0,
          'brickType': 99.0, // Invalid, should clamp to 2
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['brickType'], equals(2));
      });

      test('clamps wallThickness to valid range', () {
        final inputs = {
          'area': 10.0,
          'brickType': 0.0,
          'wallThickness': 99.0, // Invalid, should clamp to 3
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallThickness'], equals(3));
      });

      test('handles small area correctly', () {
        final inputs = {
          'area': 1.0,
          'brickType': 0.0,
          'wallThickness': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 1 m² * 51 * 1.05 = 53.55 → 54
        expect(result.values['bricksNeeded'], equals(54));
      });

      test('handles large area correctly', () {
        final inputs = {
          'area': 500.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 500 * 102 * 1.05 = 53550
        expect(result.values['bricksNeeded'], equals(53550));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area without dimensions', () {
        final inputs = {
          'area': 0.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'area': -10.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
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
          'area': 10.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'brick', name: 'Кирпич', price: 15.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'cement', name: 'Цемент', price: 350.0, unit: 'мешок', imageUrl: ''),
          const PriceItem(sku: 'sand', name: 'Песок', price: 1500.0, unit: 'м³', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice!, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 10.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Cement and sand calculations', () {
      test('calculates cement needed', () {
        final inputs = {
          'area': 20.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // cementNeeded = mortarVolume * 375
        // ~0.54 * 375 = ~200 kg
        expect(result.values['cementNeeded'], closeTo(200, 10));
      });

      test('calculates sand needed', () {
        final inputs = {
          'area': 20.0,
          'brickType': 0.0,
          'wallThickness': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // sandNeeded = mortarVolume * 1.5
        // ~0.54 * 1.5 = ~0.8 m³
        expect(result.values['sandNeeded'], closeTo(0.8, 0.1));
      });
    });
  });
}
