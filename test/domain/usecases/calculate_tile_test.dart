import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateTile', () {
    test('calculates tiles needed correctly (default pattern)', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0,
        'area': 10.0,
        'tileSize': 0.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      // Default layoutPattern=1(straight,10%), roomComplexity=1(1.0x), no size adj
      // 10 / 0.09 * 1.10 = ~122
      expect(result.values['tilesNeeded'], greaterThan(100));
      expect(result.values['tilesNeeded'], lessThan(130));
    });

    test('calculates grout and glue needed', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0,
        'area': 10.0,
        'tileSize': 0.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
        'jointWidth': 3.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      // groutDepth=6mm для плитки 30×30 (15-40 см)
      expect(result.values['groutNeeded'], closeTo(2.11, 0.15));
      expect(result.values['glueNeeded'], closeTo(40.0, 5.0));
    });

    test('handles different tile sizes', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'tileSize': 60.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      expect(result.values['tilesNeeded'], greaterThan(50));
      expect(result.values['tilesNeeded'], lessThan(70));
    });

    test('calculates crosses needed', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0,
        'area': 10.0,
        'tileSize': 0.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      final tilesNeeded = result.values['tilesNeeded']!;
      // ~1.2 крестика на плитку (1 на пересечение + 20% запас)
      expect(result.values['crossesNeeded'], equals((tilesNeeded * 1.2).ceil().toDouble()));
    });

    // ========= NEW: Layout pattern tests =========

    group('layout patterns', () {
      test('diagonal pattern adds 15% waste', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final resultStraight = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 30.0,
          'layoutPattern': 1.0,
        }, emptyPriceList);

        final resultDiagonal = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 30.0,
          'layoutPattern': 2.0,
        }, emptyPriceList);

        expect(resultDiagonal.values['tilesNeeded'],
            greaterThan(resultStraight.values['tilesNeeded']!));
        expect(resultDiagonal.values['wastePercent'], closeTo(15, 0.5));
      });

      test('herringbone pattern adds 20% waste', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 30.0,
          'layoutPattern': 4.0,
        }, emptyPriceList);

        expect(result.values['wastePercent'], closeTo(20, 0.5));
      });

      test('offset pattern same waste as straight (10%)', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 30.0,
          'layoutPattern': 3.0,
        }, emptyPriceList);

        expect(result.values['wastePercent'], closeTo(10, 0.5));
      });
    });

    group('room complexity', () {
      test('L-shaped room adds 5% to waste', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final resultSimple = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 30.0,
          'layoutPattern': 1.0, 'roomComplexity': 1.0,
        }, emptyPriceList);

        final resultLShaped = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 30.0,
          'layoutPattern': 1.0, 'roomComplexity': 2.0,
        }, emptyPriceList);

        // Simple: 10% waste. L-shaped: 10% + 5% = 15%
        expect(resultLShaped.values['tilesNeeded'],
            greaterThanOrEqualTo(resultSimple.values['tilesNeeded']!));
        expect(resultLShaped.values['wastePercent'], closeTo(15, 0.5));
      });

      test('complex room adds 10% to waste', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 30.0,
          'layoutPattern': 1.0, 'roomComplexity': 3.0,
        }, emptyPriceList);

        // 10% + 10% = 20% (аддитивная формула)
        expect(result.values['wastePercent'], closeTo(20, 0.5));
      });
    });

    group('tile size adjustments', () {
      test('large tile (>60cm) adds 5% extra waste', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 1.0, 'area': 20.0, 'tileSize': 80.0,
          'layoutPattern': 1.0,
        }, emptyPriceList);

        // 10% base + 5% size adjustment = 15%
        expect(result.values['wastePercent'], closeTo(15, 0.5));
        expect(result.values['warningLargeTile'], equals(1.0));
      });

      test('mosaic tile (<10cm) reduces waste by 3%', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 1.0, 'area': 20.0,
          'tileSize': 0.0, 'tileWidth': 5.0, 'tileHeight': 5.0,
          'layoutPattern': 1.0,
        }, emptyPriceList);

        // 10% base - 3% size adjustment = 7%
        expect(result.values['wastePercent'], closeTo(7, 0.5));
      });
    });

    group('warnings', () {
      test('herringbone on large area (>30m2) generates warning', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 1.0, 'area': 35.0, 'tileSize': 30.0,
          'layoutPattern': 4.0,
        }, emptyPriceList);

        expect(result.values['warningHerringboneLargeArea'], equals(1.0));
      });

      test('no warning for herringbone on small area', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 1.0, 'area': 15.0, 'tileSize': 30.0,
          'layoutPattern': 4.0,
        }, emptyPriceList);

        expect(result.values.containsKey('warningHerringboneLargeArea'),
            isFalse);
      });
    });

    group('practical verification', () {
      test('bathroom 2x3m, diagonal -> +15%', () {
        final calculator = CalculateTile();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'inputMode': 0.0, 'length': 3.0, 'width': 2.0,
          'tileSize': 30.0, 'layoutPattern': 2.0,
        }, emptyPriceList);

        // area=6m2, tile=0.09m2, diagonal=15%
        // 6 / 0.09 * 1.15 = 76.7 -> 77 tiles
        expect(result.values['tilesNeeded'], closeTo(77, 2));
      });
    });
  });
}
