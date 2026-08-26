import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/decor_stone_canonical_adapter.dart';

void main() {
  group('calculateCanonicalDecorStone v2', () {
    test('subtracts openings in dimensions mode', () {
      final result = calculateCanonicalDecorStone({
        'inputMode': 0,
        'wallWidth': 4,
        'wallHeight': 2.7,
        'openingsArea': 1.8,
      });

      expect(result.totals['grossArea'], 10.8);
      expect(result.totals['area'], 9);
    });

    test('applies reserve once and rounds by the actual pack area', () {
      final result = calculateCanonicalDecorStone({
        'inputMode': 1,
        'area': 10,
        'reservePercent': 10,
        'packArea': 1.8,
      });

      expect(result.scenarios['MIN']!.exactNeed, 10);
      expect(result.scenarios['REC']!.exactNeed, 11);
      expect(result.scenarios['MAX']!.exactNeed, 11.5);
      expect(result.scenarios['REC']!.buyPlan.packagesCount, 7);
      expect(result.scenarios['REC']!.purchaseQuantity, 12.6);
      expect(result.scenarios['REC']!.leftover, 1.6);
    });

    test('uses product rates and package sizes for consumables', () {
      final result = calculateCanonicalDecorStone({
        'inputMode': 1,
        'area': 10,
        'glueRate': 4.2,
        'glueBag': 20,
        'needGrout': 1,
        'groutRate': 0.35,
        'groutBag': 5,
        'needPrimer': 1,
        'primerRate': 0.12,
        'primerLayers': 2,
        'primerCan': 5,
      });

      expect(result.totals['glueKg'], 42);
      expect(result.totals['glueBags'], 3);
      expect(result.totals['groutKg'], 3.5);
      expect(result.totals['groutBags'], 1);
      expect(result.totals['primerL'], 2.4);
      expect(result.totals['primerCans'], 1);
    });
  });
}
