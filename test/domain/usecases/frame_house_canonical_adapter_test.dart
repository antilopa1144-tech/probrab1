import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/frame_house_canonical_adapter.dart';

void main() {
  group('calculateCanonicalFrameHouse v2', () {
    test(
      'по умолчанию не додумывает пиломатериал и использует валовую площадь',
      () {
        final result = calculateCanonicalFrameHouse({});

        expect(result.formulaVersion, 'frame-house-canonical-v2');
        expect(result.totals['grossWallArea'], 81);
        expect(result.totals['netWallArea'], 71);
        expect(result.totals['selectedSurfaceArea'], 81);
        expect(
          result.materials.any(
            (material) => material.category == 'Каркас по проекту',
          ),
          isFalse,
        );
        expect(
          result.warnings.any(
            (warning) => warning.contains('Пиломатериал каркаса не добавлен'),
          ),
          isTrue,
        );
      },
    );

    test('разделяет точную площадь, запас и целые наружные листы', () {
      final result = calculateCanonicalFrameHouse({});
      final material = result.materials.singleWhere(
        (item) => item.name == 'Наружная листовая обшивка по проекту',
      );

      expect(material.quantity, 81);
      expect(material.withReserve, 89.1);
      expect(material.purchaseQty, 90.625);
      expect(material.packageInfo?['count'], 29);
      expect(result.totals['outerSheets'], 29);
    });

    test('MIN REC MAX относятся только к наружным листам', () {
      final result = calculateCanonicalFrameHouse({});

      expect(result.scenarios['MIN']!.exactNeed, 25.92);
      expect(result.scenarios['MIN']!.purchaseQuantity, 26);
      expect(result.scenarios['REC']!.exactNeed, 28.512);
      expect(result.scenarios['REC']!.purchaseQuantity, 29);
      expect(result.scenarios['MAX']!.exactNeed, 29.808);
      expect(result.scenarios['MAX']!.purchaseQuantity, 30);
    });

    test('чистая площадь применяется только по явному выбору', () {
      final result = calculateCanonicalFrameHouse({'surfaceAreaBasis': 1});

      expect(result.totals['selectedSurfaceArea'], 71);
      expect(result.totals['outerSheets'], 25);
    });

    test('ограничивает площадь проёмов площадью стен', () {
      final result = calculateCanonicalFrameHouse({
        'wallLength': 5,
        'wallHeight': 2,
        'openingsArea': 20,
        'surfaceAreaBasis': 1,
      });

      expect(result.totals['openingsArea'], 10);
      expect(result.totals['netWallArea'], 0);
      expect(
        result.warnings.any(
          (warning) => warning.contains('ограничена площадью стен'),
        ),
        isTrue,
      );
    });

    test('округляет одну проектную позицию до целых досок', () {
      final result = calculateCanonicalFrameHouse({
        'framingProjectLengthM': 100,
        'framingReservePercent': 5,
        'framingBoardLengthM': 6,
      });

      expect(result.totals['framingPurchaseBoards'], 18);
      expect(result.totals['framingPurchaseM'], 108);
      expect(
        result.materials.any(
          (material) => material.name.contains('Стойки каркаса'),
        ),
        isFalse,
      );
    });

    test('считает внутреннюю обшивку по слоям и фактическому листу', () {
      final result = calculateCanonicalFrameHouse({
        'innerSheathingEnabled': 1,
        'innerSheathingLayers': 2,
        'innerSheetAreaM2': 3,
        'innerSheathingReservePercent': 10,
      });

      expect(result.totals['innerExactAreaM2'], 162);
      expect(result.totals['innerSheets'], 60);
      expect(result.totals['innerPurchaseAreaM2'], 180);
    });

    test('не считает утеплитель без площади фактической упаковки', () {
      final result = calculateCanonicalFrameHouse({'insulationEnabled': 1});

      expect(result.totals['insulationPackages'], 0);
      expect(
        result.materials.any((material) => material.category == 'Утепление'),
        isFalse,
      );
      expect(
        result.warnings.any((warning) => warning.contains('площадь упаковки')),
        isTrue,
      );
    });

    test('считает утеплитель упаковками принятой толщины', () {
      final result = calculateCanonicalFrameHouse({
        'insulationEnabled': 1,
        'insulationPackageAreaM2': 5.76,
        'insulationLayers': 2,
        'insulationReservePercent': 5,
      });

      expect(result.totals['insulationExactAreaM2'], 162);
      expect(result.totals['insulationPackages'], 30);
    });

    test('не выводит ленту и крепёж из скрытых универсальных норм', () {
      final defaults = calculateCanonicalFrameHouse({});
      expect(defaults.totals['tapeRolls'], 0);
      expect(defaults.totals['sheathingFastenerPackages'], 0);
      expect(defaults.totals['framingFastenerPackages'], 0);

      final result = calculateCanonicalFrameHouse({
        'tapeProjectM': 100,
        'tapeReservePercent': 10,
        'tapeRollLengthM': 25,
        'sheathingFastenersProjectPcs': 1000,
        'sheathingFastenersReservePercent': 5,
        'sheathingFastenersPackagePcs': 200,
        'framingFastenersProjectPcs': 450,
        'framingFastenersReservePercent': 10,
        'framingFastenersPackagePcs': 100,
      });

      expect(result.totals['tapeRolls'], 5);
      expect(result.totals['sheathingFastenerPackages'], 6);
      expect(result.totals['framingFastenerPackages'], 5);
    });

    test('не применяет скрытый accuracy multiplier', () {
      final basic = calculateCanonicalFrameHouse({'accuracyMode': 0});
      final expert = calculateCanonicalFrameHouse({'accuracyMode': 2});

      expect(expert.totals, basic.totals);
      expect(expert.materials.length, basic.materials.length);
    });
  });
}
