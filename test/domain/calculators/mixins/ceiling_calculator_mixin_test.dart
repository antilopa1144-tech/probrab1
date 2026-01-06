import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/mixins/ceiling_calculator_mixin.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/data/models/price_item.dart';

// Test implementation of BaseCalculator with CeilingCalculatorMixin
class TestCeilingCalculator extends BaseCalculator with CeilingCalculatorMixin {
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
  late TestCeilingCalculator calculator;

  setUp(() {
    calculator = TestCeilingCalculator();
  });

  group('CeilingCalculatorMixin', () {
    group('calculateCeilingArea', () {
      test('calculates ceiling area with default margin', () {
        final result = calculator.calculateCeilingArea(100.0);
        expect(result, closeTo(110.0, 0.01)); // 100 * 1.1
      });

      test('calculates ceiling area with custom margin', () {
        final result = calculator.calculateCeilingArea(
          100.0,
          marginPercent: 15.0,
        );
        expect(result, closeTo(115.0, 0.01)); // 100 * 1.15
      });

      test('handles zero area', () {
        final result = calculator.calculateCeilingArea(
          0.0,
          marginPercent: 10.0,
        );
        expect(result, 0.0);
      });
    });

    group('calculateSheetsNeeded', () {
      test('calculates sheets needed with default margin', () {
        final result = calculator.calculateSheetsNeeded(100.0, 3.0);
        expect(result, 37); // ceil((100 / 3) * 1.1)
      });

      test('calculates sheets needed with custom margin', () {
        final result = calculator.calculateSheetsNeeded(
          100.0,
          3.0,
          marginPercent: 5.0,
        );
        expect(result, 35); // ceil((100 / 3) * 1.05)
      });

      test('handles zero sheet area', () {
        final result = calculator.calculateSheetsNeeded(100.0, 0.0);
        expect(result, 0);
      });

      test('handles exact division', () {
        final result = calculator.calculateSheetsNeeded(
          90.0,
          3.0,
          marginPercent: 0.0,
        );
        expect(result, 30); // ceil(90 / 3)
      });
    });

    group('calculateProfileLength', () {
      test('calculates profile length with default spacing and margin', () {
        final result = calculator.calculateProfileLength(100.0);
        // Complex calculation based on area and default spacing 0.6m
        expect(result, greaterThan(0.0));
      });

      test('calculates profile length with custom spacing', () {
        final result = calculator.calculateProfileLength(
          100.0,
          profileSpacing: 1.0,
        );
        expect(result, greaterThan(0.0));
      });

      test('calculates profile length with custom margin', () {
        final result = calculator.calculateProfileLength(
          100.0,
          marginPercent: 20.0,
        );
        expect(result, greaterThan(0.0));
      });

      test('handles zero area', () {
        final result = calculator.calculateProfileLength(0.0);
        expect(result, 0.0);
      });
    });

    group('calculateSuspensionsNeeded', () {
      test('calculates suspensions with default spacing', () {
        final result = calculator.calculateSuspensionsNeeded(100.0);
        // (100 / (0.6 * 0.6)) = ceil(277.77) = 278
        expect(result, 278);
      });

      test('calculates suspensions with custom spacing', () {
        final result = calculator.calculateSuspensionsNeeded(
          100.0,
          suspensionSpacing: 1.0,
        );
        // (100 / (1.0 * 1.0)) = 100
        expect(result, 100);
      });

      test('handles zero area', () {
        final result = calculator.calculateSuspensionsNeeded(0.0);
        expect(result, 0);
      });

      test('handles zero spacing', () {
        final result = calculator.calculateSuspensionsNeeded(
          100.0,
          suspensionSpacing: 0.0,
        );
        expect(result, 0);
      });
    });

    group('calculateScrewsNeeded', () {
      test('calculates screws with default values', () {
        final result = calculator.calculateScrewsNeeded(100);
        // (100 sheets * 25 screws/sheet) * 1.1 = 2750
        expect(result, 2750);
      });

      test('calculates screws with custom screws per sheet', () {
        final result = calculator.calculateScrewsNeeded(
          100,
          screwsPerSheet: 30,
        );
        // ceil((100 * 30) * 1.1) = 3300
        expect(result, greaterThanOrEqualTo(3300));
        expect(result, lessThanOrEqualTo(3301));
      });

      test('calculates screws with custom margin', () {
        final result = calculator.calculateScrewsNeeded(
          100,
          marginPercent: 20.0,
        );
        // (100 * 25) * 1.2 = 3000
        expect(result, 3000);
      });

      test('handles zero sheets', () {
        final result = calculator.calculateScrewsNeeded(0);
        expect(result, 0);
      });
    });

    group('calculateCeilingCost', () {
      test('calculates cost for sheets only', () {
        final result = calculator.calculateCeilingCost(
          sheetsArea: 30.0,
          sheetPrice: 500.0,
        );
        expect(result, 15000.0); // 30 * 500
      });

      test('calculates cost with all materials', () {
        final result = calculator.calculateCeilingCost(
          sheetsArea: 30.0,
          sheetPrice: 500.0,
          profileLength: 50.0,
          profilePrice: 100.0,
          suspensionsCount: 100,
          suspensionPrice: 10.0,
          screwsCount: 500,
          screwPrice: 1.0,
        );
        // (30*500) + (50*100) + (100*10) + (500*1) = 21500
        expect(result, 21500.0);
      });

      test('returns null if sheet price is null', () {
        final result = calculator.calculateCeilingCost(
          sheetsArea: 30.0,
          sheetPrice: null,
        );
        expect(result, null);
      });

      test('ignores zero count materials', () {
        final result = calculator.calculateCeilingCost(
          sheetsArea: 30.0,
          sheetPrice: 500.0,
          profileLength: 0.0,
          profilePrice: 100.0,
          suspensionsCount: 0,
          suspensionPrice: 10.0,
        );
        expect(result, 15000.0); // Only sheets
      });

      test('handles null prices for optional materials', () {
        final result = calculator.calculateCeilingCost(
          sheetsArea: 30.0,
          sheetPrice: 500.0,
          profileLength: 50.0,
          profilePrice: null,
          suspensionsCount: 100,
          suspensionPrice: null,
        );
        // Main material has price, so returns that cost (ignores null optionals)
        expect(result, 15000.0);
      });
    });
  });
}
