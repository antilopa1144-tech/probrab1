import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile_glue.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateTileGlue', () {
    late CalculateTileGlue calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateTileGlue();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('calculates glue for standard 30x30 tile on floor', () {
        final inputs = {
          'area': 20.0,
          'tileSize': 30.0,
          'layerThickness': 5.0,
          'surface': 2.0, // floor
        };

        final result = calculator(inputs, emptyPriceList);

        // Base: 4.2 kg/m², no adjustment for 30cm tile, 5mm layer, floor
        // 20 * 4.2 * 1.0 * 1.0 * 1.08 = 90.72 kg
        expect(result.values['glueNeeded'], closeTo(90.72, 0.5));
        expect(result.values['consumptionPerM2'], closeTo(4.2, 0.1));
        expect(result.values['area'], equals(20.0));
      });

      test('calculates glue for wall with 10% increase', () {
        final inputs = {
          'area': 20.0,
          'tileSize': 30.0,
          'layerThickness': 5.0,
          'surface': 1.0, // wall
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 4.2 * 1.1 * 1.08 = 99.79 kg
        expect(result.values['glueNeeded'], closeTo(99.79, 0.5));
        expect(result.values['consumptionPerM2'], closeTo(4.62, 0.1));
      });
    });

    group('Tile size adjustments', () {
      test('mosaic tile (<10 cm) uses thinner layer — lower consumption', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 5.0, // mosaic
          'layerThickness': 5.0,
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Base 4.2 * 0.7 (mosaic — гребёнка 3-4 мм) = 2.94 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(2.94, 0.1));
      });

      test('small tile (10-20 cm) uses 6mm notch — slightly lower consumption', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 15.0,
          'layerThickness': 5.0,
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Base 4.2 * 0.85 = 3.57 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(3.57, 0.1));
      });

      test('large tile (40-60 cm) uses 8-10mm notch — higher consumption', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 50.0,
          'layerThickness': 5.0,
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Base 4.2 * 1.2 = 5.04 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(5.04, 0.1));
      });

      test('extra large tile (>60 cm) uses 10-12mm notch + double application', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 80.0,
          'layerThickness': 5.0,
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Base 4.2 * 1.4 = 5.88 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(5.88, 0.1));
      });

      test('standard consumption for 20-40 cm tile (base, no adjustment)', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 30.0,
          'layerThickness': 5.0,
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Base 4.2, no adjustment
        expect(result.values['consumptionPerM2'], closeTo(4.2, 0.1));
      });
    });

    group('Layer thickness adjustments', () {
      test('thicker layer increases consumption', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 30.0,
          'layerThickness': 10.0, // 2x default
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 4.2 * (10/5) = 8.4 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(8.4, 0.1));
      });

      test('thinner layer decreases consumption', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 30.0,
          'layerThickness': 2.5, // half default
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 4.2 * (2.5/5) = 2.1 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(2.1, 0.1));
      });
    });

    group('Auxiliary materials', () {
      test('calculates primer needed', () {
        final inputs = {
          'area': 50.0,
          'tileSize': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 50 * 0.15 = 7.5 L
        expect(result.values['primerNeeded'], closeTo(7.5, 0.1));
      });

      test('calculates crosses needed based on tile count', () {
        final inputs = {
          'area': 9.0, // 3x3 = 9 m²
          'tileSize': 30.0, // 0.3x0.3 = 0.09 m²
        };

        final result = calculator(inputs, emptyPriceList);

        // 9 / 0.09 = 100 tiles, 100 * 5 = 500 crosses
        expect(result.values['crossesNeeded'], equals(500.0));
      });

      test('calculates water needed', () {
        final inputs = {
          'area': 20.0,
          'tileSize': 30.0,
          'layerThickness': 5.0,
          'surface': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // glueNeeded * 0.25
        final glueNeeded = result.values['glueNeeded']!;
        expect(result.values['waterNeeded'], closeTo(glueNeeded * 0.25, 0.1));
      });

      test('always needs 1 spatula and 1 bucket', () {
        final inputs = {
          'area': 100.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['spatulasNeeded'], equals(1.0));
        expect(result.values['bucketsNeeded'], equals(1.0));
      });
    });

    group('Notch size selection', () {
      test('6mm notch for tile under 20cm', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 15.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['notchSize'], equals(6.0));
      });

      test('8mm notch for tile 20-40cm', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['notchSize'], equals(8.0));
      });

      test('10mm notch for tile over 40cm', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 60.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['notchSize'], equals(10.0));
      });
    });

    group('Default values', () {
      test('uses defaults when not specified', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['tileSize'], equals(30.0));
        expect(result.values['layerThickness'], equals(5.0));
        expect(result.values['notchSize'], equals(8.0)); // for 30cm tile
      });
    });

    group('Edge cases', () {
      test('handles minimum tile size', () {
        final inputs = {
          'area': 5.0,
          'tileSize': 5.0, // minimum
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glueNeeded'], greaterThan(0));
        // 4.2 * 0.7 = 2.94
        expect(result.values['consumptionPerM2'], closeTo(2.94, 0.1));
      });

      test('handles maximum tile size', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 150.0, // maximum
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glueNeeded'], greaterThan(0));
        // 4.2 * 1.4 = 5.88
        expect(result.values['consumptionPerM2'], closeTo(5.88, 0.1));
      });

      test('handles small area', () {
        final inputs = {
          'area': 1.0,
          'tileSize': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glueNeeded'], greaterThan(0));
        expect(result.values['glueNeeded'], lessThan(10));
      });

      test('handles large area', () {
        final inputs = {
          'area': 500.0,
          'tileSize': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glueNeeded'], greaterThan(2000));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area', () {
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
          'tileSize': 30.0,
        };
        final priceList = [
          const PriceItem(sku: 'glue_tile', name: 'Tile Glue', price: 25.0, unit: 'kg', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Primer', price: 100.0, unit: 'L', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Combined factors', () {
      test('mosaic on wall with thick layer', () {
        final inputs = {
          'area': 5.0,
          'tileSize': 5.0, // mosaic: 0.7x
          'layerThickness': 10.0, // 2x
          'surface': 1.0, // wall: 1.1x
        };

        final result = calculator(inputs, emptyPriceList);

        // 4.2 * 0.7 * 2.0 * 1.1 = 6.468 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(6.47, 0.1));
        // 5 * 6.468 * 1.08 = 34.93 kg
        expect(result.values['glueNeeded'], closeTo(34.93, 0.5));
      });

      test('large tile on floor with thin layer', () {
        final inputs = {
          'area': 30.0,
          'tileSize': 80.0, // large: 1.4x
          'layerThickness': 3.0, // 0.6x
          'surface': 2.0, // floor: 1.0x
        };

        final result = calculator(inputs, emptyPriceList);

        // 4.2 * 1.4 * 0.6 * 1.0 = 3.528 kg/m²
        expect(result.values['consumptionPerM2'], closeTo(3.53, 0.1));
        // 30 * 3.528 * 1.08 = 114.31 kg
        expect(result.values['glueNeeded'], closeTo(114.31, 0.5));
      });
    });
  });
}
