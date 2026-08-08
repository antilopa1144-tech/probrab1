import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/services/calculator_engine.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';

void main() {
  group('CalculatorEngine', () {
    test('every custom screen id has a registered screen engine', () {
      final missing = <String>[];
      for (final id in CalculatorScreenRegistry.registeredIds) {
        if (id == 'sheeting_osb_plywood' ||
            id == 'paint_universal' ||
            id == 'paint' ||
            id == 'wood' ||
            id == 'floors_screed' ||
            id == 'dsp' ||
            // Landscape-калькуляторы используют CanonicalBridgeUseCase
            // напрямую из definition (Pro-only path), screen-engine не нужен.
            id == 'lawn' ||
            id == 'drainage' ||
            id == 'greenhouse' ||
            id == 'paving_tiles' ||
            id == 'septic_rings') {
          continue;
        }
        if (!CalculatorEngine.screenEngines.containsKey(id)) {
          missing.add(id);
        }
      }
      expect(
        missing,
        isEmpty,
        reason: 'Add engines for: ${missing.join(', ')}',
      );
    });

    test(
      'catalog useCase matches screen engine for registered calculators',
      () {
        final mismatched = <String>[];
        for (final entry in CalculatorEngine.screenEngines.entries) {
          final definition = CalculatorRegistry.getById(entry.key);
          if (definition == null) {
            mismatched.add('${entry.key}: no definition');
            continue;
          }
          if (!identical(definition.useCase, entry.value)) {
            mismatched.add('${entry.key}: ${definition.useCase.runtimeType}');
          }
        }
        expect(
          mismatched,
          isEmpty,
          reason: 'Registry not aligned: ${mismatched.join('; ')}',
        );
      },
    );

    test('resolve returns definition useCase for Pro-only calculators', () {
      final lawn = CalculatorRegistry.getById('lawn');
      expect(lawn, isNotNull);
      expect(
        identical(CalculatorEngine.resolve('lawn'), lawn!.useCase),
        isTrue,
      );
    });

    test('foundation slab resolves to the canonical catalog useCase', () {
      final slab = CalculatorRegistry.getById('foundation_slab');
      expect(slab, isNotNull);
      expect(
        identical(CalculatorEngine.resolve('foundation_slab'), slab!.useCase),
        isTrue,
      );
      expect(
        CalculatorEngine.screenEngines,
        isNot(contains('foundation_slab')),
      );
    });

    test('calculate smoke: attic with default-like inputs', () {
      final result = CalculatorEngine.calculate('attic', {
        'floorLength': 8.0,
        'floorWidth': 6.0,
        'roofHeight': 2.5,
        'insulationThickness': 150.0,
        'atticType': 1.0,
        'insulationType': 0.0,
        'needVaporBarrier': 1.0,
        'needMembrane': 1.0,
        'needGypsum': 1.0,
      });
      expect(result.values, isNotEmpty);
    });
  });
}
