import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/rebar_canonical_adapter.dart';

void main() {
  group('rebar canonical v2', () {
    test('default grid uses explicit geometry and whole rods', () {
      final result = calculateCanonicalRebar(const {});

      expect(result.formulaVersion, 'rebar-canonical-v2');
      expect(result.totals['barsAlongLength'], 41);
      expect(result.totals['barsAlongWidth'], 51);
      expect(result.totals['mainExactLengthM'], 1617.6);
      expect(result.totals['mainExactWeightKg'], closeTo(1436.429, 1e-3));
      expect(result.totals['mainPlanningLengthM'], 1779.36);
      expect(result.totals['mainRods'], 153);
      expect(result.totals['mainPurchaseLengthM'], 1790.1);
      expect(result.materials.first.packageInfo?['count'], 153);
      expect(result.materials.first.packageInfo?['size'], 11.7);
    });

    test('wire follows tie share, reserve and package size', () {
      final result = calculateCanonicalRebar({
        'tieSharePercent': 25,
        'wireLengthPerTieM': 0.3,
        'wireReservePercent': 10,
        'wirePackageKg': 5,
      });

      expect(result.totals['tieCount'], 1046);
      expect(result.totals['wireExactKg'], closeTo(1.883, 1e-3));
      expect(result.totals['wirePurchaseKg'], 5);
      expect(result.materials.last.packageInfo?['count'], 1);
      expect(result.materials.last.packageInfo?['size'], 5);
    });

    test('frame keeps main bars and stirrups as separate purchases', () {
      final result = calculateCanonicalRebar({
        'structureType': 1,
        'frameLengthM': 10,
        'longitudinalBars': 6,
        'stirrupWidthMm': 400,
        'stirrupHeightMm': 600,
        'stirrupStepMm': 500,
        'stirrupHookAllowanceMm': 200,
      });

      expect(result.totals['mainExactLengthM'], 60);
      expect(result.totals['stirrupCount'], 21);
      expect(result.totals['stirrupPieceLengthM'], 2.2);
      expect(result.totals['secondaryExactLengthM'], 46.2);
      expect(result.totals['intersections'], 126);
      expect(
        result.materials.map((item) => item.name).join(' '),
        contains('Хомуты'),
      );
    });

    test('scenarios use only the explicit reserve policy', () {
      final result = calculateCanonicalRebar({'reservePercent': 10});

      expect(result.scenarios['MIN']?.exactNeed, 1617.6);
      expect(result.scenarios['MIN']?.purchaseQuantity, 1626.3);
      expect(result.scenarios['REC']?.exactNeed, 1779.36);
      expect(result.scenarios['REC']?.purchaseQuantity, 1790.1);
      expect(result.scenarios['MAX']?.exactNeed, 1860.24);
      expect(result.scenarios['MAX']?.purchaseQuantity, 1860.3);
    });
  });
}
