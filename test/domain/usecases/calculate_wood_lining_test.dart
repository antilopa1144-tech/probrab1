import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wood_lining.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateWoodLining', () {
    test('calculates lining pieces correctly for standard type', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'liningType': 1.0, // standard: 88mm x 3m
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Lining area with reserve: 20 * 1.1 = 22 м²
      expect(result.values['liningArea'], closeTo(22.0, 0.1));
      // Board area: 3.0 * 0.088 = 0.264 м²
      // Pieces: 22 / 0.264 = 83.3 -> ceil = 84
      expect(result.values['liningPieces'], equals(84.0));
    });

    test('calculates lining pieces correctly for euro type', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'liningType': 2.0, // euro: 96mm x 2.5m
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Board area: 2.5 * 0.096 = 0.24 м²
      // Pieces: 22 / 0.24 = 91.7 -> ceil = 92
      expect(result.values['liningPieces'], equals(92.0));
    });

    test('calculates lining pieces correctly for block house', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'liningType': 3.0, // block house: 140mm x 2m
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Board area: 2.0 * 0.14 = 0.28 м²
      // Pieces: 22 / 0.28 = 78.6 -> ceil = 79
      expect(result.values['liningPieces'], equals(79.0));
    });

    test('calculates batten length for vertical mounting', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'height': 2.5,
        'perimeter': 18.0, // ~4.5m x 4.5m room
        'mountingDirection': 1.0, // vertical
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Batten count: 2.5 / 0.5 = 5 rows
      // Batten length: 5 * 18 * 1.1 = 99 м
      expect(result.values['battenLength'], closeTo(99.0, 5.0));
    });

    test('calculates batten length for horizontal mounting', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'height': 2.5,
        'perimeter': 18.0,
        'mountingDirection': 2.0, // horizontal
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Batten count: 18 / 0.5 = 36 columns
      // Batten length: 36 * 2.5 * 1.1 = 99 м
      expect(result.values['battenLength'], closeTo(99.0, 5.0));
    });

    test('calculates batten length for diagonal mounting with increased margin', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'height': 2.5,
        'perimeter': 18.0,
        'mountingDirection': 3.0, // diagonal - 30% margin
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Batten count: 18 / 0.5 = 36 columns
      // Batten length: 36 * 2.5 * 1.3 = 117 м
      expect(result.values['battenLength'], closeTo(117.0, 5.0));
    });

    test('calculates fasteners for klyaymery', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'fasteningType': 1.0, // klyaymery - 20 per m²
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Lining area: 22 м²
      // Fasteners: 22 * 20 = 440
      expect(result.values['fasteners'], equals(440.0));
    });

    test('calculates fasteners for nails with higher count', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'fasteningType': 2.0, // nails - 25 per m²
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Fasteners: 22 * 25 = 550
      expect(result.values['fasteners'], equals(550.0));
    });

    test('calculates antiseptic when enabled', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'useAntiseptic': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Antiseptic: 20 * 0.2 * 1.1 = 4.4 л
      expect(result.values['antiseptic'], closeTo(4.4, 0.1));
    });

    test('does not include antiseptic when disabled', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'useAntiseptic': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values.containsKey('antiseptic'), isFalse);
    });

    test('calculates finish for varnish', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'useFinish': 1.0,
        'finishType': 1.0, // varnish - 0.15 л/м²
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Finish: 20 * 0.15 * 1.1 = 3.3 л
      expect(result.values['finish'], closeTo(3.3, 0.1));
    });

    test('calculates finish for oil with lower consumption', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'useFinish': 1.0,
        'finishType': 2.0, // oil - 0.12 л/м²
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Finish: 20 * 0.12 * 1.1 = 2.64 л
      expect(result.values['finish'], closeTo(2.64, 0.1));
    });

    test('calculates insulation when enabled', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'useInsulation': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Insulation: 20 * 1.1 = 22 м²
      expect(result.values['insulation'], closeTo(22.0, 0.1));
    });

    test('calculates vapor barrier when enabled', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
        'useVaporBarrier': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Vapor barrier: 20 * 1.2 = 24 м² (20% margin for overlaps)
      expect(result.values['vaporBarrier'], closeTo(24.0, 0.1));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Default: standard lining (1), vertical mounting (1), klyaymery (1), 10% reserve
      expect(result.values['liningType'], equals(1.0));
      expect(result.values['mountingDirection'], equals(1.0));
      expect(result.values['fasteningType'], equals(1.0));
      // Antiseptic is enabled by default
      expect(result.values.containsKey('antiseptic'), isTrue);
    });

    test('throws exception for zero area', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('estimates perimeter from area when not provided', () {
      final calculator = CalculateWoodLining();
      final inputs = {
        'area': 16.0, // 4x4 room
        'height': 2.5,
        'mountingDirection': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Estimated perimeter for 16 m²: 4 * sqrt(16) = 16 м
      // Batten count: 2.5 / 0.5 = 5 rows
      // Batten length: 5 * 16 * 1.1 = 88 м
      expect(result.values['battenLength'], closeTo(88.0, 5.0));
    });
  });
}
