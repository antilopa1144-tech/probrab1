import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/concrete_universal_calculator_v2.dart';
import 'package:probrab_ai/domain/usecases/concrete_canonical_adapter.dart';

void main() {
  group('calculateCanonicalConcrete v2', () {
    test('Flutter-поля используют canonical-дефолты и диапазоны', () {
      final volume = concreteUniversalCalculatorV2.fields.firstWhere(
        (field) => field.key == 'concreteVolume',
      );
      final reserve = concreteUniversalCalculatorV2.fields.firstWhere(
        (field) => field.key == 'reserve',
      );

      expect(volume.defaultValue, 5);
      expect(volume.minValue, 0.1);
      expect(volume.maxValue, 100);
      expect(reserve.defaultValue, 5);
      expect(reserve.minValue, 0);
      expect(reserve.maxValue, 20);
    });

    test('разделяет чистый объём, выбранный запас и заказ', () {
      final result = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'concreteGrade': 3,
        'manualMix': 0,
        'reserve': 5,
      });
      final concrete = result.materials.first;

      expect(result.formulaVersion, 'concrete-canonical-v2');
      expect(result.totals['sourceVolume'], 5);
      expect(result.totals['totalVolume'], 5.25);
      expect(result.scenarios['MIN']!.exactNeed, 5);
      expect(result.scenarios['REC']!.exactNeed, 5.25);
      expect(result.scenarios['REC']!.purchaseQuantity, 5.3);
      expect(result.scenarios['MAX']!.exactNeed, 5.5);
      expect(concrete.quantity, 5);
      expect(concrete.withReserve, 5.25);
      expect(concrete.purchaseQty, 5.3);
      expect(concrete.packageInfo, isNull);
    });

    test('режим точности не добавляет второй скрытый запас', () {
      final basic = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'reserve': 5,
        'accuracyMode': 0,
      });
      final professional = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'reserve': 5,
        'accuracyMode': 2,
      });

      expect(professional.scenarios['REC']!.exactNeed, 5.25);
      expect(
        professional.scenarios['REC']!.purchaseQuantity,
        basic.scenarios['REC']!.purchaseQuantity,
      );
    });

    test('ручной замес считает компоненты от объёма с запасом один раз', () {
      final result = calculateCanonicalConcrete({
        'concreteVolume': 5,
        'concreteGrade': 3,
        'manualMix': 1,
        'reserve': 5,
      });
      final cement = result.materials.firstWhere(
        (material) => material.name.startsWith('Цемент'),
      );

      expect(result.totals['cementKg'], 1522.5);
      expect(cement.quantity, 1522.5);
      expect(cement.purchaseQty, 1550);
    });
  });
}
