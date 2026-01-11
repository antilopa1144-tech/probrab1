import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile_adhesive_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateTileAdhesiveV2', () {
    late CalculateTileAdhesiveV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateTileAdhesiveV2();
      emptyPriceList = <PriceItem>[];
    });

    group('validation', () {
      test('returns error for area below minimum', () {
        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'area': 0.5,
        });
        expect(error, isNotNull);
        expect(error, contains('1 м²'));
      });

      test('returns error for area above maximum', () {
        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'area': 1500.0,
        });
        expect(error, isNotNull);
        expect(error, contains('1000 м²'));
      });

      test('returns error for dimensions below minimum', () {
        final error = calculator.validateInputs({
          'inputMode': 0.0,
          'length': 0.05,
          'width': 4.0,
        });
        expect(error, isNotNull);
        expect(error, contains('0.1 м'));
      });

      test('returns null for valid inputs', () {
        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'area': 20.0,
        });
        expect(error, isNull);
      });
    });

    group('calculation by area', () {
      test('calculates adhesive correctly for ceramic tile', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'tileType': 1.0, // ceramic
          'surfaceType': 0.0, // wall
          'brandIndex': 14.0, // average (1.5 kg/m²/mm)
          'bagWeight': 25.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(20.0));
        expect(result.values['tileType'], equals(1.0));
        expect(result.values['surfaceType'], equals(0.0));
        expect(result.values['notchSize'], equals(8.0)); // ceramic = 8mm notch

        // Расход: 1.5 × 8 × 0.55 × 1.1 (wall factor) = 7.26 кг/м²
        expect(result.values['adhesiveConsumption'], closeTo(7.26, 0.01));
        // Проверяем что количество мешков рассчитано
        expect(result.values['bagsNeeded'], greaterThan(0));
      });

      test('calculates primer correctly', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
        }, emptyPriceList);

        // Грунтовка: 20 × 0.15 = 3.0 л
        expect(result.values['primerLiters'], equals(3.0));
      });

      test('calculates crosses correctly', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 9.0,
          'tileType': 1.0, // ceramic (30cm default size)
        }, emptyPriceList);

        // Площадь плитки: 0.3 × 0.3 = 0.09 м²
        // Количество плиток: ceil(9 / 0.09) = 100 шт
        // Крестики: 100 × 5 = 500 шт
        expect(result.values['crossesNeeded'], greaterThan(0));
      });
    });

    group('calculation by dimensions', () {
      test('calculates area from dimensions correctly', () {
        final result = calculator({
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(20.0));
      });
    });

    group('tile types', () {
      test('mosaic has smallest notch size', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'tileType': 0.0, // mosaic
        }, emptyPriceList);

        expect(result.values['notchSize'], equals(6.0));
        expect(result.values['tileSize'], equals(10.0)); // 10cm default
      });

      test('ceramic has medium notch size', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'tileType': 1.0, // ceramic
        }, emptyPriceList);

        expect(result.values['notchSize'], equals(8.0));
        expect(result.values['tileSize'], equals(30.0)); // 30cm default
      });

      test('porcelain has larger notch size', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'tileType': 2.0, // porcelain
        }, emptyPriceList);

        expect(result.values['notchSize'], equals(10.0));
        expect(result.values['tileSize'], equals(40.0)); // 40cm default
      });

      test('large format has largest notch size', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'tileType': 3.0, // large format
        }, emptyPriceList);

        expect(result.values['notchSize'], equals(12.0));
        expect(result.values['tileSize'], equals(60.0)); // 60cm default
      });
    });

    group('surface types', () {
      test('wall surface has higher coefficient', () {
        final wallResult = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'surfaceType': 0.0, // wall
          'tileType': 1.0,
          'brandIndex': 14.0,
        }, emptyPriceList);

        final floorResult = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'surfaceType': 1.0, // floor
          'tileType': 1.0,
          'brandIndex': 14.0,
        }, emptyPriceList);

        // Wall should have 10% more consumption due to 1.1 factor
        expect(wallResult.values['adhesiveConsumption'],
            greaterThan(floorResult.values['adhesiveConsumption']!));
      });
    });

    group('bag weights', () {
      test('calculates correctly for 20kg bags', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'tileType': 1.0,
          'surfaceType': 0.0,
          'bagWeight': 20.0,
          'brandIndex': 14.0,
        }, emptyPriceList);

        expect(result.values['bagWeight'], equals(20.0));
        // Same total weight, more bags needed
        final totalWeight = result.values['totalWeight']!;
        expect(result.values['bagsNeeded'], equals((totalWeight / 20).ceil()));
      });

      test('calculates correctly for 25kg bags', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'bagWeight': 25.0,
        }, emptyPriceList);

        expect(result.values['bagWeight'], equals(25.0));
      });
    });

    group('SVP (leveling system)', () {
      test('no SVP when disabled', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'useSVP': 0.0,
        }, emptyPriceList);

        expect(result.values['svpCount'], equals(0.0));
      });

      test('calculates SVP clips when enabled', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 9.0,
          'tileType': 1.0, // ceramic (30cm)
          'useSVP': 1.0,
        }, emptyPriceList);

        // 100 плиток × 3 клипсы (medium size) = 300 шт
        expect(result.values['svpCount'], equals(300.0));
      });

      test('uses more clips for small tiles', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 1.0, // 1 м²
          'tileType': 0.0, // mosaic (10cm) - small tiles
          'useSVP': 1.0,
        }, emptyPriceList);

        // 100 плиток × 4 клипсы (small) = 400 шт
        expect(result.values['svpCount'], equals(400.0));
      });

      test('uses fewer clips for large tiles', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 3.6, // 3.6 м²
          'tileType': 3.0, // large format (60cm) - large tiles
          'useSVP': 1.0,
        }, emptyPriceList);

        // 10 плиток × 2 клипсы (large) = 20 шт
        expect(result.values['svpCount'], equals(20.0));
      });
    });

    group('grout calculation', () {
      test('no grout when disabled', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'calculateGrout': 0.0,
        }, emptyPriceList);

        expect(result.values['groutWeight'], equals(0.0));
      });

      test('calculates grout when enabled', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'tileType': 1.0, // ceramic (30cm)
          'calculateGrout': 1.0,
        }, emptyPriceList);

        expect(result.values['groutWeight'], greaterThan(0.0));
      });
    });

    group('waterproofing calculation', () {
      test('no waterproofing when disabled', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'useWaterproofing': 0.0,
        }, emptyPriceList);

        expect(result.values['waterproofingWeight'], equals(0.0));
      });

      test('calculates waterproofing when enabled', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'useWaterproofing': 1.0,
        }, emptyPriceList);

        // 10 × 0.4 × 2 = 8 кг
        expect(result.values['waterproofingWeight'], equals(8.0));
      });
    });

    group('brand variations', () {
      test('different brands have different consumption rates', () {
        final ceresitCM11 = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'tileType': 1.0,
          'surfaceType': 1.0,
          'brandIndex': 0.0, // Ceresit CM 11 (1.5)
        }, emptyPriceList);

        final ceresitCM17 = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'tileType': 1.0,
          'surfaceType': 1.0,
          'brandIndex': 3.0, // Ceresit CM 17 (1.8)
        }, emptyPriceList);

        expect(ceresitCM17.values['adhesiveConsumption'],
            greaterThan(ceresitCM11.values['adhesiveConsumption']!));
      });
    });

    group('edge cases', () {
      test('handles minimum valid area', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 1.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(1.0));
        expect(result.values['bagsNeeded'], greaterThan(0));
      });

      test('default values are applied when area is provided', () {
        final result = calculator({
          'area': 20.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(20.0));
        expect(result.values['tileType'], equals(1.0)); // default ceramic
        expect(result.values['bagWeight'], equals(25.0)); // default bag weight
      });
    });
  });
}
