import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_linoleum_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateLinoleumV2', () {
    late CalculateLinoleumV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateLinoleumV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('20 sqm, 3m roll width', () {
        final inputs = {
          'area': 20.0,
          'rollWidth': 3.0,
          'needTape': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 1.1 = 22 m²
        expect(result.values['areaWithWaste'], closeTo(22.0, 0.1));
        // rollArea = 3 * 25 = 75 m², rollsNeeded = 22 / 75 = 0.293
        expect(result.values['rollsNeeded']!, closeTo(0.293, 0.01));
        expect(result.values['area'], equals(20.0));
        expect(result.values['wastePercent'], equals(10.0));
      });

      test('larger roll width uses less rolls', () {
        final narrowInputs = {
          'area': 50.0,
          'rollWidth': 2.0,
          'needTape': 0.0,
          'needPlinth': 0.0,
        };
        final wideInputs = {
          'area': 50.0,
          'rollWidth': 5.0,
          'needTape': 0.0,
          'needPlinth': 0.0,
        };

        final narrowResult = calculator(narrowInputs, emptyPriceList);
        final wideResult = calculator(wideInputs, emptyPriceList);

        expect(
          wideResult.values['rollsNeeded']!,
          lessThan(narrowResult.values['rollsNeeded']!),
        );
      });
    });

    group('Room dimensions input', () {
      test('calculates area from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'rollWidth': 3.0,
          'needTape': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 5 = 20 m²
        expect(result.values['area'], equals(20.0));
        expect(result.values['roomWidth'], equals(4.0));
        expect(result.values['roomLength'], equals(5.0));
      });

      test('area input takes priority over room dimensions', () {
        final inputs = {
          'area': 30.0,
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'rollWidth': 3.0,
          'needTape': 0.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Should use explicit area, not 4*5=20
        expect(result.values['area'], equals(30.0));
      });

      test('approximates square room from area', () {
        final inputs = {
          'area': 25.0, // sqrt(25) = 5
          'rollWidth': 3.0,
          'needTape': 0.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['roomWidth'], closeTo(5.0, 0.01));
        expect(result.values['roomLength'], closeTo(5.0, 0.01));
      });
    });

    group('Tape calculations', () {
      test('calculates tape when enabled', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'rollWidth': 3.0,
          'needTape': 1.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // tapeLength = 2*(4+5) + 5 = 23 m
        expect(result.values['tapeLength'], closeTo(23.0, 0.1));
        expect(result.values['needTape'], equals(1.0));
      });

      test('no tape when disabled', () {
        final inputs = {
          'area': 20.0,
          'rollWidth': 3.0,
          'needTape': 0.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['tapeLength'], equals(0));
        expect(result.values['needTape'], equals(0));
      });
    });

    group('Plinth calculations', () {
      test('calculates plinth from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'rollWidth': 3.0,
          'needTape': 0.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // plinthLength = 2*(4+5) - 0.9 = 17.1 m
        expect(result.values['plinthLength'], closeTo(17.1, 0.1));
        // plinthPieces = ceil(17.1 / 2.5) = 7
        expect(result.values['plinthPieces'], equals(7));
      });

      test('calculates plinth from area (square room approximation)', () {
        final inputs = {
          'area': 25.0, // sqrt(25) = 5
          'rollWidth': 3.0,
          'needTape': 0.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // plinthLength = 2*(5+5) - 0.9 = 19.1 m
        expect(result.values['plinthLength'], closeTo(19.1, 0.1));
        // plinthPieces = ceil(19.1 / 2.5) = 8
        expect(result.values['plinthPieces'], equals(8));
      });

      test('no plinth when disabled', () {
        final inputs = {
          'area': 20.0,
          'rollWidth': 3.0,
          'needTape': 0.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['plinthLength'], equals(0));
        expect(result.values['plinthPieces'], equals(0));
        expect(result.values['needPlinth'], equals(0));
      });
    });

    group('Roll width variations', () {
      final testCases = <(double, double)>[
        (2.0, 50.0), // 2m wide roll, 50 m² area
        (3.0, 75.0), // 3m wide roll, 75 m² area
        (4.0, 100.0), // 4m wide roll, 100 m² area
        (5.0, 125.0), // 5m wide roll, 125 m² area
      ];

      for (final (rollWidth, expectedRollArea) in testCases) {
        test('rollWidth=$rollWidth → rollArea=$expectedRollArea', () {
          final inputs = {
            'area': expectedRollArea, // Use area equal to roll area for easy calculation
            'rollWidth': rollWidth,
            'needTape': 0.0,
            'needPlinth': 0.0,
          };

          final result = calculator(inputs, emptyPriceList);

          // With 10% waste, areaWithWaste = rollArea * 1.1
          // rollsNeeded = areaWithWaste / rollArea = 1.1
          expect(result.values['rollsNeeded']!, closeTo(1.1, 0.01));
        });
      }
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['rollWidth'], equals(3.0));
        expect(result.values['needTape'], equals(1)); // enabled by default
        expect(result.values['needPlinth'], equals(1)); // enabled by default
      });
    });

    group('Edge cases', () {
      test('clamps rollWidth to valid range', () {
        final inputs = {
          'area': 20.0,
          'rollWidth': 10.0, // Invalid, should clamp to 5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['rollWidth'], equals(5.0));
      });

      test('handles small area correctly', () {
        final inputs = {
          'area': 3.0,
          'rollWidth': 3.0,
          'needTape': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['areaWithWaste'], greaterThan(0));
        expect(result.values['rollsNeeded']!, greaterThan(0));
      });

      test('handles large area correctly', () {
        final inputs = {
          'area': 500.0,
          'rollWidth': 4.0,
          'needTape': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 500 * 1.1 = 550 m²
        expect(result.values['areaWithWaste'], closeTo(550.0, 0.1));
        // rollArea = 4 * 25 = 100, rollsNeeded = 550 / 100 = 5.5
        expect(result.values['rollsNeeded']!, closeTo(5.5, 0.01));
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
      test('calculates total price when prices available', () {
        final inputs = {
          'area': 20.0,
          'rollWidth': 3.0,
          'needTape': 1.0,
          'needPlinth': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'linoleum', name: 'Линолеум', price: 350.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'tape', name: 'Скотч', price: 50.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'plinth', name: 'Плинтус', price: 150.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice!, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical room installation', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'rollWidth': 3.0,
          'needTape': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20 m²
        expect(result.values['area'], equals(20.0));
        // With 10% waste = 22 m²
        expect(result.values['areaWithWaste'], closeTo(22.0, 0.1));
        // Tape: 2*(4+5) + 5 = 23 m
        expect(result.values['tapeLength'], closeTo(23.0, 0.1));
        // Plinth: 17.1m, need 7 pieces
        expect(result.values['plinthPieces'], equals(7));
      });

      test('minimal installation without extras', () {
        final inputs = {
          'area': 20.0,
          'rollWidth': 4.0,
          'needTape': 0.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['tapeLength'], equals(0));
        expect(result.values['plinthPieces'], equals(0));
        expect(result.values['areaWithWaste'], closeTo(22.0, 0.1));
      });
    });
  });
}
