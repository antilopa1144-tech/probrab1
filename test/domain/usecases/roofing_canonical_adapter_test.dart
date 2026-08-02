import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/roofing_canonical_adapter.dart';

void main() {
  const softRoofingInputs = <String, double>{
    'roofingType': 1,
    'area': 80,
    'slope': 30,
    'ridgeLength': 8,
    'sheetWidth': 1.18,
    'sheetLength': 2.5,
    'complexity': 0,
    'accuracyMode': 0,
  };

  group('calculateCanonicalRoofing v2', () {
    test('calculates soft-roofing nails in kilograms', () {
      final result = calculateCanonicalRoofing(softRoofingInputs);
      final nails = result.materials.singleWhere(
        (material) => material.name.contains('Гвозди ершёные'),
      );

      expect(result.formulaVersion, 'roofing-canonical-v2');
      expect(nails.quantity, 9.238);
      expect(nails.withReserve, 9.699);
      expect(nails.purchaseQty, 10);
      expect(nails.packageInfo?['count'], 2);
      expect(nails.packageInfo?['unitSize'], 5);
    });

    test('uses the increased nail rate above 45 degrees', () {
      final result = calculateCanonicalRoofing({
        ...softRoofingInputs,
        'slope': 50,
      });
      final nails = result.materials.singleWhere(
        (material) => material.name.contains('Гвозди ершёные'),
      );

      expect(nails.quantity, 18.669);
      expect(nails.withReserve, 19.602);
      expect(nails.purchaseQty, 20);
    });
  });
}
