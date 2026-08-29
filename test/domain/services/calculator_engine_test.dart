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

    test('concrete screen engine uses the canonical v3 purchase contract', () {
      final result = CalculatorEngine.calculate('concrete_universal', {
        'inputMode': 0,
        'concreteVolume': 1,
        'concreteGrade': 3,
        'manualMix': 1,
        'readyMixOrderStepM3': 0.5,
        'reserve': 5,
      });

      expect(result.primaryTotals?['recExactNeedM3'], closeTo(1.05, 1e-9));
      expect(
        result.materials?.map((material) => material.name),
        containsAll(['Цемент М400 (50 кг)', 'Песок строительный', 'Щебень']),
      );
      expect(result.norms.join(' '), contains('не рецепт'));
      expect(result.values.keys.join(' '), isNot(contains('formwork')));
      expect(result.values.keys.join(' '), isNot(contains('rebar')));
    });

    test('strip foundation route uses the canonical v3 purchase contract', () {
      final result = CalculatorEngine.calculate('foundation_strip', {
        'perimeter': 40,
        'width': 400,
        'depth': 700,
        'aboveGround': 300,
        'formworkHeight': 300,
        'reserve': 5,
        'readyMixOrderStepM3': 0.5,
        'deliveryAllowanceM3': 0.35,
        'reinforcement': 1,
        'clampStepMm': 400,
        'concreteCoverMm': 50,
        'clampHookAllowanceMm': 300,
        'rebarReserve': 12,
        'rodLengthM': 11.7,
        'formworkReserve': 10,
      });

      expect(result.primaryTotals?['recExactNeedM3'], closeTo(17.15, 1e-9));
      expect(result.primaryTotals?['recPurchaseM3'], 17.5);
      expect(result.primaryTotals?['longBars'], 16);
      expect(
        result.materials
            ?.firstWhere((material) => material.name.contains('продольная'))
            .packageInfo?['count'],
        16,
      );
      expect(result.values.keys.join(' '), isNot(contains('sandVolume')));
      expect(result.values.keys.join(' '), isNot(contains('fbsBlocksCount')));
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
