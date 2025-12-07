import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/material_comparison.dart';

void main() {
  group('MaterialOption', () {
    test('calculates total cost correctly', () {
      const option = MaterialOption(
        id: 'opt1',
        name: 'Option 1',
        category: 'test',
        pricePerUnit: 100.0,
        unit: 'м²',
      );

      expect(option.calculateTotalCost(10.0), equals(1000.0));
      expect(option.calculateTotalCost(5.5), equals(550.0));
    });

    test('calculates cost per year correctly', () {
      const option = MaterialOption(
        id: 'opt1',
        name: 'Option 1',
        category: 'test',
        pricePerUnit: 100.0,
        unit: 'м²',
        durabilityYears: 10,
      );

      // 100 * 10 / 10 = 100 в год
      expect(option.getCostPerYear(10.0), equals(100.0));
    });

    test('handles zero durability years', () {
      const option = MaterialOption(
        id: 'opt1',
        name: 'Option 1',
        category: 'test',
        pricePerUnit: 100.0,
        unit: 'м²',
        durabilityYears: 0,
      );

      expect(option.getCostPerYear(10.0), equals(double.infinity));
    });

    test('handles negative durability years', () {
      const option = MaterialOption(
        id: 'opt1',
        name: 'Option 1',
        category: 'test',
        pricePerUnit: 100.0,
        unit: 'м²',
        durabilityYears: -5,
      );

      expect(option.getCostPerYear(10.0), equals(double.infinity));
    });
  });

  group('MaterialComparison', () {
    test('finds cheapest option', () {
      final options = [
        const MaterialOption(
          id: 'opt1',
          name: 'Expensive',
          category: 'test',
          pricePerUnit: 200.0,
          unit: 'м²',
        ),
        const MaterialOption(
          id: 'opt2',
          name: 'Cheap',
          category: 'test',
          pricePerUnit: 100.0,
          unit: 'м²',
        ),
        const MaterialOption(
          id: 'opt3',
          name: 'Medium',
          category: 'test',
          pricePerUnit: 150.0,
          unit: 'м²',
        ),
      ];

      final comparison = MaterialComparison(
        calculatorId: 'test',
        requiredQuantity: 10.0,
        options: options,
      );

      expect(comparison.cheapest?.id, equals('opt2'));
      expect(comparison.cheapest?.pricePerUnit, equals(100.0));
    });

    test('returns null for cheapest when options empty', () {
      const comparison = MaterialComparison(
        calculatorId: 'test',
        requiredQuantity: 10.0,
        options: [],
      );

      expect(comparison.cheapest, isNull);
    });

    test('finds most durable option', () {
      final options = [
        const MaterialOption(
          id: 'opt1',
          name: 'Short',
          category: 'test',
          pricePerUnit: 100.0,
          unit: 'м²',
          durabilityYears: 5,
        ),
        const MaterialOption(
          id: 'opt2',
          name: 'Long',
          category: 'test',
          pricePerUnit: 150.0,
          unit: 'м²',
          durabilityYears: 20,
        ),
        const MaterialOption(
          id: 'opt3',
          name: 'Medium',
          category: 'test',
          pricePerUnit: 120.0,
          unit: 'м²',
          durabilityYears: 10,
        ),
      ];

      final comparison = MaterialComparison(
        calculatorId: 'test',
        requiredQuantity: 10.0,
        options: options,
      );

      expect(comparison.mostDurable?.id, equals('opt2'));
      expect(comparison.mostDurable?.durabilityYears, equals(20));
    });

    test('finds optimal option (balance price/quality)', () {
      final options = [
        const MaterialOption(
          id: 'opt1',
          name: 'Cheap but short',
          category: 'test',
          pricePerUnit: 50.0,
          unit: 'м²',
          durabilityYears: 5, // 50*10/5 = 100 в год
        ),
        const MaterialOption(
          id: 'opt2',
          name: 'Expensive but long',
          category: 'test',
          pricePerUnit: 200.0,
          unit: 'м²',
          durabilityYears: 20, // 200*10/20 = 100 в год
        ),
        const MaterialOption(
          id: 'opt3',
          name: 'Optimal',
          category: 'test',
          pricePerUnit: 100.0,
          unit: 'м²',
          durabilityYears: 15, // 100*10/15 = 66.67 в год
        ),
      ];

      final comparison = MaterialComparison(
        calculatorId: 'test',
        requiredQuantity: 10.0,
        options: options,
      );

      expect(comparison.optimal?.id, equals('opt3'));
    });

    test('returns null for optimal when options empty', () {
      const comparison = MaterialComparison(
        calculatorId: 'test',
        requiredQuantity: 10.0,
        options: [],
      );

      expect(comparison.optimal, isNull);
    });
  });
}
