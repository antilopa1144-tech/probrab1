// ignore_for_file: unnecessary_null_checks

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_parquet_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateParquetV2', () {
    late CalculateParquetV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateParquetV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('straight pattern, 20 sqm, 2.0 pack area', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0, // straight
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 1.05 = 21 m²
        expect(result.values['areaWithWaste'], closeTo(21.0, 0.1));
        // ceil(21 / 2.0) = 11
        expect(result.values['packsNeeded'], equals(11));
        expect(result.values['area'], equals(20.0));
        expect(result.values['wastePercent'], equals(5.0));
      });

      test('diagonal pattern uses more parquet', () {
        final straightInputs = {
          'area': 20.0,
          'pattern': 0.0, // straight (5%)
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };
        final diagonalInputs = {
          'area': 20.0,
          'pattern': 1.0, // diagonal (15%)
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };

        final straightResult = calculator(straightInputs, emptyPriceList);
        final diagonalResult = calculator(diagonalInputs, emptyPriceList);

        expect(
          diagonalResult.values['packsNeeded']!,
          greaterThan(straightResult.values['packsNeeded']!),
        );
        expect(diagonalResult.values['wastePercent'], equals(15.0));
      });

      test('herringbone pattern uses most parquet', () {
        final diagonalInputs = {
          'area': 50.0, // Larger area to avoid ceiling coincidence
          'pattern': 1.0, // diagonal (15%)
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };
        final herringboneInputs = {
          'area': 50.0,
          'pattern': 2.0, // herringbone (20%)
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };

        final diagonalResult = calculator(diagonalInputs, emptyPriceList);
        final herringboneResult = calculator(herringboneInputs, emptyPriceList);

        // 50*1.15=57.5 → 29 packs vs 50*1.20=60 → 30 packs
        expect(
          herringboneResult.values['packsNeeded'],
          greaterThan(diagonalResult.values['packsNeeded']!),
        );
        expect(herringboneResult.values['wastePercent'], equals(20.0));
      });
    });

    group('Room dimensions input', () {
      test('calculates area from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 0.0,
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
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Should use explicit area, not 4*5=20
        expect(result.values['area'], equals(30.0));
      });

      test('approximates square room from area for plinth calculation', () {
        final inputs = {
          'area': 25.0, // sqrt(25) = 5
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 1.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // roomWidth = roomLength = sqrt(25) = 5
        expect(result.values['roomWidth'], closeTo(5.0, 0.01));
        expect(result.values['roomLength'], closeTo(5.0, 0.01));
      });
    });

    group('Underlay calculations', () {
      test('calculates underlay when enabled', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // underlayArea = 20 * 1.1 = 22 m²
        expect(result.values['underlayArea'], closeTo(22.0, 0.1));
        expect(result.values['needUnderlay'], equals(1.0));
      });

      test('no underlay when disabled', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['underlayArea'], equals(0));
        expect(result.values['needUnderlay'], equals(0));
      });
    });

    group('Plinth calculations', () {
      test('calculates plinth from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 1.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // plinthLength = 2*(4+5) - 0.9 = 17.1 m
        expect(result.values['plinthLength'], closeTo(17.1, 0.1));
        // plinthPieces = ceil(17.1 / 2.5) = 7
        expect(result.values['plinthPieces'], equals(7));
      });

      test('calculates plinth from area (square room approximation)', () {
        final inputs = {
          'area': 25.0, // sqrt(25) = 5, perimeter = 4*5 = 20
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 1.0,
          'needGlue': 0.0,
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
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['plinthLength'], equals(0));
        expect(result.values['plinthPieces'], equals(0));
        expect(result.values['needPlinth'], equals(0));
      });
    });

    group('Glue calculations', () {
      test('calculates glue when enabled', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // glueLiters = 20 * 0.25 = 5 l
        expect(result.values['glueLiters'], closeTo(5.0, 0.1));
        expect(result.values['needGlue'], equals(1.0));
      });

      test('no glue when disabled', () {
        final inputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glueLiters'], equals(0));
        expect(result.values['needGlue'], equals(0));
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
          'needGlue': 0.0,
        };
        final smallPackInputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 1.5,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
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
        expect(result.values['packArea'], equals(2.0));
        expect(result.values['needUnderlay'], equals(1)); // enabled
        expect(result.values['needPlinth'], equals(1)); // enabled
        expect(result.values['needGlue'], equals(0)); // disabled
      });
    });

    group('Edge cases', () {
      test('clamps pattern to valid range', () {
        final inputs = {
          'area': 20.0,
          'pattern': 99.0, // Invalid, should clamp to 2
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['pattern'], equals(2));
      });

      test('handles small area correctly', () {
        final inputs = {
          'area': 3.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['packsNeeded'], greaterThan(0));
        expect(result.values['underlayArea'], greaterThan(0));
        expect(result.values['glueLiters'], greaterThan(0));
      });

      test('handles large area correctly', () {
        final inputs = {
          'area': 500.0,
          'pattern': 2.0, // herringbone (20%)
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 500 * 1.2 = 600, ceil(600/2) = 300 packs
        expect(result.values['packsNeeded'], equals(300));
        // underlay = 500 * 1.1 = 550 m²
        expect(result.values['underlayArea'], closeTo(550, 0.1));
        // glue = 500 * 0.25 = 125 l
        expect(result.values['glueLiters'], closeTo(125, 0.1));
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
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'parquet', name: 'Паркет', price: 2500.0, unit: 'уп', imageUrl: ''),
          const PriceItem(sku: 'underlay', name: 'Подложка', price: 500.0, unit: 'рулон', imageUrl: ''),
          const PriceItem(sku: 'plinth', name: 'Плинтус', price: 200.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'glue', name: 'Клей', price: 150.0, unit: 'л', imageUrl: ''),
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
        (2, 20.0), // herringbone
      ];

      for (final (pattern, expectedWaste) in testCases) {
        test('pattern=$pattern → waste=$expectedWaste%', () {
          final inputs = {
            'area': 100.0, // Use 100 for easy percentage calculation
            'pattern': pattern.toDouble(),
            'packArea': 2.0,
            'needUnderlay': 0.0,
            'needPlinth': 0.0,
            'needGlue': 0.0,
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
      test('typical room installation with all options', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20 m²
        expect(result.values['area'], equals(20.0));
        // With 5% waste = 21 m², need 11 packs
        expect(result.values['packsNeeded'], equals(11));
        // Underlay: 22 m²
        expect(result.values['underlayArea'], closeTo(22.0, 0.1));
        // Plinth: 17.1m, need 7 pieces
        expect(result.values['plinthPieces'], equals(7));
        // Glue: 5 liters
        expect(result.values['glueLiters'], closeTo(5.0, 0.1));
      });

      test('herringbone installation needs more material', () {
        final straightInputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 0.0, // straight (5%)
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 0.0,
        };
        final herringboneInputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'pattern': 2.0, // herringbone (20%)
          'packArea': 2.0,
          'needUnderlay': 1.0,
          'needPlinth': 1.0,
          'needGlue': 0.0,
        };

        final straightResult = calculator(straightInputs, emptyPriceList);
        final herringboneResult = calculator(herringboneInputs, emptyPriceList);

        // Herringbone needs more parquet
        expect(
          herringboneResult.values['packsNeeded']!,
          greaterThan(straightResult.values['packsNeeded']!),
        );
        // But same underlay and plinth
        expect(
          herringboneResult.values['underlayArea'],
          equals(straightResult.values['underlayArea']),
        );
        expect(
          herringboneResult.values['plinthPieces'],
          equals(straightResult.values['plinthPieces']),
        );
      });

      test('glue adds to material list', () {
        final withoutGlueInputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 0.0,
        };
        final withGlueInputs = {
          'area': 20.0,
          'pattern': 0.0,
          'packArea': 2.0,
          'needUnderlay': 0.0,
          'needPlinth': 0.0,
          'needGlue': 1.0,
        };

        final withoutResult = calculator(withoutGlueInputs, emptyPriceList);
        final withResult = calculator(withGlueInputs, emptyPriceList);

        expect(withoutResult.values['glueLiters'], equals(0));
        expect(withResult.values['glueLiters'], greaterThan(0));
      });
    });
  });
}
