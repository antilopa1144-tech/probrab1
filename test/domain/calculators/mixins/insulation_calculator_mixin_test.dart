import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/mixins/insulation_calculator_mixin.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/data/models/price_item.dart';

// Test implementation of BaseCalculator with InsulationCalculatorMixin
class TestInsulationCalculator extends BaseCalculator
    with InsulationCalculatorMixin {
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
  late TestInsulationCalculator calculator;

  setUp(() {
    calculator = TestInsulationCalculator();
  });

  group('InsulationCalculatorMixin', () {
    group('calculateInsulationVolume', () {
      test('calculates volume with default margin', () {
        final result = calculator.calculateInsulationVolume(100.0, 50.0);
        // (100 * 50 / 1000) * 1.1 = 5.5
        expect(result, 5.5);
      });

      test('calculates volume with custom margin', () {
        final result = calculator.calculateInsulationVolume(
          100.0,
          50.0,
          marginPercent: 20.0,
        );
        // (100 * 50 / 1000) * 1.2 = 6.0
        expect(result, 6.0);
      });

      test('handles different thickness values', () {
        final result = calculator.calculateInsulationVolume(
          50.0,
          100.0,
          marginPercent: 0.0,
        );
        // (50 * 100 / 1000) = 5.0
        expect(result, 5.0);
      });
    });

    group('calculateInsulationSheetsNeeded', () {
      test('calculates sheets with default margin', () {
        final result = calculator.calculateInsulationSheetsNeeded(100.0, 1.2);
        expect(result, greaterThanOrEqualTo(91)); // ceil((100 / 1.2) * 1.1)
        expect(result, lessThanOrEqualTo(92));
      });

      test('calculates sheets with custom margin', () {
        final result = calculator.calculateInsulationSheetsNeeded(
          100.0,
          1.2,
          marginPercent: 15.0,
        );
        expect(result, greaterThanOrEqualTo(95)); // ceil((100 / 1.2) * 1.15)
        expect(result, lessThanOrEqualTo(96));
      });

      test('handles zero sheet area', () {
        final result = calculator.calculateInsulationSheetsNeeded(100.0, 0.0);
        expect(result, 0);
      });
    });

    group('calculateVaporBarrierArea', () {
      test('calculates vapor barrier with default margin', () {
        final result = calculator.calculateVaporBarrierArea(100.0);
        expect(result, closeTo(115.0, 0.01)); // 100 * 1.15
      });

      test('calculates vapor barrier with custom margin', () {
        final result = calculator.calculateVaporBarrierArea(
          100.0,
          marginPercent: 20.0,
        );
        expect(result, closeTo(120.0, 0.01)); // 100 * 1.2
      });

      test('handles zero area', () {
        final result = calculator.calculateVaporBarrierArea(
          0.0,
          marginPercent: 15.0,
        );
        expect(result, 0.0);
      });
    });

    group('calculateWaterproofingArea', () {
      test('calculates waterproofing with default margin', () {
        final result = calculator.calculateWaterproofingArea(100.0);
        expect(result, closeTo(115.0, 0.01)); // 100 * 1.15
      });

      test('calculates waterproofing with custom margin', () {
        final result = calculator.calculateWaterproofingArea(
          100.0,
          marginPercent: 10.0,
        );
        expect(result, closeTo(110.0, 0.01)); // 100 * 1.1
      });

      test('handles zero area', () {
        final result = calculator.calculateWaterproofingArea(
          0.0,
          marginPercent: 15.0,
        );
        expect(result, 0.0);
      });
    });

    group('calculateFastenersNeeded', () {
      test('calculates fasteners with default spacing and margin', () {
        final result = calculator.calculateFastenersNeeded(100.0);
        // ceil((100 / (0.5 * 0.5)) * 1.1) = 441
        expect(result, greaterThanOrEqualTo(440));
        expect(result, lessThanOrEqualTo(441));
      });

      test('calculates fasteners with custom spacing', () {
        final result = calculator.calculateFastenersNeeded(
          100.0,
          fastenerSpacing: 1.0,
        );
        // ceil((100 / (1.0 * 1.0)) * 1.1) = 110
        expect(result, greaterThanOrEqualTo(110));
        expect(result, lessThanOrEqualTo(111));
      });

      test('calculates fasteners with custom margin', () {
        final result = calculator.calculateFastenersNeeded(
          100.0,
          marginPercent: 20.0,
        );
        // ceil((100 / (0.5 * 0.5)) * 1.2) = 480
        expect(result, greaterThanOrEqualTo(479));
        expect(result, lessThanOrEqualTo(480));
      });

      test('handles zero area', () {
        final result = calculator.calculateFastenersNeeded(0.0);
        expect(result, 0);
      });

      test('handles zero spacing', () {
        final result = calculator.calculateFastenersNeeded(
          100.0,
          fastenerSpacing: 0.0,
        );
        expect(result, 0);
      });
    });

    group('calculateTapeLength', () {
      test('calculates tape length with default values', () {
        final result = calculator.calculateTapeLength(100.0);
        // (100 * 2.0) * 1.1 = 220.0
        expect(result, closeTo(220.0, 0.01));
      });

      test('calculates tape length with custom tape per m2', () {
        final result = calculator.calculateTapeLength(
          100.0,
          tapePerM2: 3.0,
        );
        // (100 * 3.0) * 1.1 = 330.0
        expect(result, closeTo(330.0, 0.01));
      });

      test('calculates tape length with custom margin', () {
        final result = calculator.calculateTapeLength(
          100.0,
          marginPercent: 20.0,
        );
        // (100 * 2.0) * 1.2 = 240.0
        expect(result, closeTo(240.0, 0.01));
      });

      test('handles zero area', () {
        final result = calculator.calculateTapeLength(0.0);
        expect(result, 0.0);
      });
    });

    group('calculateInsulationWeight', () {
      test('calculates weight correctly', () {
        final result = calculator.calculateInsulationWeight(10.0, 50.0);
        expect(result, 500.0); // 10 * 50
      });

      test('handles different density values', () {
        final result = calculator.calculateInsulationWeight(5.0, 100.0);
        expect(result, 500.0); // 5 * 100
      });

      test('handles zero volume', () {
        final result = calculator.calculateInsulationWeight(0.0, 50.0);
        expect(result, 0.0);
      });

      test('handles zero density', () {
        final result = calculator.calculateInsulationWeight(10.0, 0.0);
        expect(result, 0.0);
      });
    });

    group('calculateInsulationCost', () {
      test('calculates cost for insulation only', () {
        final result = calculator.calculateInsulationCost(
          insulationVolume: 10.0,
          insulationPrice: 1000.0,
        );
        expect(result, 10000.0); // 10 * 1000
      });

      test('calculates cost with all materials', () {
        final result = calculator.calculateInsulationCost(
          insulationVolume: 10.0,
          insulationPrice: 1000.0,
          vaporBarrierArea: 100.0,
          vaporBarrierPrice: 50.0,
          waterproofingArea: 100.0,
          waterproofingPrice: 60.0,
          fastenersCount: 500,
          fastenerPrice: 2.0,
          tapeLength: 200.0,
          tapePrice: 5.0,
        );
        // (10*1000) + (100*50) + (100*60) + (500*2) + (200*5) = 23000
        expect(result, 23000.0);
      });

      test('returns null if insulation price is null', () {
        final result = calculator.calculateInsulationCost(
          insulationVolume: 10.0,
          insulationPrice: null,
        );
        expect(result, null);
      });

      test('ignores zero area/count materials', () {
        final result = calculator.calculateInsulationCost(
          insulationVolume: 10.0,
          insulationPrice: 1000.0,
          vaporBarrierArea: 0.0,
          vaporBarrierPrice: 50.0,
          waterproofingArea: 0.0,
          waterproofingPrice: 60.0,
          fastenersCount: 0,
          fastenerPrice: 2.0,
          tapeLength: 0.0,
          tapePrice: 5.0,
        );
        expect(result, 10000.0); // Only insulation
      });

      test('handles null prices for optional materials', () {
        final result = calculator.calculateInsulationCost(
          insulationVolume: 10.0,
          insulationPrice: 1000.0,
          vaporBarrierArea: 100.0,
          vaporBarrierPrice: null,
          waterproofingArea: 100.0,
          waterproofingPrice: null,
        );
        // Main material has price, so returns that cost (ignores null optionals)
        expect(result, 10000.0);
      });
    });
  });
}
