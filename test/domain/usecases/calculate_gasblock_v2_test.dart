import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gasblock_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateGasblockV2', () {
    late CalculateGasblockV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateGasblockV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Input modes', () {
      test('by dimensions mode (default)', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 10.0,
          'height': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 10 * 3 = 30 sqm
        expect(result.values['grossArea'], equals(30.0));
        expect(result.values['netArea'], equals(30.0));
      });

      test('by area mode', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 25.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['grossArea'], equals(25.0));
        expect(result.values['netArea'], equals(25.0));
      });

      test('dimensions mode is default when inputMode not specified', () {
        final inputs = {
          'length': 8.0,
          'height': 2.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(1.0));
        expect(result.values['grossArea'], equals(20.0));
      });
    });

    group('Openings calculation', () {
      test('openings reduce net area', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 10.0,
          'height': 3.0,
          'openingsArea': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['grossArea'], equals(30.0));
        expect(result.values['netArea'], equals(25.0));
      });

      test('openings cannot exceed gross area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'openingsArea': 30.0, // more than area
        };

        final result = calculator(inputs, emptyPriceList);

        // Net area should be 0, not negative
        expect(result.values['netArea'], equals(0.0));
      });

      test('no openings by default', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['openingsArea'], equals(0.0));
        expect(result.values['netArea'], equals(20.0));
      });
    });

    group('Blocks calculation', () {
      test('calculates blocks count based on face area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 18.0, // 18 sqm
          'blockLength': 60.0, // cm
          'blockHeight': 30.0, // cm
          'reserve': 0.0, // no reserve for easy calculation
        };

        final result = calculator(inputs, emptyPriceList);

        // Block face area = 0.6 * 0.3 = 0.18 sqm
        // Blocks = 18 / 0.18 = 100 blocks
        expect(result.values['blocksCount'], equals(100.0));
      });

      test('applies reserve to blocks count', () {
        final noReserve = calculator({
          'inputMode': 0.0,
          'area': 18.0,
          'blockLength': 60.0,
          'blockHeight': 30.0,
          'reserve': 0.0,
        }, emptyPriceList);

        final withReserve = calculator({
          'inputMode': 0.0,
          'area': 18.0,
          'blockLength': 60.0,
          'blockHeight': 30.0,
          'reserve': 10.0, // 10% reserve
        }, emptyPriceList);

        // With reserve should need more blocks
        expect(
          withReserve.values['blocksCount'],
          greaterThan(noReserve.values['blocksCount']!),
        );
      });

      test('zero net area gives zero blocks', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'openingsArea': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['blocksCount'], equals(0.0));
      });
    });

    group('Volume calculation', () {
      test('volume based on net area and thickness', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'blockThickness': 200.0, // mm
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 20 sqm * 0.2 m = 4 m³
        expect(result.values['volume'], equals(4.0));
      });

      test('different thicknesses affect volume', () {
        final thin = calculator({
          'inputMode': 0.0,
          'area': 10.0,
          'blockThickness': 100.0,
        }, emptyPriceList);

        final thick = calculator({
          'inputMode': 0.0,
          'area': 10.0,
          'blockThickness': 300.0,
        }, emptyPriceList);

        expect(thick.values['volume'], greaterThan(thin.values['volume']!));
        // 10 * 0.1 = 1 m³ vs 10 * 0.3 = 3 m³
        expect(thin.values['volume'], equals(1.0));
        expect(thick.values['volume'], equals(3.0));
      });
    });

    group('Wall types', () {
      test('partition wall type (0) is default', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallType'], equals(0.0));
      });

      test('accepts bearing wall type (1)', () {
        final inputs = {
          'wallType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallType'], equals(1.0));
      });
    });

    group('Masonry mix - Glue', () {
      test('glue mode is default', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['masonryMix'], equals(0.0));
      });

      test('calculates glue kg and bags', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'blockThickness': 200.0, // 0.2m
          'masonryMix': 0.0, // glue
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 20 * 0.2 = 4 m³
        // Glue = 4 * 25 * 1.1 = 110 kg
        // Bags = ceil(110 / 25) = 5 bags
        expect(result.values['glueKg'], closeTo(110.0, 0.1));
        expect(result.values['glueBags'], equals(5.0));
        expect(result.values['mortarM3'], equals(0.0));
      });
    });

    group('Masonry mix - Mortar', () {
      test('mortar mode calculates m³', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'blockThickness': 200.0, // 0.2m
          'masonryMix': 1.0, // mortar
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 4 m³
        // Mortar = 4 * 0.2 * 1.1 = 0.88 m³
        expect(result.values['mortarM3'], closeTo(0.88, 0.01));
        expect(result.values['glueKg'], equals(0.0));
        expect(result.values['glueBags'], equals(0.0));
      });
    });

    group('Reinforcement calculation', () {
      test('reinforcement enabled by default', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 6.0,
          'height': 2.7,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['useReinforcement'], equals(1.0));
        expect(result.values['reinforcementLength'], greaterThan(0));
      });

      test('no reinforcement when disabled', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 6.0,
          'height': 2.7,
          'useReinforcement': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['reinforcementLength'], equals(0.0));
      });

      test('partition walls have different step than bearing', () {
        final partition = calculator({
          'inputMode': 1.0,
          'length': 10.0,
          'height': 3.0,
          'wallType': 0.0, // partition - step 3 rows
          'useReinforcement': 1.0,
        }, emptyPriceList);

        final bearing = calculator({
          'inputMode': 1.0,
          'length': 10.0,
          'height': 3.0,
          'wallType': 1.0, // bearing - step 2 rows
          'useReinforcement': 1.0,
        }, emptyPriceList);

        // Bearing walls need more reinforcement (every 2 rows vs every 3 rows)
        expect(
          bearing.values['reinforcementLength'],
          greaterThan(partition.values['reinforcementLength']!),
        );
      });
    });

    group('Primer calculation', () {
      test('primer enabled by default', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['usePrimer'], equals(1.0));
        expect(result.values['primerLiters'], greaterThan(0));
      });

      test('no primer when disabled', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'usePrimer': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['primerLiters'], equals(0.0));
      });

      test('primer calculation with 2 layers', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'openingsArea': 0.0,
          'usePrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Primer = 20 * 0.2 * 2 = 8 liters
        expect(result.values['primerLiters'], closeTo(8.0, 0.1));
      });
    });

    group('Plaster calculation', () {
      test('plaster enabled by default', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['usePlaster'], equals(1.0));
        expect(result.values['plasterKg'], greaterThan(0));
      });

      test('no plaster when disabled', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'usePlaster': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['plasterKg'], equals(0.0));
      });

      test('plaster calculation with 2 layers', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'openingsArea': 0.0,
          'usePlaster': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Plaster = 20 * 10 * 2 = 400 kg
        expect(result.values['plasterKg'], closeTo(400.0, 0.1));
      });
    });

    group('Mesh calculation', () {
      test('mesh enabled by default', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['useMesh'], equals(1.0));
        expect(result.values['meshArea'], greaterThan(0));
      });

      test('no mesh when disabled', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'useMesh': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['meshArea'], equals(0.0));
      });

      test('mesh for both sides with margin', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'openingsArea': 0.0,
          'useMesh': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Mesh = 20 * 2 * 1.05 = 42 sqm
        expect(result.values['meshArea'], closeTo(42.0, 0.1));
      });
    });

    group('Lintels calculation', () {
      test('lintels disabled by default', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['useLintels'], equals(0.0));
        expect(result.values['lintelsCount'], equals(0.0));
      });

      test('lintels count when enabled', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'useLintels': 1.0,
          'lintelsCount': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['useLintels'], equals(1.0));
        expect(result.values['lintelsCount'], equals(5.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(1.0)); // by dimensions
        expect(result.values['length'], equals(6.0));
        expect(result.values['height'], equals(2.7));
        expect(result.values['openingsArea'], equals(0.0));
        expect(result.values['wallType'], equals(0.0)); // partition
        expect(result.values['blockMaterial'], equals(0.0)); // gasblock
        expect(result.values['blockLength'], equals(60.0));
        expect(result.values['blockHeight'], equals(30.0));
        expect(result.values['blockThickness'], equals(100.0));
        expect(result.values['masonryMix'], equals(0.0)); // glue
        expect(result.values['reserve'], equals(5.0));
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final tooSmall = calculator({
          'inputMode': 0.0,
          'area': 0.5, // min 1
        }, emptyPriceList);

        final tooLarge = calculator({
          'inputMode': 0.0,
          'area': 2000.0, // max 1000
        }, emptyPriceList);

        expect(tooSmall.values['area'], equals(1.0));
        expect(tooLarge.values['area'], equals(1000.0));
      });

      test('clamps dimensions to valid range', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 0.2, // min 0.5
          'height': 10.0, // max 6
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(0.5));
        expect(result.values['height'], equals(6.0));
      });

      test('clamps block dimensions to valid range', () {
        final inputs = {
          'blockLength': 40.0, // min 50
          'blockHeight': 40.0, // max 35
          'blockThickness': 50.0, // min 75
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['blockLength'], equals(50.0));
        expect(result.values['blockHeight'], equals(35.0));
        expect(result.values['blockThickness'], equals(75.0));
      });

      test('clamps reserve to valid range', () {
        final tooMuch = calculator({
          'reserve': 30.0, // max 15
        }, emptyPriceList);

        expect(tooMuch.values['reserve'], equals(15.0));
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'masonryMix': 0.0,
          'useReinforcement': 1.0,
          'usePrimer': 1.0,
          'usePlaster': 1.0,
          'useMesh': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'gasblock', name: 'Газоблок', price: 50.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'glue', name: 'Клей', price: 300.0, unit: 'мешок', imageUrl: ''),
          const PriceItem(sku: 'reinforcement', name: 'Арматура', price: 30.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 50.0, unit: 'л', imageUrl: ''),
          const PriceItem(sku: 'plaster', name: 'Штукатурка', price: 10.0, unit: 'кг', imageUrl: ''),
          const PriceItem(sku: 'mesh', name: 'Сетка', price: 100.0, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });

      test('uses alternative SKUs if primary not found', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };
        final priceList = [
          const PriceItem(sku: 'gas_block', name: 'Газоблок', price: 50.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });
    });

    group('Full scenario tests', () {
      test('small partition wall with glue', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 5.0,
          'height': 2.5,
          'openingsArea': 2.0, // door
          'wallType': 0.0, // partition
          'blockThickness': 100.0,
          'masonryMix': 0.0, // glue
          'reserve': 5.0,
          'useReinforcement': 1.0,
          'usePrimer': 1.0,
          'usePlaster': 1.0,
          'useMesh': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Gross = 5 * 2.5 = 12.5 sqm
        // Net = 12.5 - 2 = 10.5 sqm
        expect(result.values['grossArea'], closeTo(12.5, 0.1));
        expect(result.values['netArea'], closeTo(10.5, 0.1));
        expect(result.values['blocksCount'], greaterThan(0));
        expect(result.values['glueKg'], greaterThan(0));
        expect(result.values['glueBags'], greaterThan(0));
        expect(result.values['reinforcementLength'], greaterThan(0));
        expect(result.values['primerLiters'], greaterThan(0));
        expect(result.values['plasterKg'], greaterThan(0));
        expect(result.values['meshArea'], greaterThan(0));
      });

      test('large bearing wall with mortar', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 20.0,
          'height': 3.0,
          'openingsArea': 10.0,
          'wallType': 1.0, // bearing
          'blockThickness': 300.0,
          'masonryMix': 1.0, // mortar
          'reserve': 10.0,
          'useReinforcement': 1.0,
          'usePrimer': 0.0,
          'usePlaster': 0.0,
          'useMesh': 0.0,
          'useLintels': 1.0,
          'lintelsCount': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Gross = 60 sqm, Net = 50 sqm
        expect(result.values['grossArea'], equals(60.0));
        expect(result.values['netArea'], equals(50.0));
        expect(result.values['mortarM3'], greaterThan(0));
        expect(result.values['glueKg'], equals(0.0));
        expect(result.values['reinforcementLength'], greaterThan(0));
        expect(result.values['primerLiters'], equals(0.0));
        expect(result.values['plasterKg'], equals(0.0));
        expect(result.values['meshArea'], equals(0.0));
        expect(result.values['lintelsCount'], equals(4.0));
      });

      test('by area mode with all options', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 30.0,
          'blockMaterial': 1.0, // foamblock
          'blockLength': 62.5,
          'blockHeight': 25.0,
          'blockThickness': 200.0,
          'masonryMix': 0.0,
          'reserve': 7.0,
          'useReinforcement': 1.0,
          'usePrimer': 1.0,
          'usePlaster': 1.0,
          'useMesh': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['grossArea'], equals(30.0));
        expect(result.values['blockMaterial'], equals(1.0));
        // 0.625 * 0.25 = 0.15625, rounded to 0.16
        expect(result.values['blockFaceArea'], closeTo(0.16, 0.01));
        expect(result.values['blocksCount'], greaterThan(0));
        expect(result.values['volume'], equals(6.0)); // 30 * 0.2
      });
    });
  });
}
