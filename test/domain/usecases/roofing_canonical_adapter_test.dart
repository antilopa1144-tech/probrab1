import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/roofing_canonical_adapter.dart';

void main() {
  const baseInputs = <String, double>{
    'roofAreaMode': 0,
    'projectSlopeAreaM2': 100,
    'planProjectionAreaM2': 80,
    'slopeDeg': 30,
    'roofingType': 0,
    'primaryCoverageM2': 2.5,
    'primaryReservePercent': 10,
  };

  group('calculateCanonicalRoofing v3', () {
    test('uses project slope area and actual useful coverage', () {
      final result = calculateCanonicalRoofing(baseInputs);
      final covering = result.materials.single;

      expect(result.formulaVersion, 'roofing-canonical-v3');
      expect(result.totals['selectedSlopeAreaM2'], 100);
      expect(result.totals['primaryUnits'], 44);
      expect(covering.quantity, 100);
      expect(covering.withReserve, 110);
      expect(covering.purchaseQty, 110);
      expect(covering.packageInfo?['count'], 44);
      expect(covering.packageInfo?['packageUnit'], 'листов');
    });

    test('uses explicit MIN REC MAX reserve only for primary covering', () {
      final result = calculateCanonicalRoofing(baseInputs);

      expect(result.scenarios['MIN']?.exactNeed, 40);
      expect(result.scenarios['REC']?.exactNeed, 44);
      expect(result.scenarios['MAX']?.exactNeed, 46);
      expect(result.scenarios['MAX']?.keyFactors['reserve_percent'], 15);
    });

    test('calculates simple projection mode with an explicit warning', () {
      final result = calculateCanonicalRoofing({
        ...baseInputs,
        'roofAreaMode': 1,
      });

      expect(result.totals['selectedSlopeAreaM2'], closeTo(92.376, 0.001));
      expect(
        result.warnings.any(
          (warning) => warning.contains('одно- или двухскатной'),
        ),
        isTrue,
      );
    });

    test('does not invent secondary materials from roof area', () {
      final result = calculateCanonicalRoofing(baseInputs);
      final names = result.materials.map((material) => material.name).join(' ');

      expect(names, isNot(contains('Снегозадерж')));
      expect(names, isNot(contains('Обрешётка')));
      expect(names, isNot(contains('мембрана')));
      expect(names, isNot(contains('Крепёж')));
      expect(result.totals, isNot(contains('perimeterEst')));
    });

    test('requires useful coverage of selected product', () {
      final result = calculateCanonicalRoofing({
        ...baseInputs,
        'primaryCoverageM2': 0,
      });

      expect(result.materials, isEmpty);
      expect(result.scenarios['REC']?.purchaseQuantity, 0);
      expect(
        result.warnings.any((warning) => warning.contains('полезную площадь')),
        isTrue,
      );
    });

    test('uses packages for soft roofing and pieces for ceramic tiles', () {
      final soft = calculateCanonicalRoofing({
        ...baseInputs,
        'roofingType': 1,
        'primaryCoverageM2': 3,
      });
      final ceramic = calculateCanonicalRoofing({
        ...baseInputs,
        'roofingType': 5,
        'primaryCoverageM2': 0.077,
      });

      expect(soft.materials.first.packageInfo?['packageUnit'], 'упаковок');
      expect(ceramic.materials.first.packageInfo?['packageUnit'], 'шт');
      expect(ceramic.materials.first.packageInfo?['count'], 1429);
    });

    test('rounds project lines by actual package sizes', () {
      final result = calculateCanonicalRoofing({
        ...baseInputs,
        'ridgeProjectM': 8,
        'ridgeElementUsefulLengthM': 1.9,
        'membraneProjectAreaM2': 110,
        'membraneReservePercent': 10,
        'membraneRollCoverageM2': 75,
        'fastenersProjectPcs': 700,
        'fastenersPackagePcs': 250,
      });
      final ridge = result.materials.singleWhere(
        (material) => material.name.contains('Коньковый'),
      );
      final membrane = result.materials.singleWhere(
        (material) => material.name.contains('мембрана'),
      );
      final fasteners = result.materials.singleWhere(
        (material) => material.name.contains('Крепёж'),
      );

      expect(ridge.packageInfo?['count'], 5);
      expect(ridge.purchaseQty, 9.5);
      expect(membrane.packageInfo?['count'], 2);
      expect(membrane.purchaseQty, 150);
      expect(fasteners.packageInfo?['count'], 3);
      expect(fasteners.purchaseQty, 750);
    });

    test('warns when project quantity has no product packaging', () {
      final result = calculateCanonicalRoofing({
        ...baseInputs,
        'ridgeProjectM': 8,
        'membraneProjectAreaM2': 100,
        'fastenersProjectPcs': 500,
      });

      expect(
        result.warnings.any(
          (warning) => warning.contains('конькового элемента'),
        ),
        isTrue,
      );
      expect(
        result.warnings.any((warning) => warning.contains('площадь рулона')),
        isTrue,
      );
      expect(
        result.warnings.any(
          (warning) => warning.contains('количество в упаковке'),
        ),
        isTrue,
      );
    });

    test('always states the project boundary', () {
      final result = calculateCanonicalRoofing(baseInputs);

      expect(result.warnings.first, contains('стропила'));
      expect(result.warnings.first, contains('нагрузки'));
      expect(result.warnings.first, contains('не проектируются'));
    });
  });
}
