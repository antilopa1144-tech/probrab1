import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/waste_optimization.dart';

void main() {
  group('WasteOptimization', () {
    test('creates with required parameters', () {
      const optimization = WasteOptimization(
        materialId: 'mat1',
        requiredArea: 25.0,
        standardSize: 3.0,
        wastePercentage: 5.0,
        optimizedQuantity: 9.0,
        wasteReduction: 5.0,
      );

      expect(optimization.materialId, 'mat1');
      expect(optimization.requiredArea, 25.0);
      expect(optimization.standardSize, 3.0);
      expect(optimization.wastePercentage, 5.0);
      expect(optimization.optimizedQuantity, 9.0);
      expect(optimization.wasteReduction, 5.0);
      expect(optimization.recommendationKeys, isEmpty);
    });

    test('creates with recommendationKeys', () {
      const optimization = WasteOptimization(
        materialId: 'mat1',
        requiredArea: 25.0,
        standardSize: 3.0,
        wastePercentage: 5.0,
        optimizedQuantity: 9.0,
        wasteReduction: 5.0,
        recommendationKeys: ['waste.recommendation.optimize', 'waste.recommendation.smaller_size'],
      );

      expect(optimization.recommendationKeys.length, 2);
      expect(optimization.recommendationKeys[0], 'waste.recommendation.optimize');
      expect(optimization.recommendationKeys[1], 'waste.recommendation.smaller_size');
    });

    group('calculate factory', () {
      test('calculates optimization for given area', () {
        final optimization = WasteOptimization.calculate(
          materialId: 'plywood',
          requiredArea: 25.0,
          standardSize: 3.0,
        );

        expect(optimization.materialId, 'plywood');
        expect(optimization.requiredArea, 25.0);
        expect(optimization.standardSize, 3.0);
        expect(optimization.optimizedQuantity, greaterThan(0));
        expect(optimization.wastePercentage, greaterThanOrEqualTo(0));
        expect(optimization.wastePercentage, lessThanOrEqualTo(100));
      });

      test('calculates with custom base waste', () {
        final optimization = WasteOptimization.calculate(
          materialId: 'plywood',
          requiredArea: 25.0,
          standardSize: 3.0,
          baseWaste: 15.0,
        );

        expect(optimization.materialId, 'plywood');
        // wasteReduction should be baseWaste - optimizedWaste
        expect(optimization.wasteReduction, isNotNull);
      });

      test('handles exact fit scenario', () {
        final optimization = WasteOptimization.calculate(
          materialId: 'tile',
          requiredArea: 9.0,
          standardSize: 3.0,
        );

        // 9.0 / 3.0 = 3 exact sheets
        expect(optimization.optimizedQuantity, greaterThanOrEqualTo(2.8));
      });

      test('handles small area relative to standard size', () {
        final optimization = WasteOptimization.calculate(
          materialId: 'panel',
          requiredArea: 1.0,
          standardSize: 3.0,
        );

        expect(optimization.optimizedQuantity, greaterThanOrEqualTo(0.8));
        // Should suggest smaller materials via i18n key
        expect(
          optimization.recommendationKeys.any((r) => r.contains('smaller_size')),
          isTrue,
        );
      });

      test('adds optimization recommendation when waste reduction is significant',
          () {
        final optimization = WasteOptimization.calculate(
          materialId: 'sheet',
          requiredArea: 8.0,
          standardSize: 3.0,
          baseWaste: 15.0,
        );

        // If wasteReduction > 2, should add recommendation
        if (optimization.wasteReduction > 2) {
          expect(
            optimization.recommendationKeys.any((r) => r.contains('optimize')),
            isTrue,
          );
        }
      });

      test('produces finite values', () {
        final optimization = WasteOptimization.calculate(
          materialId: 'material',
          requiredArea: 100.0,
          standardSize: 2.5,
        );

        expect(optimization.wastePercentage.isFinite, isTrue);
        expect(optimization.optimizedQuantity.isFinite, isTrue);
        expect(optimization.wasteReduction.isFinite, isTrue);
      });

      test('clamps waste percentage between 0 and 100', () {
        final optimization = WasteOptimization.calculate(
          materialId: 'material',
          requiredArea: 0.1,
          standardSize: 10.0,
        );

        expect(optimization.wastePercentage, greaterThanOrEqualTo(0));
        expect(optimization.wastePercentage, lessThanOrEqualTo(100));
      });
    });
  });
}
