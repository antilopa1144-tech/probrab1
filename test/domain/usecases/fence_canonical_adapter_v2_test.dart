import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/fence_canonical_adapter.dart';

void main() {
  group('fence canonical v2', () {
    test('uses passport working width without hidden reserve', () {
      final result = calculateCanonicalFence({});
      final sheets = result.materials[2];

      expect(result.formulaVersion, 'fence-canonical-v2');
      expect(result.totals['netLength'], 45);
      expect(result.totals['sheetWorkingWidthMm'], 1150);
      expect(result.totals['sheetExactNeed'], closeTo(45 / 1.15, 0.000001));
      expect(result.scenarios['MIN']!.exactNeed, closeTo(45 / 1.15, 0.000001));
      expect(result.scenarios['REC']!.purchaseQuantity, 40);
      expect(result.scenarios['MAX']!.purchaseQuantity, 42);
      expect(sheets.quantity, closeTo(45 / 1.15, 0.000001));
      expect(sheets.purchaseQty, 40);
    });

    test('1000 mm working width changes purchase to 45 sheets', () {
      final result = calculateCanonicalFence({'sheetWorkingWidthMm': 1000});

      expect(result.totals['sheetExactNeed'], 45);
      expect(result.totals['sheets'], 45);
    });

    test('explicit cover reserve is applied once', () {
      final result = calculateCanonicalFence({
        'sheetWorkingWidthMm': 1150,
        'coverReservePercent': 10,
      });

      expect(
        result.scenarios['REC']!.exactNeed,
        closeTo(45 / 1.15 * 1.1, 0.000001),
      );
      expect(result.scenarios['REC']!.purchaseQuantity, 44);
      expect(result.scenarios['REC']!.keyFactors['reserve_percent'], 10);
    });

    test('screws stay in pieces and round to the entered package', () {
      final result = calculateCanonicalFence({
        'screwsPerSheet': 6,
        'screwReservePercent': 5,
        'screwPackCount': 200,
      });
      final screws = result.materials.firstWhere(
        (material) => material.name == 'Саморезы для профлиста',
      );

      expect(screws.quantity, 240);
      expect(screws.withReserve, 252);
      expect(screws.purchaseQty, 400);
      expect(screws.unit, 'шт');
      expect(screws.packageInfo?['count'], 2);
      expect(screws.packageInfo?['size'], 200);
    });

    test('zero passport rate omits the empty fastener line', () {
      final result = calculateCanonicalFence({'screwsPerSheet': 0});

      expect(
        result.materials.any(
          (material) => material.name == 'Саморезы для профлиста',
        ),
        isFalse,
      );
    });

    test('legacy field names and type order are migrated', () {
      final result = calculateCanonicalFence({
        'fenceLength': 50,
        'fenceHeight': 2,
        'fenceType': 1,
        'postSpacing': 2.5,
        'gates': 1,
        'wickets': 1,
      });

      expect(result.totals['fenceType'], 2);
      expect(
        result.materials.any(
          (material) => material.name.contains('Деревянный штакетник'),
        ),
        isTrue,
      );
    });
  });
}
