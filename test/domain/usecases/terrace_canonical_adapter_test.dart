import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/terrace_canonical_adapter.dart';

void main() {
  group('terrace canonical v2', () {
    test('safe layout applies reserve once and buys whole boards', () {
      final result = calculateCanonicalTerrace({});
      final board = result.materials.first;

      expect(result.formulaVersion, 'terrace-canonical-v2');
      expect(result.totals['area'], 15);
      expect(result.totals['rowCount'], 20);
      expect(result.totals['safeBaseBoards'], 40);
      expect(result.totals['baseCutWasteM'], 20);
      expect(result.scenarios['MIN']!.exactNeed, 40);
      expect(result.scenarios['REC']!.exactNeed, 44);
      expect(result.scenarios['REC']!.purchaseQuantity, 44);
      expect(result.scenarios['MAX']!.exactNeed, 46);
      expect(board.quantity, 40);
      expect(board.withReserve, 44);
      expect(board.purchaseQty, 44);
    });

    test('confirmed offcut reuse reduces the board purchase', () {
      final result = calculateCanonicalTerrace({'offcutReuseMode': 1});

      expect(result.totals['baseBoardExact'], closeTo(100 / 3, 0.000001));
      expect(result.totals['baseBoardPurchase'], 34);
      expect(result.totals['baseCutWasteM'], 2);
      expect(result.scenarios['REC']!.purchaseQuantity, 37);
    });

    test('lags, clips, screws and geotextile use explicit packages', () {
      final result = calculateCanonicalTerrace({});
      final lags = result.materials[1];
      final clips = result.materials[2];
      final screws = result.materials[3];
      final geotextile = result.materials[4];

      expect(result.totals['lagRowCount'], 14);
      expect(result.totals['lagBaseM'], 42);
      expect(lags.quantity, 14);
      expect(lags.withReserve, 14.7);
      expect(lags.purchaseQty, 15);
      expect(clips.quantity, 320);
      expect(clips.withReserve, 336);
      expect(clips.purchaseQty, 400);
      expect(clips.packageInfo?['count'], 4);
      expect(screws.unit, 'шт');
      expect(screws.purchaseQty, 400);
      expect(geotextile.quantity, 15);
      expect(geotextile.withReserve, 15.75);
      expect(geotextile.purchaseQty, 50);
    });

    test('treatment rate and can size come from the user input', () {
      final result = calculateCanonicalTerrace({
        'boardType': 1,
        'withTreatment': 1,
        'treatmentRateLPerM2PerLayer': 0.12,
        'treatmentLayers': 2,
        'treatmentCanL': 2.5,
        'treatmentReservePercent': 10,
        'withGeotextile': 0,
      });
      final oil = result.materials.firstWhere(
        (material) => material.name == 'Масло для дерева',
      );

      expect(oil.quantity, 3.6);
      expect(oil.withReserve, 3.96);
      expect(oil.purchaseQty, 5);
      expect(oil.packageInfo?['count'], 2);
      expect(
        result.materials.any((item) => item.name.contains('Геотекстиль')),
        isFalse,
      );
    });

    test('legacy area is not ignored', () {
      final result = calculateCanonicalTerrace({'area': 36, 'floorType': 1});

      expect(result.totals['length'], 6);
      expect(result.totals['width'], 6);
      expect(result.totals['area'], 36);
    });
  });
}
