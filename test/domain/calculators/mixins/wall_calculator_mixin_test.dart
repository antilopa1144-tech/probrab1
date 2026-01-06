import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/mixins/wall_calculator_mixin.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/data/models/price_item.dart';

// Test implementation of BaseCalculator with WallCalculatorMixin
class TestWallCalculator extends BaseCalculator with WallCalculatorMixin {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    return const CalculatorResult(
      values: {},
      totalPrice: null,
    );
  }
}

void main() {
  late TestWallCalculator calculator;

  setUp(() {
    calculator = TestWallCalculator();
  });

  group('WallCalculatorMixin', () {
    group('calculateWallArea', () {
      test('calculates wall area with default margin', () {
        final result = calculator.calculateWallArea(100.0);
        expect(result, closeTo(110.0, 0.01)); // 100 * 1.1
      });

      test('calculates wall area with windows deducted', () {
        final result = calculator.calculateWallArea(
          100.0,
          windowsArea: 10.0,
        );
        expect(result, closeTo(99.0, 0.01)); // (100 - 10) * 1.1
      });

      test('calculates wall area with doors deducted', () {
        final result = calculator.calculateWallArea(
          100.0,
          doorsArea: 5.0,
        );
        expect(result, closeTo(104.5, 0.01)); // (100 - 5) * 1.1
      });

      test('calculates wall area with windows and doors deducted', () {
        final result = calculator.calculateWallArea(
          100.0,
          windowsArea: 10.0,
          doorsArea: 5.0,
        );
        expect(result, closeTo(93.5, 0.01)); // (100 - 10 - 5) * 1.1
      });

      test('calculates wall area with custom margin', () {
        final result = calculator.calculateWallArea(
          100.0,
          marginPercent: 15.0,
        );
        expect(result, closeTo(115.0, 0.01)); // 100 * 1.15
      });
    });

    group('calculateRollsNeeded', () {
      test('calculates rolls needed with default margin', () {
        final result = calculator.calculateRollsNeeded(100.0, 10.0);
        expect(result, 12); // ceil((100 / 10) * 1.15)
      });

      test('calculates rolls needed with custom margin', () {
        final result = calculator.calculateRollsNeeded(
          100.0,
          10.0,
          marginPercent: 10.0,
        );
        expect(result, greaterThanOrEqualTo(11)); // ceil((100 / 10) * 1.1)
        expect(result, lessThanOrEqualTo(12));
      });

      test('handles zero roll area', () {
        final result = calculator.calculateRollsNeeded(100.0, 0.0);
        expect(result, 0);
      });

      test('handles fractional results by ceiling', () {
        final result = calculator.calculateRollsNeeded(
          50.0,
          10.0,
          marginPercent: 0.0,
        );
        expect(result, 5); // ceil(50 / 10)
      });
    });

    group('calculatePaintNeeded', () {
      test('calculates paint needed with default values', () {
        final result = calculator.calculatePaintNeeded(100.0, 10.0);
        // (100 * 2) / 10 * 1.1 = 22.0
        expect(result, 22.0);
      });

      test('calculates paint needed with custom layers', () {
        final result = calculator.calculatePaintNeeded(
          100.0,
          10.0,
          layers: 3,
        );
        // (100 * 3) / 10 * 1.1 = 33.0
        expect(result, 33.0);
      });

      test('calculates paint needed with custom margin', () {
        final result = calculator.calculatePaintNeeded(
          100.0,
          10.0,
          marginPercent: 20.0,
        );
        // (100 * 2) / 10 * 1.2 = 24.0
        expect(result, 24.0);
      });

      test('handles zero area', () {
        final result = calculator.calculatePaintNeeded(0.0, 10.0);
        expect(result, 0.0);
      });

      test('handles zero coverage', () {
        final result = calculator.calculatePaintNeeded(100.0, 0.0);
        expect(result, 0.0);
      });
    });

    group('calculateTilesNeeded', () {
      test('calculates tiles needed with default margin', () {
        final result = calculator.calculateTilesNeeded(100.0, 0.5);
        expect(result, greaterThanOrEqualTo(220)); // ceil((100 / 0.5) * 1.1)
        expect(result, lessThanOrEqualTo(221));
      });

      test('calculates tiles needed with custom margin', () {
        final result = calculator.calculateTilesNeeded(
          100.0,
          0.5,
          marginPercent: 15.0,
        );
        expect(result, 230); // ceil((100 / 0.5) * 1.15)
      });

      test('handles zero tile area', () {
        final result = calculator.calculateTilesNeeded(100.0, 0.0);
        expect(result, 0);
      });
    });

    group('calculatePlasterNeeded', () {
      test('calculates plaster volume with default margin', () {
        final result = calculator.calculatePlasterNeeded(100.0, 10.0);
        // (100 * 10 / 1000) * 1.1 = 1.1
        expect(result, 1.1);
      });

      test('calculates plaster volume with custom margin', () {
        final result = calculator.calculatePlasterNeeded(
          100.0,
          10.0,
          marginPercent: 20.0,
        );
        // (100 * 10 / 1000) * 1.2 = 1.2
        expect(result, 1.2);
      });

      test('handles different thickness values', () {
        final result = calculator.calculatePlasterNeeded(
          50.0,
          20.0,
          marginPercent: 0.0,
        );
        // (50 * 20 / 1000) = 1.0
        expect(result, 1.0);
      });
    });

    group('calculateWallCost', () {
      test('calculates cost for main material only', () {
        final result = calculator.calculateWallCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 500.0,
        );
        expect(result, 50000.0); // 100 * 500
      });

      test('calculates cost with all materials', () {
        final result = calculator.calculateWallCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 500.0,
          primerArea: 100.0,
          primerPrice: 50.0,
          adhesiveArea: 100.0,
          adhesivePrice: 100.0,
        );
        expect(result, 65000.0); // (100*500) + (100*50) + (100*100)
      });

      test('returns null if main material price is null', () {
        final result = calculator.calculateWallCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: null,
        );
        expect(result, null);
      });

      test('ignores zero area materials', () {
        final result = calculator.calculateWallCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 500.0,
          primerArea: 0.0,
          primerPrice: 50.0,
          adhesiveArea: 0.0,
          adhesivePrice: 100.0,
        );
        expect(result, 50000.0); // Only main material
      });

      test('handles null prices for optional materials', () {
        final result = calculator.calculateWallCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 500.0,
          primerArea: 100.0,
          primerPrice: null,
          adhesiveArea: 100.0,
          adhesivePrice: null,
        );
        // Main material has price, so returns that cost (ignores null optionals)
        expect(result, 50000.0);
      });
    });
  });
}
