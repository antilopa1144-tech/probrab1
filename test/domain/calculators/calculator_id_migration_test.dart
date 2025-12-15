import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_id_migration.dart';

void main() {
  group('CalculatorIdMigration', () {
    test('canonicalize maps known legacy IDs', () {
      expect(CalculatorIdMigration.canonicalize('walls_paint'), 'wall_paint');
      expect(
        CalculatorIdMigration.canonicalize('calculator.stripTitle'),
        'foundation_strip',
      );
      expect(
        CalculatorIdMigration.canonicalize('strip_foundation'),
        'foundation_strip',
      );
      expect(
        CalculatorIdMigration.canonicalize('slab_foundation'),
        'foundation_slab',
      );
      expect(
        CalculatorIdMigration.canonicalize('basement'),
        'foundation_basement',
      );
      expect(
        CalculatorIdMigration.canonicalize('blind_area'),
        'foundation_blind_area',
      );
      expect(
        CalculatorIdMigration.canonicalize('warm_floor'),
        'floors_warm',
      );
      expect(
        CalculatorIdMigration.canonicalize('heating'),
        'engineering_heating',
      );
    });

    test('canonicalize returns input for unknown IDs', () {
      expect(CalculatorIdMigration.canonicalize('floors_tile'), 'floors_tile');
      expect(CalculatorIdMigration.canonicalize('unknown'), 'unknown');
    });

    test('canonicalizeList maps and dedupes', () {
      final result = CalculatorIdMigration.canonicalizeList([
        'walls_paint',
        'wall_paint',
        'strip_foundation',
        'foundation_strip',
      ]);
      expect(result, ['wall_paint', 'foundation_strip']);
    });
  });
}

