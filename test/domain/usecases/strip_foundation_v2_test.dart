import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_strip_foundation.dart';
import 'package:probrab_ai/domain/usecases/strip_foundation_canonical_adapter.dart';

void main() {
  group('CalculateStripFoundation canonical integration', () {
    final calculator = CalculateStripFoundation();

    test(
      'монолитная лента использует тот же расчёт, что canonical adapter',
      () {
        final result = calculator.calculate({
          'houseLength': 10,
          'houseWidth': 8,
          'width': 0.4,
          'height': 0.8,
          'foundationType': 0,
          'hasInternalWalls': 1,
          'internalWallsLength': 8,
          'accuracyMode': 0,
        }, const []);
        final canonical = calculateCanonicalStripFoundation({
          'perimeter': 44,
          'width': 400,
          'depth': 800,
          'aboveGround': 0,
          'formworkHeight': 800,
          'reinforcement': 1,
          'deliveryMethod': 0,
          'accuracyMode': 0,
        });

        expect(result.values['stripVolume'], 14.08);
        expect(
          result.values['concreteVolume'],
          canonical.totals['recPurchaseM3'],
        );
        expect(
          result.values['rebarWeight'],
          closeTo(
            canonical.totals['longPurchaseWeightKg']! +
                canonical.totals['clampPurchaseWeightKg']!,
            0.01,
          ),
        );
        expect(
          result.values['formworkArea'],
          canonical.totals['formworkWithReserve'],
        );
        expect(result.values['longitudinalBars'], 4);
        expect(result.values['fbsBlocksCount'], 0);
        expect(result.values['sandVolume'], 0);
      },
    );

    test('режим точности не добавляет скрытый второй запас', () {
      Map<String, double> calculateForMode(double mode) =>
          calculator.calculate({
            'perimeter': 40,
            'width': 0.4,
            'height': 1,
            'foundationType': 0,
            'accuracyMode': mode,
            'reserve': 5,
          }, const []).values;

      final basic = calculateForMode(0);
      final professional = calculateForMode(2);

      expect(basic['stripVolume'], 16);
      expect(basic['concreteVolume'], 16.8);
      expect(professional['concreteVolume'], 16.8);
    });
  });

  group('calculateCanonicalStripFoundation v3', () {
    test('не выдумывает потери насоса и учитывает только явный остаток', () {
      final withoutAllowance = calculateCanonicalStripFoundation({
        'perimeter': 40,
        'width': 400,
        'depth': 700,
        'aboveGround': 300,
        'reserve': 0,
      });
      final withAllowance = calculateCanonicalStripFoundation({
        'perimeter': 40,
        'width': 400,
        'depth': 700,
        'aboveGround': 300,
        'reserve': 0,
        'deliveryAllowanceM3': 0.35,
      });

      expect(withoutAllowance.totals['recPurchaseM3'], 16);
      expect(withAllowance.totals['recExactNeedM3'], 16.35);
      expect(withAllowance.totals['recPurchaseM3'], 16.4);
    });

    test('вязальная проволока считается по длине вязок', () {
      final result = calculateCanonicalStripFoundation({
        'perimeter': 40,
        'width': 400,
        'depth': 700,
        'aboveGround': 300,
        'accuracyMode': 0,
      });

      expect(result.totals['tieCount'], 400);
      expect(result.totals['wireLengthM'], 120);
      expect(result.totals['wireKg'], 0.72);
    });

    test('округляет арматуру до целых прутков выбранной длины', () {
      final result = calculateCanonicalStripFoundation({
        'perimeter': 40,
        'width': 400,
        'depth': 700,
        'aboveGround': 300,
        'reinforcement': 2,
        'rodLengthM': 11.7,
      });

      final longitudinal = result.materials.firstWhere(
        (material) => material.name.contains('продольная'),
      );
      expect(result.totals['rebarDiam'], 14);
      expect(result.totals['longBars'], 16);
      expect(longitudinal.packageInfo?['count'], 16);
      expect(longitudinal.purchaseQty, 187.2);
      expect(result.totals['longPurchaseWeightKg'], closeTo(226.512, 1e-9));
    });
  });
}
