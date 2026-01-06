import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/material_comparison_provider.dart';
import 'package:probrab_ai/domain/entities/material_comparison.dart';

void main() {
  group('MaterialComparisonNotifier', () {
    test('starts with empty list', () {
      final notifier = MaterialComparisonNotifier();
      expect(notifier.state, isEmpty);
    });

    test('addComparison adds comparison to state', () {
      final notifier = MaterialComparisonNotifier();

      const comparison = MaterialComparison(
        calculatorId: 'calc1',
        requiredQuantity: 100,
        options: [
          MaterialOption(
            id: 'opt1',
            name: 'Option 1',
            category: 'category1',
            pricePerUnit: 50,
            unit: 'м²',
          ),
        ],
      );

      notifier.addComparison(comparison);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.calculatorId, 'calc1');
      expect(notifier.state.first.requiredQuantity, 100);
    });

    test('addComparison adds multiple comparisons', () {
      final notifier = MaterialComparisonNotifier();

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc1',
        requiredQuantity: 100,
        options: [],
      ));

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc2',
        requiredQuantity: 200,
        options: [],
      ));

      expect(notifier.state.length, 2);
      expect(notifier.state[0].calculatorId, 'calc1');
      expect(notifier.state[1].calculatorId, 'calc2');
    });

    test('removeComparison removes comparison from state', () {
      final notifier = MaterialComparisonNotifier();

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc1',
        requiredQuantity: 100,
        options: [],
      ));

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc2',
        requiredQuantity: 200,
        options: [],
      ));

      notifier.removeComparison('calc1');

      expect(notifier.state.length, 1);
      expect(notifier.state.first.calculatorId, 'calc2');
    });

    test('removeComparison does not affect other comparisons', () {
      final notifier = MaterialComparisonNotifier();

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc1',
        requiredQuantity: 100,
        options: [],
      ));

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc2',
        requiredQuantity: 200,
        options: [],
      ));

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc3',
        requiredQuantity: 300,
        options: [],
      ));

      notifier.removeComparison('calc2');

      expect(notifier.state.length, 2);
      expect(notifier.state[0].calculatorId, 'calc1');
      expect(notifier.state[1].calculatorId, 'calc3');
    });

    test('removeComparison handles non-existent id gracefully', () {
      final notifier = MaterialComparisonNotifier();

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc1',
        requiredQuantity: 100,
        options: [],
      ));

      notifier.removeComparison('non-existent');

      expect(notifier.state.length, 1);
      expect(notifier.state.first.calculatorId, 'calc1');
    });

    test('getComparison returns comparison by id', () {
      final notifier = MaterialComparisonNotifier();

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc1',
        requiredQuantity: 100,
        options: [],
      ));

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc2',
        requiredQuantity: 200,
        options: [],
      ));

      final comparison = notifier.getComparison('calc2');

      expect(comparison, isNotNull);
      expect(comparison!.calculatorId, 'calc2');
      expect(comparison.requiredQuantity, 200);
    });

    test('getComparison returns null for non-existent id', () {
      final notifier = MaterialComparisonNotifier();

      notifier.addComparison(const MaterialComparison(
        calculatorId: 'calc1',
        requiredQuantity: 100,
        options: [],
      ));

      final comparison = notifier.getComparison('non-existent');

      expect(comparison, isNull);
    });

    test('handles complex comparison with multiple options', () {
      final notifier = MaterialComparisonNotifier();

      const comparison = MaterialComparison(
        calculatorId: 'wall-paint',
        requiredQuantity: 50,
        options: [
          MaterialOption(
            id: 'opt1',
            name: 'Budget Paint',
            category: 'paint',
            pricePerUnit: 100,
            unit: 'л',
            durabilityYears: 5,
            supplier: 'Supplier A',
          ),
          MaterialOption(
            id: 'opt2',
            name: 'Premium Paint',
            category: 'paint',
            pricePerUnit: 200,
            unit: 'л',
            durabilityYears: 10,
            supplier: 'Supplier B',
          ),
          MaterialOption(
            id: 'opt3',
            name: 'Eco Paint',
            category: 'paint',
            pricePerUnit: 150,
            unit: 'л',
            durabilityYears: 8,
            supplier: 'Supplier C',
            notes: 'Environmentally friendly',
          ),
        ],
        recommended: MaterialOption(
          id: 'opt2',
          name: 'Premium Paint',
          category: 'paint',
          pricePerUnit: 200,
          unit: 'л',
          durabilityYears: 10,
          supplier: 'Supplier B',
        ),
      );

      notifier.addComparison(comparison);

      final stored = notifier.getComparison('wall-paint');
      expect(stored, isNotNull);
      expect(stored!.options.length, 3);
      expect(stored.recommended, isNotNull);
      expect(stored.recommended!.name, 'Premium Paint');
    });
  });
}
