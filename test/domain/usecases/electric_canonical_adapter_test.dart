import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/electric_canonical_adapter.dart';

void main() {
  group('calculateCanonicalElectric v2', () {
    test('считает сценарии в метрах и округляет каждое сечение отдельно', () {
      final result = calculateCanonicalElectric({
        'apartmentArea': 60,
        'roomsCount': 3,
        'ceilingHeight': 2.7,
        'wiringType': 0,
        'hasKitchen': 1,
        'reserve': 15,
      });
      final cablePurchase = result.materials
          .where((material) => material.category == 'Кабель')
          .fold<double>(
            0,
            (total, material) => total + (material.purchaseQty ?? 0),
          );

      expect(result.formulaVersion, 'electric-canonical-v2');
      expect(result.scenarios['MIN']!.exactNeed, closeTo(219.88524, 0.00001));
      expect(result.scenarios['REC']!.exactNeed, closeTo(239.19024, 0.00001));
      expect(result.scenarios['MAX']!.exactNeed, closeTo(268.14774, 0.00001));
      expect(result.scenarios['MIN']!.purchaseQuantity, 268);
      expect(result.scenarios['REC']!.purchaseQuantity, cablePurchase);
      expect(result.scenarios['MAX']!.purchaseQuantity, 318);
      expect(result.scenarios['REC']!.buyPlan.unit, 'м');
    });

    test(
      'REC использует выбранный запас без скрытого второго коэффициента',
      () {
        final result = calculateCanonicalElectric({
          'apartmentArea': 60,
          'roomsCount': 3,
          'ceilingHeight': 2.7,
          'wiringType': 0,
          'hasKitchen': 1,
          'reserve': 20,
          'accuracyMode': 2,
        });

        expect(
          result.scenarios['REC']!.keyFactors['input_reserve_multiplier'],
          1.2,
        );
        expect(
          result.scenarios['MIN']!.exactNeed,
          lessThan(result.scenarios['REC']!.exactNeed),
        );
        expect(
          result.scenarios['REC']!.exactNeed,
          lessThan(result.scenarios['MAX']!.exactNeed),
        );
      },
    );
  });
}
