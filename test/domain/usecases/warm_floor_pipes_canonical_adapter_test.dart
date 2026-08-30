import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_pipes_canonical_adapter.dart';

void main() {
  group('calculateCanonicalWarmFloorPipes v2', () {
    test('считает геометрию без скрытых процентов и материалов', () {
      final result = calculateCanonicalWarmFloorPipes({});

      expect(result.formulaVersion, 'warm-floor-pipes-canonical-v2');
      expect(result.totals['layoutAreaM2'], 15);
      expect(result.totals['pipeSpacingMm'], 150);
      expect(result.totals['fieldPipeLengthM'], 100);
      expect(result.totals['exactPipeLengthM'], 100);
      expect(result.totals['purchasePipeLengthM'], 100);
      expect(result.materials, hasLength(1));
      expect(
        result.materials.single.name,
        contains('предварительная геометрия'),
      );
      expect(result.materials.single.packageInfo, isNull);
    });

    test('прибавляет только явно введённые подводки', () {
      final result = calculateCanonicalWarmFloorPipes({
        'layoutAreaM2': 15,
        'pipeSpacingMm': 150,
        'connectionLengthM': 6,
      });

      expect(result.totals['fieldPipeLengthM'], 100);
      expect(result.totals['exactPipeLengthM'], 106);
      expect(result.scenarios['REC']!.exactNeed, 106);
    });

    test('принимает проектную ведомость и фактическую бухту', () {
      final result = calculateCanonicalWarmFloorPipes({
        'calculationMode': 1,
        'projectTotalPipeLengthM': 260,
        'circuitCount': 3,
        'longestCircuitLengthM': 92,
        'maxCircuitLengthM': 90,
        'coilLengthM': 200,
        'collectorCount': 1,
        'manifoldOutletCount': 3,
      });

      expect(result.totals['averageCircuitLengthM'], closeTo(86.667, 0.001));
      expect(result.totals['requiredCoilCount'], 2);
      expect(result.totals['purchasePipeLengthM'], 400);
      expect(result.totals['leftoverPipeLengthM'], 140);
      expect(result.materials, hasLength(2));
      expect(result.materials.first.packageInfo, {
        'count': 2,
        'size': 200,
        'packageUnit': 'бухт',
      });
      expect(
        result.warnings.any((warning) => warning.contains('превышает предел')),
        isTrue,
      );
    });

    test('не выдаёт общую длину за план раскроя непрерывных петель', () {
      final result = calculateCanonicalWarmFloorPipes({
        'calculationMode': 1,
        'projectTotalPipeLengthM': 150,
        'circuitCount': 2,
        'longestCircuitLengthM': 110,
        'coilLengthM': 100,
      });

      expect(result.totals['requiredCoilCount'], 2);
      expect(result.warnings.join(' '), contains('не проверяет план раскроя'));
      expect(
        result.warnings.join(' '),
        contains('больше одной выбранной бухты'),
      );
    });

    test('MIN REC MAX совпадают без универсального запаса', () {
      final result = calculateCanonicalWarmFloorPipes({
        'layoutAreaM2': 20,
        'pipeSpacingMm': 200,
        'connectionLengthM': 5,
        'coilLengthM': 50,
      });

      for (final scenario in result.scenarios.values) {
        expect(scenario.exactNeed, 105);
        expect(scenario.purchaseQuantity, 150);
        expect(scenario.leftover, 45);
        expect(scenario.assumptions, contains('no_hidden_reserve'));
      }
    });

    test('не добавляет ЭППС крепёж ленту и стяжку', () {
      final names = calculateCanonicalWarmFloorPipes(
        {},
      ).materials.map((material) => material.name).join(' ');

      expect(names, isNot(contains('ЭППС')));
      expect(names, isNot(contains('Клипс')));
      expect(names, isNot(contains('лент')));
      expect(names, isNot(contains('Стяж')));
      expect(names, isNot(contains('Коллектор')));
    });

    test('проверяет коллектор только по явно введённой ведомости', () {
      final missingCollector = calculateCanonicalWarmFloorPipes({
        'calculationMode': 1,
        'projectTotalPipeLengthM': 180,
        'circuitCount': 3,
        'manifoldOutletCount': 3,
      });
      final tooFewOutlets = calculateCanonicalWarmFloorPipes({
        'calculationMode': 1,
        'projectTotalPipeLengthM': 180,
        'circuitCount': 3,
        'collectorCount': 1,
        'manifoldOutletCount': 2,
      });

      expect(missingCollector.warnings.join(' '), contains('без количества'));
      expect(
        tooFewOutlets.warnings.join(' '),
        contains('меньше числа контуров'),
      );
    });
  });
}
