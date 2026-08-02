import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/gutters_canonical_adapter.dart';

void main() {
  const standardInputs = <String, double>{
    'roofPerimeter': 20,
    'roofArea': 100,
    'roofHeight': 5,
    'funnels': 2,
    'systemType': 1,
    'gutterLength': 3,
    'gutterSections': 2,
    'gutterCornerCount': 0,
    'endCapCount': 4,
    'hasEaveOffset': 1,
    'accuracyMode': 0,
  };

  group('calculateCanonicalGutters v2', () {
    test('matches the canonical web baseline', () {
      final result = calculateCanonicalGutters(standardInputs);

      expect(result.formulaVersion, 'gutters-canonical-v2');
      expect(result.totals['gutterExactPcs'], 6.667);
      expect(result.totals['gutterPcs'], 8);
      expect(result.totals['pipeExactPcs'], 3.333);
      expect(result.totals['pipePcs'], 4);
      expect(result.totals['pipeCouplings'], 2);
      expect(result.totals['gutterJoints'], 6);
      expect(result.totals['gutterHooks'], 46);
      expect(result.totals['pipeClamps'], 9);
      expect(result.totals['kneeElbows'], 4);
      expect(result.totals['drainOutlets'], 2);
      expect(result.totals['recommendedFunnels'], 2);
      expect(result.scenarios['REC']!.exactNeed, 7.42);
      expect(result.scenarios['REC']!.purchaseQuantity, 8);
      expect(result.materials, hasLength(10));
      expect(result.warnings, isEmpty);
    });

    test('does not invent corners or include sealant', () {
      final result = calculateCanonicalGutters(standardInputs);
      final names = result.materials.map((material) => material.name).toList();

      expect(names.any((name) => name.contains('Угловые элементы')), isFalse);
      expect(names.any((name) => name.contains('Герметик')), isFalse);
      expect(
        names.any((name) => name.contains('Муфты соединительные')),
        isTrue,
      );
      expect(names.any((name) => name.contains('Водосточные сливы')), isTrue);
    });

    test('warns when long gutter runs need more funnels', () {
      final result = calculateCanonicalGutters({
        ...standardInputs,
        'roofPerimeter': 50,
        'funnels': 2,
      });

      expect(result.totals['recommendedFunnelsByArea'], 2);
      expect(result.totals['recommendedFunnelsByLength'], 6);
      expect(result.totals['recommendedFunnels'], 6);
      expect(result.warnings.single, contains('минимум 6'));
    });

    test('keeps legacy diameter input compatible', () {
      final normalized = normalizeLegacyGuttersInputs({
        'roofPerimeter': 20,
        'gutterDia': 125,
      });

      expect(normalized['systemType'], 2);
      expect(normalized['roofArea'], 100);
      expect(normalized['gutterSections'], 2);
    });
  });
}
