import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/drywall_ceiling_canonical_adapter.dart';

void main() {
  group('Drywall ceiling canonical v2', () {
    test('разделяет чистую потребность ГКЛ, запас и покупку', () {
      final result = calculateCanonicalDrywallCeiling({
        'inputMode': 0,
        'length': 5,
        'width': 4,
        'layers': 1,
      });
      final gkl = result.materials.first;

      expect(result.formulaVersion, 'drywall-ceiling-canonical-v2');
      expect(gkl.quantity, closeTo(20 / 3, 0.000001));
      expect(gkl.withReserve, closeTo(20 / 3 * 1.1, 0.000001));
      expect(gkl.purchaseQty, 8);
      expect(result.scenarios['MIN']!.exactNeed, closeTo(20 / 3, 0.000001));
      expect(result.scenarios['REC']!.purchaseQuantity, 8);
    });

    test('каркас использует опубликованные ориентиры на площадь', () {
      final result = calculateCanonicalDrywallCeiling({
        'inputMode': 0,
        'length': 5,
        'width': 4,
      });

      expect(result.totals['profileBaseM'], 58);
      expect(result.totals['ppPcs'], 21);
      expect(result.totals['pnPcs'], 7);
      expect(result.totals['suspCount'], 15);
      expect(result.totals['crabCount'], 36);
    });

    test('саморезы считаются в штуках и округляются до упаковки', () {
      final result = calculateCanonicalDrywallCeiling({
        'inputMode': 1,
        'area': 20,
        'screwPackCount': 1000,
      });
      final screws = result.materials.firstWhere(
        (material) => material.name.contains('Саморезы для ГКЛ'),
      );

      expect(screws.quantity, 460);
      expect(screws.withReserve, 483);
      expect(screws.purchaseQty, 1000);
      expect(screws.packageInfo?['count'], 1);
      expect(screws.packageInfo?['size'], 1000);
    });

    test('размер листа и фасовки меняют покупку без скрытых множителей', () {
      final result = calculateCanonicalDrywallCeiling({
        'inputMode': 1,
        'area': 24,
        'sheetWidthMm': 1200,
        'sheetLengthMm': 3000,
        'sheetReservePercent': 0,
        'profileLengthM': 4,
        'profileReservePercent': 0,
        'fastenerReservePercent': 0,
        'screwPackCount': 500,
        'tapeRollM': 50,
        'puttyBagKg': 10,
        'primerRateLPerM2': 0.2,
        'primerCanL': 3,
        'finishReservePercent': 0,
      });

      expect(result.materials[0].purchaseQty, 7);
      expect(result.materials[1].purchaseQty, 18);
      expect(result.materials[5].purchaseQty, 1000);
      expect(result.materials[7].purchaseQty, 50);
      expect(result.materials[8].purchaseQty, 10);
      expect(result.materials[9].purchaseQty, 6);
    });
  });
}
