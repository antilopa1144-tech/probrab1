import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/savings_calculation.dart';

void main() {
  group('SavingsCalculation', () {
    test('calculates savings correctly without hourly rate', () {
      final calc = SavingsCalculation.calculate(
        workType: 'plaster',
        materialCost: 5000.0,
        laborCost: 10000.0,
        selfWorkTimeHours: 20.0,
        hourlyRate: 0.0,
      );

      // Экономия = (5000 + 10000) - (5000 + 0) = 10000
      expect(calc.savings, equals(10000.0));
      expect(calc.timeCost, equals(0.0));
      expect(calc.isWorthIt, isTrue);
    });

    test('calculates savings with hourly rate', () {
      final calc = SavingsCalculation.calculate(
        workType: 'tile',
        materialCost: 8000.0,
        laborCost: 15000.0,
        selfWorkTimeHours: 30.0,
        hourlyRate: 500.0,
      );

      // timeCost = 30 * 500 = 15000
      // totalSelfCost = 8000 + 15000 = 23000
      // totalHiredCost = 8000 + 15000 = 23000
      // savings = 23000 - 23000 = 0
      expect(calc.timeCost, equals(15000.0));
      expect(calc.savings, equals(0.0));
    });

    test('isWorthIt returns false when savings negative', () {
      final calc = SavingsCalculation.calculate(
        workType: 'test',
        materialCost: 10000.0,
        laborCost: 5000.0, // дешевле нанять
        selfWorkTimeHours: 20.0,
        hourlyRate: 1000.0,
      );

      // timeCost = 20 * 1000 = 20000
      // totalSelfCost = 10000 + 20000 = 30000
      // totalHiredCost = 10000 + 5000 = 15000
      // savings = 15000 - 30000 = -15000
      expect(calc.savings, lessThan(0));
      expect(calc.isWorthIt, isFalse);
    });

    test('isWorthIt returns true when savings significant', () {
      final calc = SavingsCalculation.calculate(
        workType: 'test',
        materialCost: 5000.0,
        laborCost: 20000.0,
        selfWorkTimeHours: 10.0,
        hourlyRate: 500.0,
      );

      // timeCost = 10 * 500 = 5000
      // totalSelfCost = 5000 + 5000 = 10000
      // totalHiredCost = 5000 + 20000 = 25000
      // savings = 25000 - 10000 = 15000
      // savings > laborCost * 0.5 (10000) = true
      expect(calc.savings, equals(15000.0));
      expect(calc.isWorthIt, isTrue);
    });

    test('getRecommendation returns appropriate message', () {
      final calc1 = SavingsCalculation.calculate(
        workType: 'test',
        materialCost: 5000.0,
        laborCost: 20000.0,
        selfWorkTimeHours: 10.0,
        hourlyRate: 0.0,
      );

      expect(calc1.getRecommendation(), contains('Выгодно делать самостоятельно'));

      final calc2 = SavingsCalculation.calculate(
        workType: 'test',
        materialCost: 10000.0,
        laborCost: 5000.0,
        selfWorkTimeHours: 20.0,
        hourlyRate: 1000.0,
      );

      expect(calc2.getRecommendation(), contains('нанять мастеров'));
    });
  });

  group('MaterialPayback', () {
    test('calculates payback correctly', () {
      final payback = MaterialPayback.calculate(
        materialId: 'mat1',
        materialName: 'Premium Material',
        initialCost: 10000.0,
        alternativeCost: 5000.0,
        durabilityYears: 20,
        alternativeDurabilityYears: 10,
      );

      // costPerYear = 10000 / 20 = 500
      // altCostPerYear = 5000 / 10 = 500
      // annualSavings = 500 - 500 = 0
      // costDifference = 10000 - 5000 = 5000
      // paybackYears = 5000 / 0 = infinity
      expect(payback.annualSavings, equals(0.0));
    });

    test('calculates payback with savings', () {
      final payback = MaterialPayback.calculate(
        materialId: 'mat2',
        materialName: 'Long Lasting',
        initialCost: 20000.0,
        alternativeCost: 10000.0,
        durabilityYears: 20,
        alternativeDurabilityYears: 5,
      );

      // costPerYear = 20000 / 20 = 1000
      // altCostPerYear = 10000 / 5 = 2000
      // annualSavings = 2000 - 1000 = 1000
      // costDifference = 20000 - 10000 = 10000
      // paybackYears = 10000 / 1000 = 10
      expect(payback.annualSavings, equals(1000.0));
      expect(payback.paybackYears, equals(10.0));
    });

    test('getRecommendation returns appropriate message', () {
      final payback2 = MaterialPayback(
        materialId: 'mat2',
        materialName: 'Test',
        initialCost: 10000.0,
        alternativeCost: 5000.0,
        durabilityYears: 10,
        alternativeDurabilityYears: 5,
        annualSavings: 500.0,
        paybackYears: 1.5,
      );

      expect(payback2.getRecommendation(), contains('Отличная инвестиция'));

      final payback3 = MaterialPayback(
        materialId: 'mat3',
        materialName: 'Test',
        initialCost: 10000.0,
        alternativeCost: 5000.0,
        durabilityYears: 10,
        alternativeDurabilityYears: 5,
        annualSavings: 500.0,
        paybackYears: 3.0,
      );

      expect(payback3.getRecommendation(), contains('Хорошая инвестиция'));

      final payback4 = MaterialPayback(
        materialId: 'mat4',
        materialName: 'Test',
        initialCost: 10000.0,
        alternativeCost: 5000.0,
        durabilityYears: 10,
        alternativeDurabilityYears: 5,
        annualSavings: 500.0,
        paybackYears: 10.0,
      );

      expect(payback4.getRecommendation(), contains('Долгосрочная инвестиция'));
    });

    test('handles infinite payback', () {
      final payback = MaterialPayback(
        materialId: 'mat1',
        materialName: 'Test',
        initialCost: 10000.0,
        alternativeCost: 5000.0,
        durabilityYears: 10,
        alternativeDurabilityYears: 5,
        annualSavings: 0.0,
        paybackYears: double.infinity,
      );

      expect(payback.getRecommendation(), contains('Альтернативный вариант дешевле'));
    });
  });
}
