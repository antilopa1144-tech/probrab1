import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/labor_cost.dart';

void main() {
  group('LaborCostCalculation', () {
    const baseRate = LaborRate(
      category: 'Отделка',
      region: 'Москва',
      pricePerUnit: 500,
      unit: 'м²',
      minPrice: 5000,
    );

    test('calculates cost above minimum correctly', () {
      final calc = LaborCostCalculation.fromCalculator(
        'walls_paint',
        20, // м²
        baseRate,
      );

      expect(calc.totalCost, 10000); // 20 * 500
      expect(calc.estimatedHours, 10); // 20 * 0.5
      expect(calc.estimatedDays, 2); // ceil(10 / 8)
    });

    test('applies minimum price when necessary', () {
      final calc = LaborCostCalculation.fromCalculator(
        'walls_paint',
        2, // 2 * 500 = 1000 < minPrice
        baseRate,
      );

      expect(calc.totalCost, baseRate.minPrice);
      expect(calc.estimatedHours, equals(1)); // ceil(2 * 0.5)
      expect(calc.estimatedDays, equals(1));
    });

    test('uses calculator-specific productivity', () {
      const tileRate = LaborRate(
        category: 'Отделка',
        region: 'Москва',
        pricePerUnit: 600,
        unit: 'м²',
        minPrice: 6000,
      );

      final calc = LaborCostCalculation.fromCalculator(
        'floors_tile',
        15,
        tileRate,
      );

      // floors_tile uses 0.6 hours per m² (see _getHoursPerUnit)
      expect(calc.estimatedHours, equals((15 * 0.6).ceil()));
      expect(calc.estimatedDays, equals(((15 * 0.6).ceil() / 8).ceil()));
    });
  });
}
