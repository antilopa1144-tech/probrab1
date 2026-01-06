import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/mixins/floor_calculator_mixin.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/data/models/price_item.dart';

// Test implementation of BaseCalculator with FloorCalculatorMixin
class TestFloorCalculator extends BaseCalculator with FloorCalculatorMixin {
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
  late TestFloorCalculator calculator;

  setUp(() {
    calculator = TestFloorCalculator();
  });

  group('FloorCalculatorMixin', () {
    group('calculateFloorArea', () {
      test('calculates floor area with default margin', () {
        final result = calculator.calculateFloorArea(100.0);
        expect(result, closeTo(110.0, 0.01)); // 100 * 1.1
      });

      test('calculates floor area with custom margin', () {
        final result = calculator.calculateFloorArea(
          100.0,
          marginPercent: 15.0,
        );
        expect(result, closeTo(115.0, 0.01)); // 100 * 1.15
      });

      test('handles zero area', () {
        final result = calculator.calculateFloorArea(
          0.0,
          marginPercent: 10.0,
        );
        expect(result, 0.0);
      });
    });

    group('calculateBoardsNeeded', () {
      test('calculates boards needed with default margin', () {
        final result = calculator.calculateBoardsNeeded(100.0, 2.0);
        expect(result, greaterThanOrEqualTo(55)); // ceil((100 / 2) * 1.1)
        expect(result, lessThanOrEqualTo(56));
      });

      test('calculates boards needed with custom margin', () {
        final result = calculator.calculateBoardsNeeded(
          100.0,
          2.0,
          marginPercent: 5.0,
        );
        expect(result, 53); // ceil((100 / 2) * 1.05)
      });

      test('handles zero board area', () {
        final result = calculator.calculateBoardsNeeded(100.0, 0.0);
        expect(result, 0);
      });

      test('handles exact division', () {
        final result = calculator.calculateBoardsNeeded(
          100.0,
          2.0,
          marginPercent: 0.0,
        );
        expect(result, 50); // ceil(100 / 2)
      });
    });

    group('calculatePackagesNeeded', () {
      test('calculates packages needed with default margin', () {
        final result = calculator.calculatePackagesNeeded(100.0, 2.5);
        expect(result, greaterThanOrEqualTo(44)); // ceil((100 / 2.5) * 1.1)
        expect(result, lessThanOrEqualTo(45));
      });

      test('calculates packages needed with custom margin', () {
        final result = calculator.calculatePackagesNeeded(
          100.0,
          2.5,
          marginPercent: 15.0,
        );
        expect(result, 46); // ceil((100 / 2.5) * 1.15)
      });

      test('handles zero package area', () {
        final result = calculator.calculatePackagesNeeded(100.0, 0.0);
        expect(result, 0);
      });
    });

    group('calculateUnderlaymentArea', () {
      test('calculates underlayment with default margin', () {
        final result = calculator.calculateUnderlaymentArea(100.0);
        expect(result, closeTo(110.0, 0.01)); // 100 * 1.1 (default is 10%)
      });

      test('calculates underlayment with custom margin', () {
        final result = calculator.calculateUnderlaymentArea(
          100.0,
          marginPercent: 5.0,
        );
        expect(result, closeTo(105.0, 0.01)); // 100 * 1.05
      });

      test('handles zero area', () {
        final result = calculator.calculateUnderlaymentArea(
          0.0,
          marginPercent: 10.0,
        );
        expect(result, 0.0);
      });
    });

    group('calculatePlinthLength', () {
      test('calculates plinth length with default margin', () {
        final result = calculator.calculatePlinthLength(40.0);
        expect(result, 42.0); // 40 * 1.05 (default is 5%)
      });

      test('calculates plinth length with custom margin', () {
        final result = calculator.calculatePlinthLength(
          40.0,
          marginPercent: 10.0,
        );
        expect(result, 44.0); // 40 * 1.1
      });

      test('handles zero perimeter', () {
        final result = calculator.calculatePlinthLength(
          0.0,
          marginPercent: 5.0,
        );
        expect(result, 0.0);
      });
    });

    group('calculateFloorCost', () {
      test('calculates cost for flooring only', () {
        final result = calculator.calculateFloorCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 1000.0,
        );
        expect(result, 100000.0); // 100 * 1000
      });

      test('calculates cost with all materials', () {
        final result = calculator.calculateFloorCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 1000.0,
          underlaymentArea: 100.0,
          underlaymentPrice: 100.0,
          plinthLength: 40.0,
          plinthPrice: 200.0,
        );
        // (100*1000) + (100*100) + (40*200) = 118000
        expect(result, 118000.0);
      });

      test('returns null if flooring price is null', () {
        final result = calculator.calculateFloorCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: null,
        );
        expect(result, null);
      });

      test('ignores zero area/length materials', () {
        final result = calculator.calculateFloorCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 1000.0,
          underlaymentArea: 0.0,
          underlaymentPrice: 100.0,
          plinthLength: 0.0,
          plinthPrice: 200.0,
        );
        expect(result, 100000.0); // Only flooring
      });

      test('handles null prices for optional materials', () {
        final result = calculator.calculateFloorCost(
          mainMaterialArea: 100.0,
          mainMaterialPrice: 1000.0,
          underlaymentArea: 100.0,
          underlaymentPrice: null,
          plinthLength: 40.0,
          plinthPrice: null,
        );
        // Main material has price, so returns that cost (ignores null optionals)
        expect(result, 100000.0);
      });
    });
  });
}
