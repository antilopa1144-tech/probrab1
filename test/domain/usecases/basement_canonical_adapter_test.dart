import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/basement_canonical_adapter.dart';

void main() {
  group('calculateCanonicalBasement v2', () {
    test('не считает углы стен дважды и отделяет плиту пола', () {
      final result = calculateCanonicalBasement({
        'length': 8,
        'width': 6,
        'depth': 2.5,
        'wallThickness': 200,
        'floorLength': 8,
        'floorWidth': 6,
        'floorThickness': 150,
      });

      expect(result.formulaVersion, 'basement-canonical-v2');
      expect(result.totals['innerPlanArea'], 42.56);
      expect(result.totals['wallVolume'], 13.6);
      expect(result.totals['floorVolume'], 7.2);
      expect(result.totals['cleanConcreteM3'], 20.8);
    });

    test('округляет отдельные заливки по выбранному шагу', () {
      final result = calculateCanonicalBasement({
        'floorConcreteReservePercent': 5,
        'wallConcreteReservePercent': 5,
        'readyMixOrderStepM3': 0.1,
      });

      expect(result.scenarios['MIN']!.purchaseQuantity, 20.8);
      expect(result.scenarios['REC']!.exactNeed, 21.84);
      expect(result.scenarios['REC']!.purchaseQuantity, 21.9);
      expect(result.scenarios['MAX']!.purchaseQuantity, 23);
    });

    test('вычитает проёмы из бетона и граней опалубки', () {
      final result = calculateCanonicalBasement({
        'wallOpeningsAreaM2': 4,
        'wallFormworkMode': 3,
        'formworkReservePercent': 0,
        'formworkSheetAreaM2': 2,
      });

      expect(result.totals['openingsVolume'], 0.8);
      expect(result.totals['wallVolume'], 12.8);
      expect(result.totals['formworkExactAreaM2'], 128);
      expect(result.totals['formworkSheets'], 64);
    });

    test('не назначает арматуру, но округляет массу из ведомости', () {
      final defaults = calculateCanonicalBasement({});
      expect(defaults.totals['rebarPurchaseKg'], 0);
      expect(
        defaults.materials.any(
          (material) => material.category == 'Армирование',
        ),
        isFalse,
      );

      final result = calculateCanonicalBasement({
        'floorRebarProjectKg': 1003,
        'wallRebarProjectKg': 2002,
        'rebarReservePercent': 5,
        'rebarOrderStepKg': 50,
      });
      expect(result.totals['floorRebarPurchaseKg'], 1100);
      expect(result.totals['wallRebarPurchaseKg'], 2150);
      expect(result.totals['rebarPurchaseKg'], 3250);
    });

    test('считает состав только по расходу и фактической упаковке', () {
      final result = calculateCanonicalBasement({
        'waterproofScope': 3,
        'waterproofSystem': 1,
        'waterproofWallHeightM': 2,
        'waterproofReservePercent': 10,
        'waterproofConsumptionKgM2': 1.5,
        'waterproofPackageKg': 20,
      });

      expect(result.totals['waterproofArea'], 104);
      expect(result.totals['waterproofPackages'], 9);
      expect(
        result.materials
            .singleWhere((material) => material.category == 'Гидроизоляция')
            .purchaseQty,
        180,
      );
    });

    test('считает рулонную систему по слоям и площади рулона', () {
      final result = calculateCanonicalBasement({
        'waterproofScope': 2,
        'waterproofSystem': 2,
        'waterproofLayers': 2,
        'waterproofReservePercent': 15,
        'waterproofRollAreaM2': 10,
      });

      expect(result.totals['waterproofArea'], 48);
      expect(result.totals['waterproofRolls'], 12);
    });

    test('округляет утеплитель до целых плит', () {
      final result = calculateCanonicalBasement({
        'insulationScope': 2,
        'insulationLayers': 1,
        'insulationReservePercent': 5,
        'insulationBoardAreaM2': 0.72,
      });

      expect(result.totals['insulationArea'], 48);
      expect(result.totals['insulationBoards'], 71);
      expect(result.totals['insulationPurchaseAreaM2'], 51.12);
    });

    test('читает старые метры толщины без возврата скрытых материалов', () {
      final result = calculateCanonicalBasement({
        'length': 8,
        'width': 6,
        'depth': 2.5,
        'wallThickness': 0.2,
        'floorThickness': 0.15,
        'needDrainage': 1,
      });

      expect(result.totals['wallThickness'], 200);
      expect(result.totals['floorThickness'], 150);
      expect(result.totals['drainageLength'], 0);
      expect(result.materials.length, 2);
    });
  });
}
