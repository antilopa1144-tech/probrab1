import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';
import 'package:probrab_ai/domain/usecases/drywall_ceiling_canonical_adapter.dart';

void main() {
  group('Drywall ceiling canonical v3', () {
    test('считает геометрию и плиты П 113.1', () {
      final result = calculateCanonicalDrywallCeiling(const {
        'inputMode': 0,
        'length': 5,
        'width': 4,
        'layers': 1,
      });
      final sheets = result.materials.first;

      expect(result.formulaVersion, 'drywall-ceiling-canonical-v3');
      expect(result.totals['area'], 20);
      expect(result.totals['perimeter'], 18);
      expect(sheets.quantity, closeTo(20 / 3, 0.000001));
      expect(sheets.withReserve, closeTo(20 / 3 * 1.1, 0.000001));
      expect(sheets.purchaseQty, 8);
    });

    test('считает полный каркас П 113.1', () {
      final result = calculateCanonicalDrywallCeiling(const {});

      expect(result.totals['profileBaseM'], 58);
      expect(result.totals['ppPcs'], 21);
      expect(result.totals['pnPcs'], 7);
      expect(result.totals['connectorCount'], 36);
      expect(result.totals['extensionCount'], 5);
      expect(result.totals['suspCount'], 15);
    });

    test('разделяет LN и TN 25 по фасовкам', () {
      final result = calculateCanonicalDrywallCeiling(const {});
      final ln = result.materials.singleWhere(
        (material) => material.name.contains('Шуруп LN'),
      );
      final tn25 = result.materials.singleWhere(
        (material) => material.name.contains('Шуруп TN 25'),
      );

      expect(ln.quantity, 28);
      expect(ln.purchaseQty, 100);
      expect(tn25.quantity, 460);
      expect(tn25.purchaseQty, 1000);
      expect(
        result.materials.any((material) => material.name.contains('TN 35')),
        isFalse,
      );
    });

    test('разделяет анкеры подвесов и крепёж ПН', () {
      final result = calculateCanonicalDrywallCeiling(const {});
      final anchors = result.materials.singleWhere(
        (material) => material.name.contains('Анкерный элемент'),
      );
      final wallFixings = result.materials.singleWhere(
        (material) => material.name.contains('Крепёж профиля ПН'),
      );

      expect(anchors.quantity, 14);
      expect(anchors.purchaseQty, 15);
      expect(wallFixings.quantity, 36);
      expect(wallFixings.purchaseQty, 38);
    });

    test('считает три ленты и составы отдельными позициями', () {
      final result = calculateCanonicalDrywallCeiling(const {});
      CanonicalMaterialResult materialByName(String name) => result.materials
          .singleWhere((material) => material.name.startsWith(name));

      expect(materialByName('Уплотнительная').purchaseQty, 30);
      expect(materialByName('Бумажная').purchaseQty, 50);
      expect(materialByName('Разделительная').purchaseQty, 50);
      expect(materialByName('Гипсовая шпаклёвка').quantity, 8);
      expect(materialByName('Гипсовая шпаклёвка').purchaseQty, 25);
      expect(materialByName('Грунтовка').quantity, 2);
      expect(materialByName('Грунтовка').purchaseQty, 5);
    });

    test('в режиме площади использует явный периметр', () {
      final result = calculateCanonicalDrywallCeiling(const {
        'inputMode': 1,
        'area': 20,
        'perimeterM': 30,
      });

      expect(result.totals['perimeter'], 30);
      expect(result.totals['pnPcs'], 11);
      expect(
        result.warnings.any(
          (warning) => warning.contains('условного квадрата'),
        ),
        isTrue,
      );
    });

    test('учитывает размеры и все пользовательские фасовки', () {
      final result = calculateCanonicalDrywallCeiling(const {
        'inputMode': 1,
        'area': 24,
        'perimeterM': 30,
        'sheetWidthMm': 1200,
        'sheetLengthMm': 3000,
        'sheetReservePercent': 0,
        'profileLengthM': 4,
        'profileReservePercent': 0,
        'fastenerReservePercent': 0,
        'tnScrewPackCount': 500,
        'lnScrewPackCount': 50,
        'jointTapeRollM': 50,
        'sealingTapeRollM': 40,
        'separatingTapeRollM': 25,
        'puttyBagKg': 10,
        'primerCanL': 3,
        'finishReservePercent': 0,
      });

      CanonicalMaterialResult materialByName(String name) => result.materials
          .singleWhere((material) => material.name.contains(name));
      expect(result.materials.first.purchaseQty, 7);
      expect(materialByName('Профиль ПП').purchaseQty, 18);
      expect(materialByName('Профиль ПН').purchaseQty, 8);
      expect(materialByName('Шуруп TN 25').purchaseQty, 1000);
      expect(materialByName('Шуруп LN').purchaseQty, 50);
      expect(materialByName('Гипсовая шпаклёвка').purchaseQty, 10);
      expect(materialByName('Грунтовка').purchaseQty, 3);
    });

    test('П 113.2 применяет отдельные нормы двух слоёв', () {
      final result = calculateCanonicalDrywallCeiling(const {'layers': 2});
      CanonicalMaterialResult materialByName(String name) => result.materials
          .singleWhere((material) => material.name.contains(name));

      expect(result.materials.first.quantity, closeTo(40 / 3, 0.000001));
      expect(materialByName('TN 25').quantity, 180);
      expect(materialByName('TN 35').quantity, 460);
      expect(materialByName('Гипсовая шпаклёвка').quantity, 12);
      expect(result.totals['profileBaseM'], 58);
      expect(
        result.warnings.any((warning) => warning.contains('0.4 кН')),
        isTrue,
      );
    });

    test('MAX не добавляет скрытый запас', () {
      final result = calculateCanonicalDrywallCeiling(const {
        'sheetReservePercent': 7,
      });

      expect(
        result.scenarios['MAX']?.exactNeed,
        result.scenarios['REC']?.exactNeed,
      );
      expect(
        result.scenarios['MAX']?.purchaseQuantity,
        result.scenarios['REC']?.purchaseQuantity,
      );
      expect(
        result.scenarios['MAX']?.assumptions,
        contains('no_hidden_max_reserve'),
      );
    });

    test('точное граничное количество не округляет заранее', () {
      final result = calculateCanonicalDrywallCeiling(const {
        'inputMode': 1,
        'area': 15,
        'perimeterM': 16,
        'sheetReservePercent': 0,
      });

      expect(result.scenarios['REC']?.exactNeed, 5);
      expect(result.scenarios['REC']?.purchaseQuantity, 5);
      expect(result.scenarios['REC']?.leftover, 0);
    });

    test('всегда сообщает границы применимости П 113', () {
      final result = calculateCanonicalDrywallCeiling(const {});

      expect(result.warnings.first, contains('только к комплектной системе'));
      expect(result.warnings[1], contains('100 м²'));
      expect(result.warnings[2], contains('Светильники'));
    });
  });
}
