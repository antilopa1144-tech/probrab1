import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/blind_area_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/calculate_blind_area_v2.dart';

void main() {
  group('CalculateBlindAreaV2 canonical parity', () {
    final calculator = CalculateBlindAreaV2();

    test('прямоугольный дом 10×8 м учитывает четыре угла', () {
      final result = calculator.calculate({
        'houseLength': 10,
        'houseWidth': 8,
        'blindAreaWidth': 1,
        'thickness': 0.1,
        'blindAreaType': 0,
        'needInsulation': 0,
        'needDrainage': 1,
      }, const []);

      expect(result.values['perimeter'], 36);
      expect(result.values['totalArea'], 40);
      expect(result.values['concreteVolume'], 4.6);
    });

    test('мягкая система не дублирует нижний щебень', () {
      final result = calculator.calculate({
        'houseLength': 10,
        'houseWidth': 8,
        'blindAreaWidth': 1,
        'thickness': 0.1,
        'blindAreaType': 2,
        'needInsulation': 0,
        'needDrainage': 1,
      }, const []);

      expect(result.values['totalArea'], 40);
      expect(result.values['gravelVolume'], 0);
      expect(result.values['sandVolume'], 4);
      expect(result.values['membranArea'], greaterThanOrEqualTo(46));
    });
  });

  group('calculateCanonicalBlindArea', () {
    test('заказ бетона не меньше рекомендованной потребности', () {
      final result = calculateCanonicalBlindArea({
        'perimeter': 40,
        'width': 1,
        'thickness': 100,
        'materialType': 0,
        'withInsulation': 0,
        'accuracyMode': 2,
      });

      final concrete = result.materials.first;
      expect(concrete.quantity, 4.4);
      expect(concrete.purchaseQty, greaterThanOrEqualTo(concrete.withReserve!));
      expect(
        (concrete.purchaseQty! * 10).roundToDouble(),
        concrete.purchaseQty! * 10,
      );
    });

    test('для плитки не выдумывает расход смеси', () {
      final result = calculateCanonicalBlindArea({
        'perimeter': 30,
        'width': 0.8,
        'thickness': 100,
        'materialType': 1,
        'withInsulation': 0,
        'accuracyMode': 0,
      });

      expect(result.totals['area'], 26.56);
      expect(result.totals['mixBags'], 0);
      expect(
        result.materials.any((material) => material.name.contains('Смесь')),
        isFalse,
      );
      expect(result.warnings.single, contains('Укладочный слой'));
    });
  });
}
