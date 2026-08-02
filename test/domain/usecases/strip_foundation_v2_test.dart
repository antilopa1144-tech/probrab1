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
            canonical.totals['longWeightKg']! +
                canonical.totals['clampWeightKg']!,
            0.01,
          ),
        );
        expect(result.values['formworkArea'], canonical.totals['formwork']);
        expect(result.values['longitudinalBars'], 4);
      },
    );

    test('режим точности влияет на заказ бетона без двойного запаса', () {
      Map<String, double> calculateForMode(double mode) =>
          calculator.calculate({
            'perimeter': 40,
            'width': 0.4,
            'height': 1,
            'foundationType': 0,
            'accuracyMode': mode,
          }, const []).values;

      final basic = calculateForMode(0);
      final professional = calculateForMode(2);

      expect(basic['stripVolume'], 16);
      expect(basic['concreteVolume'], 16);
      expect(professional['concreteVolume'], greaterThan(16));
      expect(professional['concreteVolume'], lessThan(20));
    });
  });

  group('calculateCanonicalStripFoundation v2', () {
    test('самослив не получает скрытые 0,5 м³, насос получает', () {
      final selfDischarge = calculateCanonicalStripFoundation({
        'perimeter': 40,
        'width': 400,
        'depth': 700,
        'aboveGround': 300,
        'deliveryMethod': 0,
        'accuracyMode': 0,
      });
      final pump = calculateCanonicalStripFoundation({
        'perimeter': 40,
        'width': 400,
        'depth': 700,
        'aboveGround': 300,
        'deliveryMethod': 1,
        'accuracyMode': 0,
      });

      expect(selfDischarge.totals['recPurchaseM3'], 16);
      expect(pump.totals['recPurchaseM3'], 16.5);
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
  });
}
