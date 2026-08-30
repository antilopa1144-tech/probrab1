import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';
import 'package:probrab_ai/domain/usecases/stairs_canonical_adapter.dart';

void main() {
  group('calculateCanonicalStairs v2', () {
    test('calculates one straight flight geometry', () {
      final result = calculateCanonicalStairs(const {});

      expect(result.formulaVersion, 'stairs-canonical-v2');
      expect(result.totals['riserCount'], 16);
      expect(result.totals['actualRiserHeightMm'], 175);
      expect(result.totals['treadCount'], 15);
      expect(result.totals['straightRunM'], 4.2);
      expect(result.totals['inclineLengthM'], 5.048);
      expect(result.totals['comfortStepMm'], 630);
    });

    test('supports a separate upper tread and explicit project count', () {
      final result = calculateCanonicalStairs(const {
        'geometryMode': 1,
        'projectRiserCount': 17,
        'topFloorActsAsTread': 0,
      });

      expect(result.totals['riserCount'], 17);
      expect(result.totals['treadCount'], 17);
      expect(result.totals['actualRiserHeightMm'], 164.706);
      expect(
        result.warnings.any(
          (warning) => warning.contains('подобрано по целевой'),
        ),
        isFalse,
      );
    });

    test('estimates headroom and marks an attention case', () {
      final result = calculateCanonicalStairs(const {
        'openingLengthM': 3.2,
        'floorStructureThicknessM': 0.3,
      });

      expect(result.totals['estimatedHeadroomM'], 1.833);
      expect(
        result.warnings.any(
          (warning) => warning.contains('нужен разрез проекта'),
        ),
        isTrue,
      );
    });

    test('does not invent structural or railing materials', () {
      final result = calculateCanonicalStairs(const {});
      final names = result.materials.map((material) => material.name).join(' ');

      expect(result.materials, hasLength(1));
      expect(names, contains('Чистовые заготовки ступеней'));
      expect(names, isNot(contains('Косоур/тетива')));
      expect(names, isNot(contains('Бетон')));
      expect(names, isNot(contains('Арматура')));
      expect(names, isNot(contains('Поручень')));
      expect(names, isNot(contains('Крепёж')));
    });

    test('rounds tread blanks by explicit reserve and packaging', () {
      final result = calculateCanonicalStairs(const {
        'treadReservePercent': 10,
        'treadsPerPackagePcs': 4,
      });
      final treads = result.materials.first;

      expect(treads.quantity, 15);
      expect(treads.withReserve, 16.5);
      expect(treads.packageInfo?['count'], 5);
      expect(treads.purchaseQty, 20);
      expect(result.scenarios['MIN']?.purchaseQuantity, 16);
      expect(result.scenarios['REC']?.purchaseQuantity, 20);
      expect(result.scenarios['MAX']?.purchaseQuantity, 20);
      expect(
        result.scenarios['MAX']?.assumptions,
        contains('no_hidden_max_reserve'),
      );
    });

    test('can exclude treads from purchase', () {
      final result = calculateCanonicalStairs(const {'includeTreadBlanks': 0});

      expect(result.materials, isEmpty);
      expect(result.scenarios['REC']?.purchaseQuantity, 0);
      expect(
        result.warnings,
        contains('Не рассчитана ни одна закупочная позиция'),
      );
    });

    test('uses only explicit riser schedule', () {
      final result = calculateCanonicalStairs(const {
        'riserProjectPcs': 15,
        'riserReservePercent': 10,
        'risersPerPackagePcs': 4,
      });
      final risers = result.materials.singleWhere(
        (material) => material.name.contains('Подступенки'),
      );

      expect(risers.quantity, 15);
      expect(risers.withReserve, 16.5);
      expect(risers.purchaseQty, 20);
    });

    test('checks whole stringer stock pieces', () {
      final result = calculateCanonicalStairs(const {
        'stringerProjectPcs': 4,
        'stringerBlankLengthM': 2.5,
        'stringerStockLengthM': 6,
      });
      final stringers = result.materials.singleWhere(
        (material) => material.name.contains('Косоур/тетива'),
      );

      expect(stringers.quantity, 10);
      expect(stringers.packageInfo?['count'], 2);
      expect(stringers.purchaseQty, 12);
    });

    test('does not join short stringer blanks without a project node', () {
      final result = calculateCanonicalStairs(const {
        'stringerProjectPcs': 2,
        'stringerBlankLengthM': 5,
        'stringerStockLengthM': 4,
      });

      expect(
        result.materials.any((material) => material.name.contains('Косоур')),
        isFalse,
      );
      expect(
        result.warnings.any((warning) => warning.contains('заготовка короче')),
        isTrue,
      );
    });

    test('packages explicit concrete, rebar, railing and fasteners', () {
      final result = calculateCanonicalStairs(const {
        'concreteProjectM3': 1.25,
        'concreteReservePercent': 5,
        'concreteOrderStepM3': 0.1,
        'rebarProjectKg': 123,
        'rebarReservePercent': 5,
        'rebarPackageKg': 25,
        'handrailProjectM': 8.4,
        'handrailReservePercent': 5,
        'handrailStockLengthM': 3,
        'railingInfillProjectPcs': 18,
        'railingInfillReservePercent': 10,
        'railingInfillPackagePcs': 5,
        'fastenersProjectPcs': 64,
        'fastenersReservePercent': 5,
        'fastenersPackagePcs': 50,
      });
      CanonicalMaterialResult byName(String name) => result.materials
          .singleWhere((material) => material.name.contains(name));

      expect(byName('Бетон').purchaseQty, 1.4);
      expect(byName('Арматура').purchaseQty, 150);
      expect(byName('Поручень').purchaseQty, 9);
      expect(byName('заполнение ограждения').purchaseQty, 20);
      expect(byName('Крепёж').purchaseQty, 100);
    });

    test('warns when a project position has no packaging', () {
      final result = calculateCanonicalStairs(const {
        'fastenersProjectPcs': 64,
        'fastenersPackagePcs': 0,
      });

      expect(
        result.materials.any((material) => material.name.contains('Крепёж')),
        isFalse,
      );
      expect(
        result.warnings.any((warning) => warning.contains('Крепёж задан')),
        isTrue,
      );
    });

    test('always states the project boundary', () {
      final result = calculateCanonicalStairs(const {});

      expect(result.warnings.first, contains('одного прямого марша'));
      expect(result.warnings.first, contains('не проектируются'));
    });
  });
}
