import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_laminate_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateLaminateV2', () {
    late CalculateLaminateV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateLaminateV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('straight pattern, 20 sqm, 2.4 pack area', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0, // straight
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 1.05 = 21 m²
        expect(result.values['areaWithWaste'], closeTo(21.0, 0.1));
        // ceil(21 / 2.4) = 9
        expect(result.values['packsNeeded']!, equals(9));
        expect(result.values['area'], equals(20.0));
        expect(result.values['wastePercent'], equals(5.0));
      });

      test('diagonal pattern uses more laminate', () {
        final straightInputs = {
          'area': 20.0,
          'pattern': 0.0, // straight (5%)
          'packArea': 2.4,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
        };
        final diagonalInputs = {
          'area': 20.0,
          'pattern': 1.0, // diagonal (15%)
          'packArea': 2.4,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
        };

        final straightResult = calculator(straightInputs, emptyPriceList);
        final diagonalResult = calculator(diagonalInputs, emptyPriceList);

        expect(
          diagonalResult.values['packsNeeded']!,
          greaterThan(straightResult.values['packsNeeded']!),
        );
        expect(diagonalResult.values['wastePercent'], equals(15.0));
      });
    });

    group('Room dimensions input', () {
      test('calculates area from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 5 = 20 m²
        expect(result.values['area'], equals(20.0));
      });

      test('area input takes priority over room dimensions', () {
        final inputs = {
          'area': 30.0,
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Should use explicit area, not 4*5=20
        expect(result.values['area'], equals(30.0));
      });
    });

    group('Underlay calculations', () {
      test('calculates underlay when enabled', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // underlayArea = 20 * 1.1 = 22 m²
        expect(result.values['underlayArea'], closeTo(22.0, 0.1));
        // underlayRolls = ceil(22 / 10) = 3
        expect(result.values['underlayRolls'], equals(3));
      });

      test('no underlay when disabled', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['underlayArea'], equals(0));
        expect(result.values['underlayRolls'], equals(0));
        expect(result.values['needUnderlay'], equals(0));
      });
    });

    group('Plinth calculations', () {
      test('calculates plinth from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 0.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // plinthLength = 2*(4+5) - 1 = 17 m
        expect(result.values['plinthLength'], closeTo(17.0, 0.1));
        // plinthPieces = ceil(17 / 2.5) = 7
        expect(result.values['plinthPieces'], equals(7));
      });

      test('calculates plinth from area (square room approximation)', () {
        final inputs = {
          'area': 25.0, // sqrt(25) = 5, perimeter = 4*5 = 20
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 0.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // plinthLength = 4*5 - 1 = 19 m
        expect(result.values['plinthLength'], closeTo(19.0, 0.1));
        // plinthPieces = ceil(19 / 2.5) = 8
        expect(result.values['plinthPieces'], equals(8));
      });

      test('no plinth when disabled', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['plinthLength'], equals(0));
        expect(result.values['plinthPieces'], equals(0));
        expect(result.values['needPlinth'], equals(0));
      });
    });

    group('Pack area variations', () {
      test('smaller pack area = more packs', () {
        final largePackInputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 3.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
        };
        final smallPackInputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
        };

        final largeResult = calculator(largePackInputs, emptyPriceList);
        final smallResult = calculator(smallPackInputs, emptyPriceList);

        expect(
          smallResult.values['packsNeeded']!,
          greaterThan(largeResult.values['packsNeeded']!),
        );
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['pattern'], equals(0)); // straight
        expect(result.values['packArea'], equals(2.4));
        expect(result.values['needUnderlay'], equals(1)); // enabled
        expect(result.values['needPlinth'], equals(1)); // enabled
      });
    });

    group('Edge cases', () {
      test('clamps pattern to valid range', () {
        final inputs = {
          'area': 20.0,
          'pattern': 99.0, // Invalid, should clamp to 1
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['pattern'], equals(1));
      });

      test('handles small area correctly', () {
        final inputs = {
          'area': 3.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['packsNeeded']!, greaterThan(0));
        expect(result.values['underlayRolls'], greaterThan(0));
      });

      test('handles large area correctly', () {
        final inputs = {
          'area': 500.0,
          'pattern': 1.0, // diagonal
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 500 * 1.15 = 575, ceil(575/2.4) = 240 packs
        expect(result.values['packsNeeded']!, equals(240));
        // underlay = 500 * 1.1 = 550, ceil(550/10) = 55 rolls
        expect(result.values['underlayRolls'], equals(55));
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
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'laminate', name: 'Ламинат', price: 1200.0, unit: 'уп', imageUrl: ''),
          const PriceItem(sku: 'underlay', name: 'Подложка', price: 500.0, unit: 'рулон', imageUrl: ''),
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

    group('Pattern waste percentages', () {
      final testCases = <(int, double)>[
        (0, 5.0),  // straight
        (1, 15.0), // diagonal
      ];

      for (final (pattern, expectedWaste) in testCases) {
        test('pattern=$pattern → waste=$expectedWaste%', () {
          final inputs = {
            'area': 100.0, // Use 100 for easy percentage calculation
            'pattern': pattern.toDouble(),
            'packArea': 2.5,
            'needUnderlay': 0.0,
            'needPlinth': 0.0,
          };

          final result = calculator(inputs, emptyPriceList);

          expect(result.values['wastePercent'], equals(expectedWaste));
          // areaWithWaste = 100 * (1 + waste/100)
          final expectedArea = 100.0 * (1 + expectedWaste / 100);
          expect(result.values['areaWithWaste'], closeTo(expectedArea, 0.01));
        });
      }
    });

    group('Full scenario tests', () {
      test('typical room installation', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20 m²
        expect(result.values['area'], equals(20.0));
        // With 5% waste = 21 m², need 9 packs
        expect(result.values['packsNeeded']!, equals(9));
        // Underlay: 22 m², need 3 rolls
        expect(result.values['underlayRolls'], equals(3));
        // Plinth: 17m, need 7 pieces
        expect(result.values['plinthPieces'], equals(7));
      });

      test('diagonal installation needs more material', () {
        final straightInputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };
        final diagonalInputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 1.0,
          'packArea': 2.4,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
        };

        final straightResult = calculator(straightInputs, emptyPriceList);
        final diagonalResult = calculator(diagonalInputs, emptyPriceList);

        // Diagonal needs more laminate
        expect(
          diagonalResult.values['packsNeeded']!,
          greaterThan(straightResult.values['packsNeeded']!),
        );
        // But same underlay and plinth
        expect(
          diagonalResult.values['underlayRolls'],
          equals(straightResult.values['underlayRolls']),
        );
        expect(
          diagonalResult.values['plinthPieces'],
          equals(straightResult.values['plinthPieces']),
        );
      });
    });
  });
}
