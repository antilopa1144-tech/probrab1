import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/electric_canonical_adapter.dart';

void main() {
  group('calculateCanonicalElectric v3', () {
    test(
      'по умолчанию покупает кабель отрезом и округляет сечения отдельно',
      () {
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

        expect(result.formulaVersion, 'electric-canonical-v3');
        expect(result.scenarios['MIN']!.exactNeed, closeTo(219.88524, 0.00001));
        expect(result.scenarios['REC']!.exactNeed, closeTo(239.19024, 0.00001));
        expect(result.scenarios['MAX']!.exactNeed, closeTo(268.14774, 0.00001));
        expect(result.scenarios['MIN']!.purchaseQuantity, 222);
        expect(result.scenarios['REC']!.purchaseQuantity, cablePurchase);
        expect(result.scenarios['REC']!.purchaseQuantity, 241);
        expect(result.scenarios['MAX']!.purchaseQuantity, 270);
        expect(result.scenarios['REC']!.buyPlan.unit, 'м');
        expect(result.materials[0].packageInfo, isNull);
        expect(result.materials[1].packageInfo, isNull);
        expect(
          result.scenarios['REC']!.assumptions,
          contains('purchase_mode:per_meter'),
        );
      },
    );

    test('режим бухт округляет 3×1,5 и 3×2,5 отдельно до 50 м', () {
      final result = calculateCanonicalElectric({
        'apartmentArea': 60,
        'roomsCount': 3,
        'ceilingHeight': 2.7,
        'wiringType': 0,
        'hasKitchen': 1,
        'cablePurchaseMode': 1,
        'reserve': 15,
      });

      expect(result.scenarios['MIN']!.purchaseQuantity, 268);
      expect(result.scenarios['REC']!.purchaseQuantity, 268);
      expect(result.scenarios['MAX']!.purchaseQuantity, 318);
      expect(result.materials[0].packageInfo?['count'], 2);
      expect(result.materials[1].packageInfo?['count'], 3);
      expect(
        result.scenarios['REC']!.assumptions,
        contains('purchase_mode:spool_50m'),
      );
    });

    test('не выводит трёхфазный ввод из площади объекта', () {
      final result = calculateCanonicalElectric({
        'apartmentArea': 120,
        'roomsCount': 5,
        'ceilingHeight': 2.7,
        'hasKitchen': 1,
      });

      expect(
        result.warnings.any((warning) => warning.contains('Площадь более')),
        isFalse,
      );
      expect(
        result.warnings.any(
          (warning) => warning.contains('выделенной мощности'),
        ),
        isTrue,
      );
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
